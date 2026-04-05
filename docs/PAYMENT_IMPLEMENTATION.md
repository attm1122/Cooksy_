# Payment Implementation Guide

**Date:** April 2026  
**Status:** Implementation Complete ✅

---

## Overview

Complete payment system with RevenueCat integration for iOS, Android, and Web. Supports free tier with limits and premium subscription with global PPP pricing.

---

## 📊 Pricing Structure

### Free Tier
| Feature | Limit |
|---------|-------|
| Recipe uploads | 3 total |
| Import platforms | YouTube only |
| Recipe books | Not available |
| Delete recipes | Not available |

### Premium Tier
| Feature | Included |
|---------|----------|
| Recipe uploads | Unlimited |
| Import platforms | YouTube, TikTok, Instagram |
| Recipe books | Unlimited |
| Delete recipes | Yes |
| Price (AUD) | $5.99/mo or $60/yr (17% savings) |

### Global PPP Pricing (Netflix Model)
Base currency: **AUD**

| Tier | Markets | Discount | Monthly Price |
|------|---------|----------|---------------|
| 1 | AU, US, CA, UK, NZ, CH | Base | $5.99 AUD |
| 2 | JP, KR, SG, HK, TW, IL | 10% off | Local currency |
| 3 | DE, FR, IT, ES, NL, etc. | 25% off | Local currency |
| 4 | BR, MX, AR, IN, etc. | 45% off | Local currency |
| 5 | NG, PK, BD, KE | 60% off | Local currency |

---

## 🏗️ Architecture

### RevenueCat Integration
- **SDK:** `react-native-purchases` (client-side)
- **Webhooks:** Edge function for server sync
- **Products:** 
  - `cooksy_premium_monthly` ($5.99 AUD)
  - `cooksy_premium_yearly` ($60 AUD)
- **Entitlement:** `premium`

### Database Schema
```
entitlements              - Feature flags
subscription_plans        - Plan definitions
plan_entitlements         - Plan → Feature mapping
user_subscriptions        - User subscription status
user_upload_quota         - Free tier tracking
pricing_by_country        - PPP pricing data
revenuecat_webhook_events - Audit log
```

### Client-Side Hooks
```typescript
useIsPremium()           // Check premium status
useCanUpload()           // Check upload availability
useCanDelete()           // Check delete permission
useCanCreateBooks()      // Check books permission
usePlatformImport()      // Check platform availability
```

---

## 🚀 Setup Instructions

### 1. RevenueCat Dashboard Configuration

#### Create Products
1. Go to RevenueCat Dashboard → Products
2. Create App Store product: `cooksy_premium_monthly` ($5.99)
3. Create App Store product: `cooksy_premium_yearly` ($59.99)
4. Link to App Store Connect products
5. Repeat for Google Play Console

#### Create Entitlement
1. Go to Entitlements
2. Create `premium` entitlement
3. Attach both products to entitlement

#### Configure Webhook
1. Go to Integrations → Webhooks
2. Add webhook URL: `https://<project>.supabase.co/functions/v1/revenuecat-webhook`
3. Add Authorization header with secret
4. Select events: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION

### 2. Environment Variables

Add to `.env`:
```bash
# RevenueCat API Keys (from RevenueCat Dashboard)
EXPO_PUBLIC_REVENUECAT_IOS_KEY=appl_xxxxxxxx
EXPO_PUBLIC_REVENUECAT_ANDROID_KEY=goog_xxxxxxxx
EXPO_PUBLIC_REVENUECAT_WEB_KEY=rcb_xxxxxxxx

# Webhook secret
REVENUECAT_WEBHOOK_AUTH=your_webhook_secret
```

### 3. Deploy Edge Function

```bash
supabase functions deploy revenuecat-webhook
supabase secrets set REVENUECAT_WEBHOOK_AUTH=your_webhook_secret
```

### 4. Deploy Database Migration

```bash
supabase db push
```

### 5. App Store / Play Store Configuration

#### App Store Connect
1. Create subscription group: "Cooksy Premium"
2. Create products:
   - Monthly: $5.99 AUD
   - Yearly: $59.99 AUD
3. Configure intro offers (7-day free trial)
4. Add localization for supported countries

#### Google Play Console
1. Create subscription: "Cooksy Premium Monthly"
2. Create subscription: "Cooksy Premium Yearly"
3. Configure base plan and offers
4. Add 7-day free trial
5. Set pricing for all countries

---

## 📱 Usage

### Initialize Subscription Store

```typescript
import { useSubscriptionStore } from '@/src/stores/subscription-store';

// In app initialization:
const userId = await getCurrentUserId();
await useSubscriptionStore.getState().initialize(userId);
```

### Check Permissions

```typescript
import { useCanUpload, useCanDelete, useIsPremium } from '@/src/stores/subscription-store';

function MyComponent() {
  const { allowed, remaining } = useCanUpload();
  const canDelete = useCanDelete();
  const isPremium = useIsPremium();
  
  if (!allowed) {
    return <UpgradePrompt feature="upload" />;
  }
}
```

### Show Paywall

```typescript
import { useRouter } from 'expo-router';

const router = useRouter();

// Navigate to paywall
router.push('/subscription/paywall');

// Or present modal
import { Paywall } from '@/src/components/subscription/Paywall';

<Paywall 
  onClose={() => router.back()}
  onSubscribe={() => {
    // Handle successful subscription
  }}
/>
```

### Handle Import with Limits

```typescript
import { beginRecipeImport } from '@/src/services/import-service';

try {
  const result = await beginRecipeImport(url);
  // Proceed with import
} catch (error) {
  if (error.message.includes('Upload limit')) {
    // Show paywall
    router.push('/subscription/paywall');
  }
}
```

---

## 🎨 UI Components

### Paywall
Full-screen paywall with plan comparison and purchase flow.

### PremiumBadge
Small badge showing premium status in headers.

### UpgradePrompt
Modal/dialog for triggering paywall on restricted actions.

### UpgradeBanner
Inline banner for embedding in lists.

---

## 🔒 Security Considerations

1. **Server-side validation:** Always verify entitlements server-side
2. **Receipt validation:** RevenueCat handles this automatically
3. **Webhook verification:** Use secret to verify webhook authenticity
4. **Grace periods:** Handle billing issues gracefully
5. **Transfer support:** Support account restoration on new devices

---

## 📊 Analytics Events

| Event | Properties |
|-------|------------|
| `subscription_initiated` | plan, source |
| `subscription_completed` | plan, platform, isTrial |
| `subscription_cancelled` | plan, reason |
| `subscription_restored` | platform |
| `paywall_shown` | source, feature |
| `paywall_dismissed` | source |

---

## 🧪 Testing

### Sandbox Testing

#### iOS
1. Create sandbox tester in App Store Connect
2. Sign in with sandbox Apple ID on device
3. Test purchases (no charge)

#### Android
1. Add tester email to Play Console
2. Use test credit cards:
   - Always approves: `4111111111111111`
   - Always declines: `4000000000000002`

#### Web
1. Use Stripe test mode
2. Test cards: https://stripe.com/docs/testing

### RevenueCat Sandbox
1. Enable sandbox mode in RevenueCat dashboard
2. Use sandbox API keys
3. Webhooks fire immediately (no delay)

---

## 🚨 Common Issues

### "Product not found"
- Check RevenueCat product IDs match code
- Verify products approved in App Store/Play Console
- Wait 24 hours after product creation

### "Purchase not working on device"
- Use physical device (not simulator)
- Sign out of real Apple ID, use sandbox
- Check bundle ID matches

### "Webhooks not receiving"
- Verify webhook URL accessible
- Check authorization header
- Review Supabase function logs

---

## 📚 Resources

- [RevenueCat Docs](https://www.revenuecat.com/docs)
- [React Native Purchases](https://github.com/RevenueCat/react-native-purchases)
- [App Store Subscriptions](https://developer.apple.com/in-app-purchase/)
- [Play Billing Library](https://developer.android.com/google/play/billing)

---

## Next Steps

1. **Configure RevenueCat Dashboard** with products
2. **Add environment variables** to project
3. **Test purchases** in sandbox
4. **Deploy to staging** and verify
5. **Submit for review** (App Store / Play Store)
6. **Monitor** webhook events and conversion
