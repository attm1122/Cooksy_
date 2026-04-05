/**
 * Subscription Store
 * Manages subscription state and provides reactive access to entitlements
 */

import { create } from 'zustand';
import Purchases, { CustomerInfo, PurchasesPackage } from 'react-native-purchases';
import { subscribeWithSelector } from '@/lib/zustand-middleware';
import {
  SubscriptionState,
  initialSubscriptionState,
  getFeatures,
  isPremiumSubscriber,
  getCurrentPlan,
  getSubscriptionExpiry,
  willSubscriptionRenew,
  getOfferings,
  getCustomerInfo,
  canUpload as checkCanUpload,
} from '@/lib/subscription';

interface SubscriptionStore extends SubscriptionState {
  // Actions
  initialize: (userId: string) => Promise<void>;
  refresh: () => Promise<void>;
  reset: () => void;
  setCustomerInfo: (info: CustomerInfo | null) => void;
  setOfferings: (offerings: PurchasesPackage[] | null) => void;
  setLoading: (loading: boolean) => void;
  
  // Helpers
  checkFeature: (feature: keyof SubscriptionState['features']) => boolean;
  checkUpload: () => Promise<{ allowed: boolean; remaining: number; reason?: string }>;
  getMonthlyPackage: () => PurchasesPackage | undefined;
  getYearlyPackage: () => PurchasesPackage | undefined;
}

export const useSubscriptionStore = create<SubscriptionStore>()(
  subscribeWithSelector((set, get) => ({
    ...initialSubscriptionState,

    initialize: async (userId: string) => {
      set({ isLoading: true });
      
      try {
        // Import and initialize
        const { initializePurchases } = await import('@/lib/subscription');
        await initializePurchases(userId);
        
        // Get initial data
        const [customerInfo, offerings] = await Promise.all([
          getCustomerInfo(),
          getOfferings(),
        ]);
        
        const isPremium = isPremiumSubscriber(customerInfo);
        
        set({
          customerInfo,
          offerings,
          isPremium,
          currentPlan: getCurrentPlan(customerInfo),
          expiresDate: getSubscriptionExpiry(customerInfo),
          willRenew: willSubscriptionRenew(customerInfo),
          features: getFeatures(isPremium),
          isLoading: false,
        });
        
        // Set up listener for changes
        Purchases.addCustomerInfoUpdateListener((info) => {
          const newIsPremium = isPremiumSubscriber(info);
          set({
            customerInfo: info,
            isPremium: newIsPremium,
            currentPlan: getCurrentPlan(info),
            expiresDate: getSubscriptionExpiry(info),
            willRenew: willSubscriptionRenew(info),
            features: getFeatures(newIsPremium),
          });
        });
      } catch (error) {
        console.error('Failed to initialize subscription store:', error);
        set({ isLoading: false });
      }
    },

    refresh: async () => {
      set({ isLoading: true });
      
      try {
        const [customerInfo, offerings, uploadStatus] = await Promise.all([
          getCustomerInfo(),
          getOfferings(),
          checkCanUpload(),
        ]);
        
        const isPremium = isPremiumSubscriber(customerInfo);
        
        set({
          customerInfo,
          offerings,
          isPremium,
          currentPlan: getCurrentPlan(customerInfo),
          expiresDate: getSubscriptionExpiry(customerInfo),
          willRenew: willSubscriptionRenew(customerInfo),
          features: getFeatures(isPremium),
          uploadsRemaining: uploadStatus.remaining,
          isLoading: false,
        });
      } catch (error) {
        console.error('Failed to refresh subscription:', error);
        set({ isLoading: false });
      }
    },

    reset: () => set({ ...initialSubscriptionState }),

    setCustomerInfo: (info) => {
      const isPremium = isPremiumSubscriber(info);
      set({
        customerInfo: info,
        isPremium,
        currentPlan: getCurrentPlan(info),
        expiresDate: getSubscriptionExpiry(info),
        willRenew: willSubscriptionRenew(info),
        features: getFeatures(isPremium),
      });
    },

    setOfferings: (offerings) => set({ offerings }),
    setLoading: (loading) => set({ isLoading: loading }),

    checkFeature: (feature) => {
      return get().features[feature];
    },

    checkUpload: async () => {
      const result = await checkCanUpload();
      set({ uploadsRemaining: result.remaining });
      return result;
    },

    getMonthlyPackage: () => {
      return get().offerings?.find(p => 
        p.product.identifier.includes('monthly')
      );
    },

    getYearlyPackage: () => {
      return get().offerings?.find(p => 
        p.product.identifier.includes('yearly')
      );
    },
  }))
);

// Selectors for better performance
export const selectIsPremium = (state: SubscriptionStore) => state.isPremium;
export const selectIsLoading = (state: SubscriptionStore) => state.isLoading;
export const selectFeatures = (state: SubscriptionStore) => state.features;
export const selectOfferings = (state: SubscriptionStore) => state.offerings;
export const selectUploadsRemaining = (state: SubscriptionStore) => state.uploadsRemaining;
export const selectCurrentPlan = (state: SubscriptionStore) => state.currentPlan;
export const selectWillRenew = (state: SubscriptionStore) => state.willRenew;

// Hook for checking specific feature
export function useFeature(feature: keyof SubscriptionState['features']): boolean {
  return useSubscriptionStore((state) => state.features[feature]);
}

// Hook for premium status
export function useIsPremium(): boolean {
  return useSubscriptionStore(selectIsPremium);
}

// Hook for upload availability
export function useCanUpload(): { allowed: boolean; remaining: number } {
  const isPremium = useIsPremium();
  const remaining = useSubscriptionStore(selectUploadsRemaining);
  
  return {
    allowed: isPremium || remaining > 0,
    remaining: isPremium ? -1 : remaining,
  };
}

// Hook for checking if user can delete
export function useCanDelete(): boolean {
  return useFeature('canDelete');
}

// Hook for checking if user can create books
export function useCanCreateBooks(): boolean {
  return useFeature('canCreateBooks');
}

// Hook for platform availability
export function usePlatformImport(platform: 'tiktok' | 'instagram'): boolean {
  const feature = platform === 'tiktok' ? 'tiktokImports' : 'instagramImports';
  return useFeature(feature);
}
