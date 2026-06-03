# Cooksy App Store Launch Checklist

> **App:** Cooksy — Recipe Import & Cook-Along
> **Platform:** iOS 17+
> **Bundle ID:** `com.cooksy.app`
> **Repository:** https://github.com/attm1122/Cooksy_
> **Last Updated:** 2026-05-10

---

## Table of Contents
1. [Pre-Launch: Apple Developer Setup](#phase-1-apple-developer-setup)
2. [Pre-Launch: Backend Configuration](#phase-2-backend-configuration)
3. [Pre-Launch: Legal & Compliance](#phase-3-legal--compliance)
4. [Build: Xcode Project Setup](#phase-4-xcode-project-setup)
5. [Build: App Store Connect](#phase-5-app-store-connect)
6. [Submit: App Store Review](#phase-6-app-store-review)
7. [Post-Launch](#phase-7-post-launch)
8. [Quick Reference: Screenshot Requirements](#quick-reference-screenshots)
9. [Quick Reference: App Store Metadata](#quick-reference-metadata)

---

## Phase 1: Apple Developer Setup

| # | Task | Cost | Est. Time | Done |
|---|------|------|-----------|------|
| 1.1 | Enroll in **Apple Developer Program** at https://developer.apple.com/enroll/ | $99/year | 1-2 days (approval) | [ ] |
| 1.2 | Accept all developer agreements in **App Store Connect** | Included | 5 min | [ ] |
| 1.3 | Verify your **tax and banking information** in App Store Connect (required for paid apps/subscriptions) | Free | 15 min | [ ] |
| 1.4 | Enable **Two-Factor Authentication** on your Apple ID (required) | Free | 5 min | [ ] |

---

## Phase 2: Backend Configuration

### 2.1 Supabase (Database & Auth)

| # | Task | Location | Done |
|---|------|----------|------|
| 2.1.1 | Create the following tables in Supabase: | Supabase Dashboard > Table Editor | [ ] |
| | `recipes` — id, user_id, title, description, image_url, source_url, source_platform, cook_time, prep_time, servings, difficulty, created_at | | |
| | `recipe_steps` — id, recipe_id, step_number, instruction, duration_seconds, timestamp_seconds | | |
| | `ingredients` — id, recipe_id, name, quantity, unit, is_checked | | |
| | `recipe_books` — id, user_id, title, color_hex, icon_name, created_at | | |
| | `recipe_book_items` — id, book_id, recipe_id, added_at | | |
| 2.1.2 | **Enable Row Level Security (RLS)** on all tables — users can only access their own data | Supabase Dashboard > Authentication > Policies | [ ] |
| 2.1.3 | Enable **Apple Sign-In** as auth provider (fill in Apple Services ID and Private Key) | Supabase Dashboard > Authentication > Providers | [ ] |
| 2.1.4 | Enable **Magic Link / OTP** email authentication | Supabase Dashboard > Authentication > Providers | [ ] |
| 2.1.5 | Confirm the **anon key** in your Cooksy code matches your Supabase project settings | Verify in code + dashboard | [ ] |

### 2.2 RevenueCat (In-App Purchases)

| # | Task | Location | Done |
|---|------|----------|------|
| 2.2.1 | Create App in RevenueCat dashboard with your **Apple App-Specific Shared Secret** | RevenueCat Dashboard > + New App | [ ] |
| 2.2.2 | Create **3 products** in App Store Connect first, then sync to RevenueCat: | App Store Connect > Features > In-App Purchases | [ ] |
| | - `cooksy_monthly` — Consumable/Auto-Renewable, $4.99/month | | |
| | - `cooksy_yearly` — Auto-Renewable, $39.99/year | | |
| | - `cooksy_lifetime` — Non-Consumable, $99.99 one-time | | |
| 2.2.3 | Create an **Offering** called `default` containing all 3 products | RevenueCat Dashboard > Offerings | [ ] |
| 2.2.4 | Create an **Entitlement** called `cooksy_pro` linked to all 3 products | RevenueCat Dashboard > Entitlements | [ ] |
| 2.2.5 | Add the **RevenueCat API key** to your Cooksy code (already obfuscated in `SecureKeyObfuscation.swift`) | Verify key matches dashboard | [ ] |
| 2.2.6 | Configure **Apple Server Notifications** in RevenueCat (for subscription status updates) | RevenueCat > Project Settings > Apple | [ ] |

---

## Phase 3: Legal & Compliance

| # | Task | Details | Done |
|---|------|---------|------|
| 3.1 | **Privacy Policy** — Host a privacy policy page at `https://cooksy.app/privacy` (or any public URL) | Required by App Store + ATT framework. Must disclose: email collection, anonymous analytics, local storage, Supabase backend, RevenueCat purchases. | [ ] |
| 3.2 | **Terms of Service** — Host at `https://cooksy.app/terms` (or any public URL) | Required for subscription apps. Cover: subscription terms, cancellation, refund policy, user content, account termination. | [ ] |
| 3.3 | **App Store Privacy Questionnaire** — Answer Apple's privacy questions in App Store Connect | Categories: Contact Info (Email), User Content (Recipes), Purchases. Select "Data Not Linked to Identity" where applicable. | [ ] |

---

## Phase 4: Xcode Project Setup

| # | Task | Detailed Steps | Done |
|---|------|----------------|------|
| 4.1 | **Open project in Xcode** | Launch Xcode 15+ → File → Open → Select `/mnt/agents/output/project/Package.swift` | [ ] |
| 4.2 | **Resolve packages** | Xcode will auto-fetch Supabase and RevenueCat dependencies. If not: File > Packages > Resolve Package Versions | [ ] |
| 4.3 | **Configure Signing** | Project navigator → Cooksy → Signing & Capabilities → Select your **Team** → Enable "Automatically manage signing" | [ ] |
| 4.4 | **Set Bundle Identifier** | Change to `com.cooksy.app` (or your chosen bundle ID). This MUST match your App Store Connect record. | [ ] |
| 4.5 | **Set Version and Build** | Marketing Version: `1.0.0`, Build: `1`. Match these in App Store Connect. | [ ] |
| 4.6 | **Add the ATS configuration** from `AppTransportSecurity.md` into the project's `Info.plist` | Copy the XML snippet from `Core/Security/AppTransportSecurity.md` | [ ] |
| 4.7 | **Build and run on Simulator** (iPhone 15 Pro) | Product > Destination > iPhone 15 Pro → Product > Run. Verify app launches without crashes. | [ ] |
| 4.8 | **Build and run on a physical device** | Connect iPhone → Select device in Xcode → Product > Run. This verifies: signing works, entitlements are valid, push notifications register. | [ ] |
| 4.9 | **Test key user flows** on device: | | [ ] |
| | - Sign up with email OTP | | |
| | - Import a recipe from a YouTube URL | | |
| | - Save a recipe to a book | | |
| | - Start Cooking Mode | | |
| | - View subscription paywall | | |

---

## Phase 5: App Store Connect

### 5.1 Create App Record

| # | Task | Details | Done |
|---|------|---------|------|
| 5.1.1 | Go to https://appstoreconnect.apple.com/apps → Click **+** → "New App" | Platform: iOS, Bundle ID: `com.cooksy.app` | [ ] |
| 5.1.2 | Fill in **App Information** | | |
| | - Name | `Cooksy` (must be unique on App Store — if taken, try `Cooksy: Recipe Import`) | |
| | - Subtitle | `Save recipes from any video` (max 30 chars) | |
| | - Category | Primary: Food & Drink, Secondary: Lifestyle | |
| | - Content Rights | Confirm you own/have rights to all content | |
| 5.1.3 | Fill in **Pricing and Availability** | Price: Free (subscriptions handle monetization), Available in all territories | [ ] |
| 5.1.4 | Fill in **App Privacy** | Answer questionnaire. Link to your privacy policy URL. | [ ] |

### 5.2 Prepare Submission

| # | Task | Details | Done |
|---|------|---------|------|
| 5.2.1 | Upload **screenshots** for iPhone 6.7" display | Use the 5 screenshots in `/AppStore/Screenshots/` (or capture real ones from Simulator at 1290x2796). Upload order: Home, Recipe Detail, Cooking Mode, Books, Premium. | [ ] |
| 5.2.2 | Upload **screenshots** for iPhone 5.5" display (optional but recommended) | iPhone 8 Plus size: 1242x2208. You can use the 6.7" screenshots and let Apple scale them, but dedicated 5.5" shots look better. | [ ] |
| 5.2.3 | Upload **App Icon** | The icon is already bundled in `Assets.xcassets/AppIcon.appiconset/`. Ensure 1024x1024 version is crisp. | [ ] |
| 5.2.4 | Fill in **Promotional Text** | `Import recipes from YouTube, TikTok, and Instagram. Cook along with step-by-step guidance synced to video.` (170 chars max) | [ ] |
| 5.2.5 | Fill in **Description** | See "Quick Reference: Metadata" below for the full description. | [ ] |
| 5.2.6 | Fill in **Keywords** | `recipe, cooking, food, meal, youtube, tiktok, instagram, import, kitchen, cookbook, planner, grocery, ingredients, chef, bake` (100 chars max) | [ ] |
| 5.2.7 | Fill in **Support URL** | Your support page (can be the same as your website) | [ ] |
| 5.2.8 | Fill in **Marketing URL** (optional) | Your app's landing page | [ ] |
| 5.2.9 | Upload **Build** via Xcode | Product > Archive → Distribute App → App Store Connect → Upload. Wait for processing (5-30 min). | [ ] |
| 5.2.10 | Select the uploaded build in App Store Connect | App Store Connect > Your App > iOS App > Build section → Select the build | [ ] |

### 5.3 App Review Information

| # | Task | Details | Done |
|---|------|---------|------|
| 5.3.1 | Fill in **App Review Information** | | [ ] |
| | - Sign-in required? | Yes — provide the App Review demo OTP below, or instructions to use Magic Link OTP | |
| | - Contact Information | Your name, phone, email | |
| | - Notes for reviewer | See "Review Notes" below | |
| 5.3.2 | Fill in **Release Option** | Choose: "Manually release this version after approval" (recommended for first launch) | [ ] |

---

## Phase 6: App Store Review

### Review Notes (copy-paste into App Store Connect)

```
Cooksy is a recipe import and cook-along app. Users paste YouTube, TikTok, or Instagram video URLs 
and the app extracts structured recipes with ingredients, steps, and cooking times.

TEST ACCOUNT:
- Email: appreview@cooksyapp.uk
- Verification code: 202626
- This demo code signs the reviewer directly into Cooksy with full app access.
- Other users can use Magic Link / OTP sign-in with their own email address.

KEY FEATURES TO TEST:
1. Recipe import — paste a YouTube cooking video URL
2. Ingredient checklist — tap to mark items as checked
3. Cooking Mode — step-by-step guidance with timers
4. Recipe Books — create collections and organize recipes
5. Cook-Along Video Sync — split-screen video + recipe steps (available with Cooksy Pro)

SUBSCRIPTION TESTING:
- Monthly ($4.99), Yearly ($39.99), and Lifetime ($99.99) options available
- RevenueCat handles purchase display, entitlement checks, and receipt validation
- The related App Store Connect in-app purchase products must be submitted with this app version
- Use sandbox Apple ID for testing subscriptions

PRIVACY:
- All recipe data stored locally via SwiftData
- Submitted recipe video links are sent to Cooksy's secure Supabase-backed processing service to extract ingredients, steps, and timings
- Optional Supabase sync for cross-device access
- EXIF metadata stripped from all uploaded images
- No third-party tracking
```

### Common Rejection Reasons & How We Prevented Them

| Risk | Cooksy Solution | Status |
|------|-----------------|--------|
| Dead button ends in blank screen | All buttons have implemented actions or disabled states | Resolved |
| Hardcoded pricing | RevenueCat fetches live prices from Apple — never hardcoded | Resolved |
| Missing entitlements | `Cooksy.entitlements` has `applesignin` + `aps-environment: production` | Resolved |
| Privacy manifest issues | `PrivacyInfo.xcprivacy` declares all collected data + API usage reasons | Resolved |
| Sign-in wall on first launch | Onboarding flow shown first, auth only when user chooses to sync/save | Resolved |
| No demo account | Magic Link OTP lets reviewers use any email — no pre-setup needed | Resolved |

---

## Phase 7: Post-Launch

| # | Task | When | Done |
|---|------|------|------|
| 7.1 | Monitor **App Store Connect Analytics** for crashes and retention | Daily for first week | [ ] |
| 7.2 | Monitor **RevenueCat Dashboard** for subscription metrics | Weekly | [ ] |
| 7.3 | Respond to **user reviews** in App Store Connect | Within 48 hours | [ ] |
| 7.4 | Set up **crash reporting** (e.g., Firebase Crashlytics or Sentry) | Week 1 | [ ] |
| 7.5 | Enable **Ratings & Reviews prompt** via `ReviewPromptService` (already implemented) | Automatic — fires after 3 recipe imports | [ ] |
| 7.6 | Plan **first update** — address any review feedback | Within 2 weeks | [ ] |

---

## Quick Reference: Screenshots

### Required Sizes

| Display Size | Resolution | Devices | Status |
|-------------|------------|---------|--------|
| 6.7" | 1290 x 2796 px | iPhone 14 Pro Max, 15 Plus, 15 Pro Max, 16 Plus, 16 Pro Max | 5 screenshots generated |
| 6.1" | 1179 x 2556 px | iPhone 14 Pro, 15, 15 Pro, 16, 16 Pro | Scaled from 6.7" |
| 5.5" | 1242 x 2208 px | iPhone 8 Plus | Optional |

### Screenshot File Locations

```
project/AppStore/Screenshots/
  Screenshot1_Home.png          — Recipe discovery feed
  Screenshot2_RecipeDetail.png  — Recipe with ingredient checklist
  Screenshot3_CookingMode.png   — Step-by-step cooking guidance
  Screenshot4_Books.png         — Recipe book collections
  Screenshot5_Premium.png       — Cooksy Pro subscription
```

### Screenshot Tips
- Upload **portrait** orientation (required for food apps)
- First screenshot is most important — make it your best
- No status bar or hardware buttons should be visible
- Content should fill the entire screen
- Use real device frames for marketing, but App Store screenshots should be frameless

---

## Quick Reference: Metadata

### App Name
```
Cooksy
```
(If taken: `Cooksy: Recipe Import`, `Cooksy - Recipe & Cook-Along`)

### Subtitle (30 chars max)
```
Save recipes from any video
```

### Description
```
Turn any cooking video into a step-by-step recipe. Import from YouTube, TikTok, and Instagram — Cooksy extracts ingredients, instructions, and cooking times automatically.

HOW IT WORKS
1. Paste a cooking video URL from YouTube, TikTok, or Instagram
2. Cooksy extracts the recipe — ingredients, steps, and timings
3. Cook along with guided step-by-step instructions
4. Save recipes to your personal cookbooks

FEATURES
- Recipe Import: Paste any cooking video URL and get a structured recipe
- Ingredient Checklist: Interactive checkboxes while you cook
- Cooking Mode: Clean, distraction-free step-by-step guidance with timers
- Recipe Books: Organize recipes into custom collections
- Cook-Along Video Sync: Watch the video while following steps side-by-side (Pro)
- Smart Scaling: Adjust recipe servings and ingredients auto-recalculate
- Works Offline: All recipes stored locally on your device

COOKSY PRO
Unlock unlimited imports, cook-along video sync, and unlimited recipe books:
- Monthly: $4.99
- Yearly: $39.99 (best value)
- Lifetime: $99.99 (one-time)

PRIVACY FIRST
- Your recipes are stored locally on your device
- Optional cloud sync via Supabase
- No third-party tracking
- EXIF metadata stripped from all images

Download Cooksy and never lose a recipe again.
```

### Keywords (100 chars)
```
recipe,cooking,food,meal,youtube,tiktok,instagram,import,kitchen,cookbook,planner,grocery,chef
```

### What's New (for v1.0.0)
```
Welcome to Cooksy! Import recipes from YouTube, TikTok, and Instagram. Cook along with guided step-by-step instructions. Create recipe books and organize your culinary collection.
```

### Review Demo Account
```
No demo account needed. Use Magic Link sign-in with any email address. Enter the OTP sent to your email to authenticate.
```

---

## File Reference

| File | Purpose | Location in Repo |
|------|---------|-----------------|
| Package.swift | SPM dependencies | Root |
| Info.plist | App configuration | `Sources/Cooksy/Resources/Info.plist` |
| Cooksy.entitlements | Capabilities | `Sources/Cooksy/Resources/Cooksy.entitlements` |
| PrivacyInfo.xcprivacy | Privacy manifest | `Sources/Cooksy/Resources/PrivacyInfo.xcprivacy` |
| AppIcon.appiconset | App icon (all sizes) | `Sources/Cooksy/Resources/Assets.xcassets/AppIcon.appiconset/` |
| AppTransportSecurity.md | ATS configuration reference | `Sources/Cooksy/Core/Security/AppTransportSecurity.md` |
| SubscriptionViewModel.swift | RevenueCat integration | `Sources/Cooksy/Features/Subscription/SubscriptionViewModel.swift` |
| SecureKeyObfuscation.swift | API key obfuscation | `Sources/Cooksy/Core/Security/SecureKeyObfuscation.swift` |
| App Store Screenshots | Marketing screenshots | `AppStore/Screenshots/` |

---

## Support Contacts

| Service | URL | For Issues With |
|---------|-----|-----------------|
| Apple Developer Support | https://developer.apple.com/contact/ | Xcode, signing, review |
| App Store Connect | https://appstoreconnect.apple.com/ | App listing, builds, analytics |
| RevenueCat Support | https://www.revenuecat.com/docs/ | In-app purchases, subscriptions |
| Supabase Support | https://supabase.com/docs/ | Database, auth, storage |

---

*This checklist was generated on 2026-05-10. Always refer to the latest Apple Developer Documentation and App Store Review Guidelines for the most current requirements.*
