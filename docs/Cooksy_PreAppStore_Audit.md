# Cooksy iOS — Pre-App Store Audit Report

**Audit Date:** 2025  
**App Version:** Pre-Submission  
**Platform:** iOS 17+  
**Architecture:** MVVM + SwiftData + Design System  
**Codebase:** 12,680 lines of Swift across 58 files (65 total Swift files in `Sources/Cooksy/`)  
**Key Dependencies:** RevenueCat (subscriptions), Supabase (backend)

---

## 1. Executive Summary

Cooksy is a well-architected iOS application built on modern Apple frameworks. The codebase demonstrates strong engineering practices: clean MVVM separation, SwiftData persistence with proper `@Model` and `@Relationship` annotations, comprehensive accessibility support (VoiceOver labels, Dynamic Type, Reduce Motion), and a thoughtful design system. The subscription layer via RevenueCat and the backend integration via Supabase are both wired correctly.

**Overall readiness: ~65% App Store ready.**

The app is functionally solid but has **four critical gaps** that would result in immediate App Store rejection or require emergency patches post-launch. These must be resolved before submission:

1. Missing entitlements file for Sign In with Apple
2. Mock service fallback that could ship with fake data
3. Analytics service silently dropping events in production
4. No App Tracking Transparency preparation for future analytics

Once the critical items are resolved, the remaining high-priority issues (onboarding, deep link navigation, review prompts, share sheets, offline handling, and loading states) should be addressed in a single sprint to bring the app to a competitive, launch-ready state. Medium and low-priority items can be scheduled for post-launch updates.

---

## 2. Critical Issues (App Store Rejection Risk)

> **Must be fixed before App Store submission. Any one of these could result in rejection or a broken production experience.**

| # | Issue | Severity | Category |
|---|-------|----------|----------|
| C-01 | Missing `.entitlements` file for Sign In with Apple | Blocking | App Store Compliance |
| C-02 | MockSupabaseService fallback in production builds | Blocking | Data Integrity |
| C-03 | AnalyticsService TODO — events silently dropped in release | Blocking | Production Readiness |
| C-04 | No App Tracking Transparency (ATT) framework | Blocking | Privacy Compliance |

### C-01: No `.entitlements` file — Sign In with Apple

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Rejection Risk** | **Yes — guaranteed rejection** |
| **Location** | `AuthViewModel` + project root |

**Description:**
Sign In with Apple is fully implemented in code — `AuthViewModel` conforms to `ASAuthorizationControllerDelegate` and the UI flow is complete. However, **no `.entitlements` file exists in the project**. The entitlement `com.apple.developer.applesignin` is mandatory for any app that uses Sign In with Apple. Without it, the authentication request will fail at runtime, and Apple will reject the binary during App Store Review.

**Fix Required:**
1. Create `Cooksy.entitlements` in the project root:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```
2. Ensure the entitlements file is referenced in the app's Build Settings under **Code Signing Entitlements**.
3. Verify the App ID in the Apple Developer Portal has **Sign In with Apple** capability enabled.
4. Test a full Sign In with Apple flow on a physical device — simulators do not enforce entitlement checks.

**Estimated effort:** 15 minutes

---

### C-02: MockSupabaseService Fallback Ships Fake Data

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Rejection Risk** | High (functional app with fake data) |
| **Location** | `CooksyApp.init()` |

**Description:**
`CooksyApp.init()` checks for the `SUPABASE_URL` environment variable at build time. If the variable is missing, it falls back to `MockSupabaseService` — a service that returns hardcoded, fake recipe data. This means a release build created from a CI/CD pipeline (or a developer's local machine) without the proper environment variables would ship to users with completely fabricated content. This is a catastrophic data integrity failure.

**Fix Required:**
1. **Remove the silent fallback.** If `SUPABASE_URL` is missing, the app should `fatalError()` in debug builds with a clear message, and in release builds, show a user-facing error screen explaining that the service is temporarily unavailable.
2. Add a build-phase script that validates required environment variables are present before compilation:
```bash
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "error: Missing required Supabase environment variables"
    exit 1
fi
```
3. Document all required environment variables in a `.env.example` file and in the project README.

**Estimated effort:** 1 hour

---

### C-03: AnalyticsService Has a TODO — Events Dropped in Production

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Rejection Risk** | Moderate (broken functionality, not a direct rejection) |
| **Location** | `AnalyticsService.swift` |

**Description:**
The codebase contains a literal TODO comment: *"Wire to real analytics provider in production."* In `DEBUG` builds, events are printed to the console. In release builds (`#else`), events are silently discarded — no tracking, no logging, no crash reporting. Shipping this means you have **zero visibility** into user behavior, conversion funnels, crashes, or app performance post-launch. You cannot optimize what you cannot measure.

**Fix Required:**
1. Integrate a production analytics provider. Recommended options:
   - **Firebase Analytics** (free, integrates well with RevenueCat)
   - **Mixpanel** (strong funnel analysis)
   - **PostHog** (open-source, event-based)
2. Ensure all tracked events are privacy-compliant and respect user opt-out.
3. Remove the TODO comment once implemented.
4. If you choose not to ship with analytics initially, explicitly decide this and replace the service with a no-op that logs a warning, rather than silently dropping events.

**Estimated effort:** 2–4 hours (depending on provider)

---

### C-04: No App Tracking Transparency (ATT) Framework

| Field | Detail |
|-------|--------|
| **Severity** | Critical |
| **Rejection Risk** | Yes — if analytics with IDFA are added later |
| **Location** | `Info.plist` (missing entry) |

**Description:**
The `Info.plist` does not contain `NSUserTrackingUsageDescription`. If you integrate Firebase, Mixpanel, or any analytics provider that collects the IDFA (Identifier for Advertisers), Apple **requires** the ATT framework with a usage description string. Even if you don't use IDFA today, adding analytics post-launch without ATT already in place will trigger a rejection. It's far simpler to add the description now than to scramble during a later update.

**Fix Required:**
1. Add to `Info.plist`:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>Cooksy uses anonymized data to improve recipe recommendations and app performance. Your data is never sold to third parties.</string>
```
2. If/when you integrate an analytics provider that uses IDFA, call `ATTrackingManager.requestTrackingAuthorization()` before initializing the analytics SDK.

**Estimated effort:** 10 minutes

---

## 3. High Priority Issues (User Experience)

> **Will not cause rejection but will significantly hurt adoption, retention, and App Store ratings. Should be fixed before launch.**

| # | Issue | Impact | Category |
|---|-------|--------|----------|
| H-01 | No onboarding flow | Poor first-time conversion | User Acquisition |
| H-02 | Deep link shows placeholder instead of RecipeDetailView | Broken navigation | Deep Linking |
| H-03 | No SKStoreReviewController | Missed reviews | App Store Optimization |
| H-04 | No share sheet implementation | Viral growth blocked | Social / Sharing |
| H-05 | No network reachability / offline handling | Confusing UX | Reliability |
| H-06 | No skeleton/shimmer loading states | Perceived slowness | Perceived Performance |
| H-07 | TimestampExtractionService has 2 TODOs | Core feature broken | Feature Completeness |

### H-01: No Onboarding Flow

| Field | Detail |
|-------|--------|
| **Impact** | Users who don't understand the value prop will bounce before signing in |
| **Location** | `AuthView` (first screen) |

**Description:**
First-time users land directly on the authentication screen with no context. They don't know what Cooksy does, why they should sign in, or what value the app provides. This is a major conversion bottleneck — users who are asked to authenticate before understanding the app's purpose have significantly lower sign-up rates.

**Fix Required:**
1. Build a 3–4 screen onboarding carousel shown before the auth screen for first-time users:
   - **Screen 1:** "Save recipes from anywhere" — explain the import feature
   - **Screen 2:** "Cook along with video sync" — highlight the cook-along feature
   - **Screen 3:** "Organize your kitchen" — show collections and meal planning
   - **Screen 4:** CTA to sign in with Apple + "Skip for now" option
2. Store `hasSeenOnboarding` in `UserDefaults` so returning users skip it.
3. Use the existing design system (Colors, Typography, Buttons) for consistency.
4. Support swipe navigation and an accessibility escape gesture.

**Estimated effort:** 4–6 hours

---

### H-02: Deep Link Shows Placeholder Text

| Field | Detail |
|-------|--------|
| **Impact** | Deep links from shared recipes or Universal Links render a broken UI |
| **Location** | `DeepLinkHandler.swift`, lines 198–200 |

**Description:**
When a user taps a deep link for a specific recipe (e.g., `cooksy://recipe/123`), the app navigates to `Text("Recipe: \(recipeId)")` — a bare text placeholder instead of the actual `RecipeDetailView`. This makes shared recipe links completely unusable. The entire deep linking infrastructure (URL scheme + Universal Links) is otherwise well-built, so this is a frustrating one-line fix that unlocks the whole feature.

**Fix Required:**
Replace the placeholder:
```swift
// DeepLinkHandler.swift, lines 198-200
// BEFORE:
// Text("Recipe: \(recipeId)")

// AFTER:
RecipeDetailView(viewModel: RecipeDetailViewModel(recipeId: recipeId))
```
Ensure the `RecipeDetailViewModel` initializer accepts a recipe ID and fetches the recipe from SwiftData/Supabase.

**Estimated effort:** 30 minutes

---

### H-03: No SKStoreReviewController Integration

| Field | Detail |
|-------|--------|
| **Impact** | Zero organic review velocity — critical for App Store ranking |
| **Location** | Missing entirely |

**Description:**
There is no mechanism to ask satisfied users for an App Store review. Reviews are a primary driver of App Store search ranking and download conversion. Without `SKStoreReviewController`, only frustrated users will proactively seek out the App Store to leave reviews (typically negative), creating a skewed rating profile.

**Fix Required:**
1. Request a review at a **positive moment** — after a user successfully saves their 3rd recipe or completes a cook-along session.
2. Use the existing design system for a soft prompt before calling `SKStoreReviewController`:
```swift
import StoreKit

func requestReviewIfAppropriate() {
    guard recipeSaveCount >= 3 else { return }
    guard let windowScene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
    SKStoreReviewController.requestReview(in: windowScene)
}
```
3. Respect Apple's limit of ~3 requests per year by tracking requests in `UserDefaults`.

**Estimated effort:** 1 hour

---

### H-04: No Share Sheet Implementation

| Field | Detail |
|-------|--------|
| **Impact** | No viral growth loop — users can't share recipes |
| **Location** | `RecipeDetailViewModel.showShareSheet` (property exists, no UI) |

**Description:**
`RecipeDetailViewModel` has a `showShareSheet` property, but there is no `UIActivityViewController` integration in the UI layer. Recipe sharing is one of the highest-virality actions for a cooking app — users naturally want to share recipes with family and friends. The missing share sheet blocks this entire growth channel.

**Fix Required:**
1. Present `UIActivityViewController` from the recipe detail view:
```swift
@MainActor
func presentShareSheet(for recipe: Recipe) {
    let items: [Any] = [
        "Check out this recipe on Cooksy: \(recipe.title)",
        URL(string: "https://cooksy.app/recipe/\(recipe.id)")!
    ]
    let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // Exclude irrelevant activities
    activityVC.excludedActivityTypes = [.assignToContact, .print]
    // Present from the top view controller
    UIApplication.shared.topViewController?.present(activityVC, animated: true)
}
```
2. Include the deep link URL so recipients can open the recipe directly in the app (fixes H-02 simultaneously).

**Estimated effort:** 1 hour

---

### H-05: No Network Reachability / Offline Handling

| Field | Detail |
|-------|--------|
| **Impact** | Users get no feedback when importing recipes offline — appears broken |
| **Location** | Recipe import flow |

**Description:**
The app has no network reachability detection. If a user attempts to import a recipe while offline (common in kitchens with spotty Wi-Fi), the operation hangs silently with no error message. The standard spinner provides no context about whether the app is working or failing.

**Fix Required:**
1. Integrate **NWPathMonitor** (from `Network` framework) to monitor connectivity:
```swift
import Network

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
}
```
2. Inject `NetworkMonitor` into the import flow. Show an offline banner when `isConnected == false`.
3. Queue recipe imports locally and retry when connectivity returns (can leverage SwiftData for the queue).

**Estimated effort:** 3–4 hours

---

### H-06: No Skeleton / Shimmer Loading States

| Field | Detail |
|-------|--------|
| **Impact** | Perceived slowness during recipe import; users may abandon |
| **Location** | Recipe import / list loading |

**Description:**
During recipe import, the only visual feedback is a standard spinner. Modern iOS apps use skeleton screens or shimmer effects to indicate content is loading, which feels faster and more polished than a spinner alone. A skeleton screen that mimics the final recipe card layout sets the right expectation and reduces perceived wait time.

**Fix Required:**
1. Create a `SkeletonCard` view in the design system that mirrors `RecipeCard` using gray placeholder rectangles.
2. Animate with a shimmer effect (linear gradient sweep) using `LinearGradient` + `mask` + `animation`.
3. Show `SkeletonCard` while `Recipe` data is loading; crossfade to the real card when data arrives.

**Estimated effort:** 2–3 hours

---

### H-07: TimestampExtractionService Has 2 TODOs — Cook-Along Feature Incomplete

| Field | Detail |
|-------|--------|
| **Impact** | Cook-along video sync won't work with real videos |
| **Location** | `TimestampExtractionService.swift` |

**Description:**
The cook-along feature — a major differentiator for Cooksy — has two TODOs in `TimestampExtractionService`:
- Audio extraction from video is mocked
- Whisper transcription for generating step timestamps is not implemented

Without these, the cook-along mode will not generate accurate step-to-timestamp mappings for real user-imported videos. The feature works with pre-seeded demo data but fails for actual usage.

**Fix Required:**
1. **Audio Extraction:** Use `AVAssetReader` to extract audio tracks from imported video URLs:
```swift
let asset = AVAsset(url: videoURL)
let reader = try AVAssetReader(asset: audioAsset)
// Extract to PCM buffer for transcription
```
2. **Whisper Transcription:** Options:
   - **OpenAI Whisper API** (cloud, ~$0.006/minute) — fastest to implement
   - **WhisperKit** (on-device, Apple Silicon optimized) — no network required, privacy-preserving
   - **Custom server** (self-hosted Whisper) — most control, highest maintenance
3. Parse transcript timestamps and map them to recipe steps (likely requires NLP matching of transcript text to step descriptions).

**Estimated effort:** 1–2 weeks (depending on chosen approach)

---

## 4. Medium Priority Issues (Nice-to-Have Polish)

> **Post-launch roadmap items that would meaningfully differentiate Cooksy from competitors. Not required for v1.0.**

| # | Issue | Impact | Category |
|---|-------|--------|----------|
| M-01 | No iOS Widget extension | Reduced daily engagement | Engagement |
| M-02 | No Live Activities | Cooking timer not visible on Lock Screen | iOS 16+ Feature |
| M-03 | No Siri Shortcuts | No hands-free cooking triggers | Accessibility / Voice |
| M-04 | No Spotlight search integration | Recipes not discoverable from home screen | Discoverability |
| M-05 | No iCloud backup for SwiftData | User data loss on reinstall | Data Persistence |
| M-06 | No CoreHaptics rich patterns | Haptics feel generic | Polish |
| M-07 | No rate limiting on recipe imports | Backend abuse risk | Backend Resilience |

### M-01: No iOS Widget Extension

**Description:** A Home Screen widget showing "What's cooking today?" with the user's saved recipes or recommended recipes would increase daily active users by providing a reason to open the app every time the user unlocks their phone.

**Recommendation:** Build a **small widget** (2x2) and **medium widget** (2x4) using WidgetKit. Show the next recipe in the user's cooking queue or a featured recipe of the day. Use the design system colors for consistency. Use `AppIntent` for the tap-to-open action.

**Estimated effort:** 6–8 hours

---

### M-02: No Live Activities

**Description:** The cook-along feature is a perfect use case for iOS 16+ Live Activities. A persistent Lock Screen / Dynamic Island widget showing the current recipe step, timer, and next step would be transformative for the cooking experience. Users wouldn't need to keep the app foregrounded while cooking.

**Recommendation:** Implement a Live Activity that:
- Shows current step number and description
- Displays a countdown timer for the current step
- Provides "Next Step" and "Previous Step" buttons
- Uses the app's cream/brand colors

**Estimated effort:** 8–12 hours

---

### M-03: No Siri Shortcuts

**Description:** "Hey Siri, start cooking my pasta recipe" would be a killer differentiator. Hands-free cooking is a natural fit — users have messy hands in the kitchen and can't tap their phone.

**Recommendation:** Use `AppIntents` framework to expose shortcuts for:
- "Start cooking [recipe name]"
- "Next step"
- "Set a timer for [duration]"
- "Add [item] to my shopping list"

**Estimated effort:** 6–8 hours

---

### M-04: No Spotlight Search Integration

**Description:** Users cannot find their saved recipes by searching from the iOS home screen. This is expected behavior for apps that store user content (see Mail, Notes, Photos).

**Recommendation:** Index all recipes using `CoreSpotlight`. Include recipe title, ingredients, and tags as searchable attributes. Use `CSSearchableItemAttributeSet` with the recipe's thumbnail image.

**Estimated effort:** 3–4 hours

---

### M-05: No iCloud Backup for SwiftData Store

**Description:** The SwiftData store is local-only. If a user deletes and reinstalls Cooksy, all saved recipes, collections, and cooking history are permanently lost. This is a significant user trust issue.

**Recommendation:** Enable iCloud sync for SwiftData by adding the `CloudKit` container identifier to the app's entitlements and configuring the SwiftData model container with `.cloudKit`:
```swift
let container = try ModelContainer(
    for: Recipe.self, Collection.self,
    configurations: ModelConfiguration(cloudKitDatabase: .automatic)
)
```

**Estimated effort:** 4–6 hours (plus Apple Developer Portal CloudKit container setup)

---

### M-06: No CoreHaptics Rich Patterns

**Description:** The app uses standard `UIImpactFeedbackGenerator` (light/medium/heavy/selection). While functional, rich custom haptic patterns via `CoreHaptics` would elevate the cooking experience — a subtle pulse when a timer completes, a rising intensity pattern during step transitions, or a celebration buzz when a recipe is finished.

**Recommendation:** Create a `CoreHapticsEngine` service that plays `CHHapticPattern` events for:
- Timer completion (strong pulse + decay)
- Step transition (gentle rising ramp)
- Recipe complete (celebration pattern)

**Estimated effort:** 3–4 hours

---

### M-07: No Rate Limiting on Recipe Imports

**Description:** A user (or bot) could hammer the backend by repeatedly tapping "Save Recipe." This could exhaust Supabase quota, trigger rate limit errors, or inflate costs.

**Recommendation:**
1. Client-side: Disable the save button for 2 seconds after tap; show a brief "Saving..." state.
2. Server-side: Implement rate limiting on the Supabase edge function that handles recipe imports (e.g., 10 imports per user per hour).
3. Show a user-friendly message if the rate limit is exceeded: "You've been saving a lot of recipes! Take a moment to enjoy them."

**Estimated effort:** 2–3 hours

---

## 5. Low Priority Issues (Future Enhancements)

> **Items to consider for v1.1+ or as long-term differentiators. Not required for initial launch.**

| # | Issue | Impact | Notes |
|---|-------|--------|-------|
| L-01 | No dark mode support | Modern app expectation | `Info.plist` forces Light mode. Supporting dark mode requires auditing all custom colors and updating the design system. |
| L-02 | No iPad multitasking | iPad users get iPhone-scaled app | Currently only portrait orientation is supported. iPad users expect Split View and Slide Over. |
| L-03 | No AirPlay support for cook-along videos | Kitchen TV use case | Users with Apple TV or AirPlay-enabled TVs can't cast cook-along videos to a larger screen. |
| L-04 | No accessibility rotor support for recipe steps | VoiceOver UX gap | VoiceOver users can't quickly jump between recipe steps using the rotor gesture. |

### Notes on Low-Priority Items

- **Dark mode (L-01):** The design system's `CooksyBackground` color (cream) does not have a dark variant. Before enabling dark mode, every color, image, and shadow in the design system must be audited for dark mode compatibility. This is a non-trivial effort that is best deferred to a dedicated polish sprint.

- **iPad multitasking (L-02):** Supporting iPad multitasking requires declaring `UIRequiresFullScreen = NO` and testing all view layouts in Split View configurations. Given Cooksy's portrait-optimized layout, this may require significant UI refactoring.

- **AirPlay (L-03):** This is a genuinely useful feature for a cooking app (kitchen TV setup). Implementation via `AVRoutePickerView` is straightforward but requires testing with real AirPlay hardware.

- **Accessibility rotor (L-04):** Implementing a custom rotor for recipe steps is relatively simple using `UIAccessibilityCustomRotor` and would meaningfully improve the cooking experience for VoiceOver users.

---

## 6. App Store Submission Checklist

| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | App Icon (all sizes: 20pt–1024pt) | **COMPLETE** | `AppIcon.appiconset` fully populated |
| 2 | Launch Screen | **COMPLETE** | `CooksyLogoLaunch.imageset` + `Info.plist` configured |
| 3 | Privacy Manifest (`PrivacyInfo.xcprivacy`) | **COMPLETE** | Email, userID, `UserDefaults` declared |
| 4 | `Info.plist` (complete) | **COMPLETE** | URL scheme, push notifications, launch screen all present |
| 5 | URL Scheme (`cooksy://`) | **COMPLETE** | Deep linking service fully functional |
| 6 | Sign In with Apple | **PARTIAL** | Code complete; **missing `.entitlements` file** (see C-01) |
| 7 | App Tracking Transparency description | **MISSING** | Add `NSUserTrackingUsageDescription` to `Info.plist` (see C-04) |
| 8 | App Store Screenshots (5.5" + 6.5") | **MISSING** | Need iPhone 8 Plus (5.5") and iPhone 15 Pro Max (6.5") screenshots |
| 9 | App Store Description | **MISSING** | Write compelling description with feature highlights |
| 10 | Keywords | **MISSING** | Research and optimize for recipe/cooking keywords |
| 11 | Support URL | **MISSING** | Required by Apple — can be a simple landing page |
| 12 | Marketing URL | **MISSING** | Optional but recommended |
| 13 | App Preview Video | **MISSING** | Optional but strongly recommended for cooking apps |

### Checklist Summary

- **Complete:** 6 / 13 items
- **Partial:** 1 / 13 items
- **Missing:** 6 / 13 items
- **Overall completion:** ~50%

### App Store Screenshots Needed

| Device Size | Dimensions | Purpose |
|-------------|------------|---------|
| 6.7" (iPhone 15 Pro Max) | 1290 x 2796 | Primary — shown first in search |
| 6.5" (iPhone 14 Pro Max) | 1284 x 2778 | Secondary |
| 5.5" (iPhone 8 Plus) | 1242 x 2208 | Required for iPhone compatibility |

**Recommended screenshot sequence:**
1. Home screen with recipe collection
2. Recipe detail with ingredients
3. Cook-along mode with video sync
4. Recipe import from URL
5. Subscription / premium features

---

## 7. Recommended Priority Order for Fixes

### Phase 1: Blockers (Complete Before Submission)

> **Target: 1–2 days**

| Order | Issue | ID | Effort |
|-------|-------|-----|--------|
| 1 | Add `.entitlements` file for Sign In with Apple | C-01 | 15 min |
| 2 | Remove MockSupabaseService fallback | C-02 | 1 hr |
| 3 | Integrate production analytics provider | C-03 | 2–4 hrs |
| 4 | Add ATT description to `Info.plist` | C-04 | 10 min |
| 5 | Fix deep link placeholder → `RecipeDetailView` | H-02 | 30 min |
| 6 | Implement share sheet (`UIActivityViewController`) | H-04 | 1 hr |

**Phase 1 total:** ~1 day

### Phase 2: Launch Readiness (Complete Before Public Launch)

> **Target: 1 sprint (1–2 weeks)**

| Order | Issue | ID | Effort |
|-------|-------|-----|--------|
| 7 | Build onboarding flow | H-01 | 4–6 hrs |
| 8 | Add `SKStoreReviewController` | H-03 | 1 hr |
| 9 | Add network reachability + offline handling | H-05 | 3–4 hrs |
| 10 | Add skeleton/shimmer loading states | H-06 | 2–3 hrs |
| 11 | Create App Store screenshots (5.5" + 6.5") | — | 2–3 hrs |
| 12 | Write App Store description + keywords | — | 2–3 hrs |
| 13 | Create support URL landing page | — | 2–3 hrs |

**Phase 2 total:** ~1–2 weeks

### Phase 3: Post-Launch Roadmap (First 60 Days)

> **Target: 2–3 sprints**

| Order | Issue | ID | Effort |
|-------|-------|-----|--------|
| 14 | Implement `TimestampExtractionService` (Whisper) | H-07 | 1–2 weeks |
| 15 | Build iOS Widget extension | M-01 | 6–8 hrs |
| 16 | Build Live Activity for cook-along | M-02 | 8–12 hrs |
| 17 | Enable iCloud backup for SwiftData | M-05 | 4–6 hrs |
| 18 | Add Siri Shortcuts | M-03 | 6–8 hrs |
| 19 | Integrate CoreSpotlight search | M-04 | 3–4 hrs |

**Phase 3 total:** ~4–6 weeks

### Phase 4: Differentiation Polish (90+ Days)

| Order | Issue | ID | Effort |
|-------|-------|-----|--------|
| 20 | Dark mode support | L-01 | 1 week |
| 21 | iPad multitasking support | L-02 | 1 week |
| 22 | AirPlay support for videos | L-03 | 4–6 hrs |
| 23 | Rich CoreHaptics patterns | M-06 | 3–4 hrs |
| 24 | Accessibility rotor for recipe steps | L-04 | 2–3 hrs |
| 25 | Rate limiting on imports | M-07 | 2–3 hrs |
| 26 | App Preview Video | — | 1 day |

---

## Appendix A: Codebase Health Assessment

| Category | Assessment | Notes |
|----------|------------|-------|
| Architecture | **Excellent** | Clean MVVM, proper use of `@Observable`, well-separated concerns |
| Persistence | **Excellent** | SwiftData with `@Model`, `@Relationship`, proper migration handling |
| Accessibility | **Very Good** | VoiceOver labels, Dynamic Type, Reduce Motion support |
| Design System | **Very Good** | Colors, Typography, Cards, Buttons all centralized |
| Error Handling | **Good** | `CooksyError` enum with `LocalizedError`, could use more user-facing recovery |
| Testing | **Unknown** | Not assessed in this audit — recommend adding unit tests for ViewModels |
| Documentation | **Fair** | TODO comments indicate areas needing attention |
| Dependencies | **Good** | RevenueCat and Supabase are well-established, actively maintained |

## Appendix B: Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| App Store rejection (missing entitlements) | **High** | **Critical** | Fix C-01 immediately |
| App ships with fake data | **Medium** | **Critical** | Fix C-02 before any CI/CD pipeline |
| Zero analytics in production | **High** | **High** | Fix C-03 before launch |
| Cook-along feature doesn't work for real videos | **High** | **High** | Plan H-07 for Phase 3 |
| Poor first-time conversion | **High** | **High** | Fix H-01 in Phase 2 |
| Negative reviews due to no review prompt | **High** | **Medium** | Fix H-03 in Phase 2 |
| User data loss on reinstall | **Medium** | **Medium** | Fix M-05 in Phase 3 |

---

*This audit was conducted against the Cooksy iOS codebase. All findings are based on static code analysis. Recommendations should be validated with functional testing on physical devices before App Store submission.*
