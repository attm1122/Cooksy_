/**
 * RevenueCat Subscription Integration
 * Handles purchases, entitlements, and subscription status
 */

import type { CustomerInfo, PurchasesError, PurchasesPackage } from 'react-native-purchases';
import { Platform } from 'react-native';
import { supabase } from './supabase';
import { captureError } from './monitoring';

type RevenueCatModule = typeof import('react-native-purchases');

let purchasesModulePromise: Promise<RevenueCatModule> | null = null;

async function getRevenueCatModule(): Promise<RevenueCatModule> {
  if (!purchasesModulePromise) {
    purchasesModulePromise = import('react-native-purchases');
  }

  return purchasesModulePromise;
}

// RevenueCat API Keys - configure in .env
const REVENUECAT_IOS_KEY = process.env.EXPO_PUBLIC_REVENUECAT_IOS_KEY;
const REVENUECAT_ANDROID_KEY = process.env.EXPO_PUBLIC_REVENUECAT_ANDROID_KEY;
const REVENUECAT_WEB_KEY = process.env.EXPO_PUBLIC_REVENUECAT_WEB_KEY;

// Product IDs configured in RevenueCat Dashboard
export const PRODUCT_IDS = {
  MONTHLY: 'cooksy_premium_monthly',
  YEARLY: 'cooksy_premium_yearly',
} as const;

// Entitlement IDs from RevenueCat
export const ENTITLEMENTS = {
  PREMIUM: 'premium',
} as const;

// Feature flags based on entitlements
export interface SubscriptionFeatures {
  canDelete: boolean;
  canCreateBooks: boolean;
  unlimitedUploads: boolean;
  tiktokImports: boolean;
  instagramImports: boolean;
}

export interface SubscriptionState {
  isPremium: boolean;
  isLoading: boolean;
  customerInfo: CustomerInfo | null;
  offerings: PurchasesPackage[] | null;
  currentPlan: 'free' | 'monthly' | 'yearly' | null;
  expiresDate: string | null;
  willRenew: boolean;
  features: SubscriptionFeatures;
  uploadsRemaining: number; // -1 = unlimited
}

// Initial state
export const initialSubscriptionState: SubscriptionState = {
  isPremium: false,
  isLoading: true,
  customerInfo: null,
  offerings: null,
  currentPlan: null,
  expiresDate: null,
  willRenew: false,
  features: {
    canDelete: false,
    canCreateBooks: false,
    unlimitedUploads: false,
    tiktokImports: false,
    instagramImports: false,
  },
  uploadsRemaining: 3,
};

// Initialize RevenueCat
export async function initializePurchases(userId: string): Promise<void> {
  const { default: Purchases, LOG_LEVEL } = await getRevenueCatModule();
  const apiKey = Platform.select({
    ios: REVENUECAT_IOS_KEY,
    android: REVENUECAT_ANDROID_KEY,
    default: REVENUECAT_WEB_KEY,
  });

  if (!apiKey) {
    captureMessage('RevenueCat API key not configured — subscriptions will not function', {
      platform: Platform.OS,
      action: 'subscription_init_skipped'
    });
    return;
  }

  // Enable debug logs in development
  if (__DEV__) {
    Purchases.setLogLevel(LOG_LEVEL.DEBUG);
  }

  Purchases.configure({ apiKey, appUserID: userId });
  
  // Sync with Supabase on initialization
  await syncSubscriptionStatus(userId);
}

// Get available offerings (pricing packages)
export async function getOfferings(): Promise<PurchasesPackage[] | null> {
  try {
    const { default: Purchases } = await getRevenueCatModule();
    const offerings = await Purchases.getOfferings();
    
    if (offerings.current) {
      return offerings.current.availablePackages;
    }
    
    return null;
  } catch (error) {
    captureError(error, { action: 'subscription_get_offerings' });
    return null;
  }
}

// Purchase a package
export async function purchasePackage(
  pkg: PurchasesPackage
): Promise<{ success: boolean; error?: string }> {
  try {
    const { default: Purchases } = await getRevenueCatModule();
    const { customerInfo } = await Purchases.purchasePackage(pkg);
    
    // Sync with server
    await syncSubscriptionStatusFromCustomerInfo(customerInfo);
    
    return { success: true };
  } catch (error) {
    const purchasesError = error as PurchasesError;
    
    // User cancelled - not an error
    if (purchasesError.code === '1') { // PURCHASE_CANCELLED
      return { success: false };
    }
    
    return { 
      success: false, 
      error: purchasesError.message || 'Purchase failed' 
    };
  }
}

// Restore purchases
export async function restorePurchases(): Promise<{ 
  success: boolean; 
  isPremium: boolean;
  error?: string 
}> {
  try {
    const { default: Purchases } = await getRevenueCatModule();
    const customerInfo = await Purchases.restorePurchases();
    await syncSubscriptionStatusFromCustomerInfo(customerInfo);
    
    const isPremium = customerInfo.entitlements.active[ENTITLEMENTS.PREMIUM] !== undefined;
    
    return { success: true, isPremium };
  } catch (error) {
    const purchasesError = error as PurchasesError;
    return { 
      success: false, 
      isPremium: false,
      error: purchasesError.message 
    };
  }
}

// Get customer info
export async function getCustomerInfo(): Promise<CustomerInfo | null> {
  try {
    const { default: Purchases } = await getRevenueCatModule();
    return await Purchases.getCustomerInfo();
  } catch (error) {
    captureError(error, { action: 'subscription_get_customer_info' });
    return null;
  }
}

// Check if user has active premium subscription
export function isPremiumSubscriber(customerInfo: CustomerInfo | null): boolean {
  if (!customerInfo) return false;
  return customerInfo.entitlements.active[ENTITLEMENTS.PREMIUM] !== undefined;
}

// Get subscription expiration date
export function getSubscriptionExpiry(customerInfo: CustomerInfo | null): string | null {
  if (!customerInfo) return null;
  const premium = customerInfo.entitlements.active[ENTITLEMENTS.PREMIUM];
  return premium?.expirationDate || null;
}

// Check if subscription will renew
export function willSubscriptionRenew(customerInfo: CustomerInfo | null): boolean {
  if (!customerInfo) return false;
  const premium = customerInfo.entitlements.active[ENTITLEMENTS.PREMIUM];
  return premium?.willRenew || false;
}

// Get current plan type
export function getCurrentPlan(customerInfo: CustomerInfo | null): 'monthly' | 'yearly' | null {
  if (!customerInfo) return null;
  
  const premium = customerInfo.entitlements.active[ENTITLEMENTS.PREMIUM];
  if (!premium) return null;
  
  const productIdentifier = premium.productIdentifier;
  
  if (productIdentifier.includes('yearly')) return 'yearly';
  if (productIdentifier.includes('monthly')) return 'monthly';
  
  return null;
}

// Sync subscription status with Supabase
async function syncSubscriptionStatus(userId: string): Promise<void> {
  try {
    const customerInfo = await getCustomerInfo();
    if (customerInfo) {
      await syncSubscriptionStatusFromCustomerInfo(customerInfo);
    }
  } catch (error) {
    captureError(error, { action: 'subscription_sync_status' });
  }
}

// Sync customer info to Supabase
async function syncSubscriptionStatusFromCustomerInfo(
  customerInfo: CustomerInfo
): Promise<void> {
  if (!supabase) return;
  
  const isPremium = isPremiumSubscriber(customerInfo);
  const plan = getCurrentPlan(customerInfo);
  const expiry = getSubscriptionExpiry(customerInfo);
  const willRenew = willSubscriptionRenew(customerInfo);
  
  // Get platform from customer info
  const platform = customerInfo.originalPurchaseDate ? 
    (Platform.OS === 'ios' ? 'ios' : 'android') : 
    'web';
  
  try {
    await supabase.rpc('sync_revenuecat_subscription', {
      p_is_premium: isPremium,
      p_plan_id: plan ? `cooksy_premium_${plan}` : null,
      p_expires_at: expiry,
      p_will_renew: willRenew,
      p_platform: platform,
      p_revenuecat_customer_id: customerInfo.originalAppUserId,
    });
  } catch (error) {
    captureError(error, { action: 'subscription_sync_to_supabase' });
  }
}

// Get features based on subscription status
export function getFeatures(isPremium: boolean): SubscriptionFeatures {
  if (isPremium) {
    return {
      canDelete: true,
      canCreateBooks: true,
      unlimitedUploads: true,
      tiktokImports: true,
      instagramImports: true,
    };
  }
  
  // Free tier
  return {
    canDelete: false,
    canCreateBooks: false,
    unlimitedUploads: false,
    tiktokImports: false,
    instagramImports: false,
  };
}

// Get pricing with PPP adjustment
export async function getPricingForRegion(): Promise<{
  monthly: number;
  yearly: number;
  monthlyDisplay: string;
  yearlyDisplay: string;
  savingsPercent: number;
  currency: string;
} | null> {
  if (!supabase) return null;
  
  try {
    // Get pricing from Supabase
    const { data, error } = await supabase.rpc('get_pricing_for_country');
    
    if (error || !data) {
      // Fallback to AUD pricing
      return {
        monthly: 599,
        yearly: 6000,
        monthlyDisplay: '$5.99',
        yearlyDisplay: '$60',
        savingsPercent: 17,
        currency: 'AUD',
      };
    }
    
    return {
      monthly: data.monthly,
      yearly: data.yearly,
      monthlyDisplay: data.monthly_display,
      yearlyDisplay: data.yearly_display,
      savingsPercent: data.yearly_savings,
      currency: data.currency,
    };
  } catch (error) {
    captureError(error, { action: 'subscription_get_pricing' });
    return null;
  }
}

// Present paywall (using RevenueCat Paywall UI)
export async function presentPaywall(): Promise<boolean> {
  try {
    // This uses RevenueCat's native paywall UI
    // Available in react-native-purchases-ui
    const { default: RevenueCatUI } = await import('react-native-purchases-ui');
    const paywallResult = await RevenueCatUI.presentPaywallIfNeeded({
      requiredEntitlementIdentifier: ENTITLEMENTS.PREMIUM,
    });
    
    return paywallResult === 'PURCHASED' || paywallResult === 'RESTORED';
  } catch (error) {
    captureError(error, { action: 'subscription_present_paywall' });
    return false;
  }
}

// Present paywall if needed (based on feature)
export async function presentPaywallIfNeeded(
  feature: keyof SubscriptionFeatures
): Promise<boolean> {
  const customerInfo = await getCustomerInfo();
  const features = getFeatures(isPremiumSubscriber(customerInfo));
  
  if (features[feature]) {
    return true; // Feature available
  }
  
  // Show paywall
  return presentPaywall();
}

// Check upload availability
export async function canUpload(): Promise<{
  allowed: boolean;
  remaining: number;
  reason?: string;
}> {
  const customerInfo = await getCustomerInfo();
  
  // Premium users can always upload
  if (isPremiumSubscriber(customerInfo)) {
    return { allowed: true, remaining: -1 };
  }
  
  // Check free tier quota from Supabase
  if (!supabase) {
    return { allowed: false, remaining: 0, reason: 'Not connected' };
  }
  
  try {
    const { data: remaining, error } = await supabase.rpc('get_remaining_uploads', {
      p_user_id: (await supabase.auth.getUser()).data.user?.id,
    });
    
    if (error) throw error;
    
    return {
      allowed: remaining > 0,
      remaining: remaining,
      reason: remaining <= 0 ? 'Free limit reached. Upgrade to Premium.' : undefined,
    };
  } catch (error) {
    captureError(error, { action: 'subscription_check_upload_quota' });
    return { allowed: false, remaining: 0, reason: 'Error checking quota' };
  }
}

// Increment upload count
export async function trackUpload(): Promise<void> {
  if (!supabase) return;
  
  try {
    await supabase.rpc('increment_upload_count', {
      p_user_id: (await supabase.auth.getUser()).data.user?.id,
    });
  } catch (error) {
    captureError(error, { action: 'subscription_track_upload' });
  }
}

// Format price for display
export function formatPrice(cents: number, currency: string): string {
  const amount = cents / 100;
  
  const formatters: Record<string, Intl.NumberFormat> = {
    AUD: new Intl.NumberFormat('en-AU', { style: 'currency', currency: 'AUD' }),
    USD: new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }),
    EUR: new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }),
    GBP: new Intl.NumberFormat('en-GB', { style: 'currency', currency: 'GBP' }),
    JPY: new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY' }),
    CAD: new Intl.NumberFormat('en-CA', { style: 'currency', currency: 'CAD' }),
  };
  
  const formatter = formatters[currency];
  if (formatter) {
    return formatter.format(amount);
  }
  
  // Fallback
  return `$${amount.toFixed(2)}`;
}

// Customer support helper - get management URL
export async function getManagementURL(): Promise<string | null> {
  try {
    const customerInfo = await getCustomerInfo();
    
    // iOS uses App Store
    if (Platform.OS === 'ios') {
      return 'https://apps.apple.com/account/subscriptions';
    }
    
    // Android uses Play Store
    if (Platform.OS === 'android') {
      return 'https://play.google.com/store/account/subscriptions';
    }
    
    // Web - use RevenueCat management URL if available
    return customerInfo?.managementURL || null;
  } catch {
    return null;
  }
}
