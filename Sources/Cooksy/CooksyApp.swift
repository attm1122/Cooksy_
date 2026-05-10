import SwiftUI
import SwiftData
import RevenueCat

// MARK: - CooksyApp
/// The main app entry point for Cooksy.
///
/// Responsible for:
/// - Setting up RevenueCat for in-app purchases
/// - Configuring push notification handling
/// - Setting up deep linking
/// - Configuring the SwiftData model container
/// - Injecting dependencies into the view hierarchy via `@Environment`
///
/// ## Configuration
/// Set the required environment variables (via Xcode scheme settings or CI secrets):
/// - `SUPABASE_URL` - Your Supabase project URL
/// - `SUPABASE_ANON_KEY` - Your Supabase anon key
///
/// ## RevenueCat Setup
/// Products are configured in the RevenueCat dashboard:
/// - Offering: "default"
/// - Products: `monthly`, `yearly`, `lifetime`
/// - Entitlement: `cooksy_pro`
@main
struct CooksyApp: App {

    // MARK: - Dependencies

    /// The Supabase service that powers all backend operations.
    private let supabaseService: any SupabaseProtocol

    // MARK: - Initialization

    /// Production Supabase URL — provided by the project owner.
    private static let defaultSupabaseUrl = "https://qirjjbmrgtailifhmakp.supabase.co"

    init() {
        // Use environment variable if available (for CI/development flexibility),
        // otherwise fall back to the production URL.
        let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Self.defaultSupabaseUrl
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

        if supabaseKey.isEmpty {
            print("[Cooksy] WARNING: SUPABASE_ANON_KEY environment variable not set. Set it in your Xcode scheme (Run → Environment Variables) or CI environment. The Supabase URL is configured.")
        }

        // Always use the real service. It will throw clear errors at runtime if misconfigured.
        let resolvedKey = supabaseKey.isEmpty ? "placeholder-key" : supabaseKey
        supabaseService = SupabaseService(url: supabaseUrl, key: resolvedKey)

        // Configure RevenueCat for subscriptions
        configureRevenueCat()

        // Register notification categories and inject dependencies
        PushNotificationService.shared.registerNotificationCategories()
        PushNotificationService.shared.configure(supabase: supabaseService)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.supabase, supabaseService)
                .onOpenURL { url in
                    DeepLinkService.shared.handle(url: url)
                }
        }
        .modelContainer(for: [Recipe.self, RecipeStep.self, Ingredient.self, RecipeBook.self])
    }

    // MARK: - RevenueCat Configuration

    /// Configures the RevenueCat SDK with the Cooksy API key.
    ///
    /// Uses the public API key for the `test_dFOvkzkolHCcofaTGPtfkIGyWjL` project.
    /// In production, RevenueCat automatically switches to the production environment.
    ///
    /// Products configured in the RevenueCat dashboard:
    /// - `monthly` — Monthly recurring subscription
    /// - `yearly` — Annual recurring subscription (best value)
    /// - `lifetime` — One-time purchase, permanent access
    ///
    /// Entitlement: `cooksy_pro` — Grants access to all premium features.
    private func configureRevenueCat() {
        Purchases.configure(
            with: Configuration.builder(withAPIKey: "test_dFOvkzkolHCcofaTGPtfkIGyWjL")
                .with(appUserID: nil)
                .build()
        )

        // Sync user ID with RevenueCat after authentication
        NotificationCenter.default.addObserver(
            forName: .userDidAuthenticate,
            object: nil,
            queue: .main
        ) { notification in
            if let userId = notification.userInfo?["userId"] as? String {
                Purchases.shared.logIn(userId) { _, _, _ in }
            }
        }

        // Clear RevenueCat user ID on sign out
        NotificationCenter.default.addObserver(
            forName: .userDidSignOut,
            object: nil,
            queue: .main
        ) { _ in
            Purchases.shared.logOut { _, _ in }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the user successfully authenticates.
    static let userDidAuthenticate = Notification.Name("com.cooksy.userDidAuthenticate")
    /// Posted when the user signs out.
    static let userDidSignOut = Notification.Name("com.cooksy.userDidSignOut")
}

// MARK: - Environment Key

/// The `@Environment` key used to inject `SupabaseProtocol` throughout the view hierarchy.
private struct SupabaseKey: EnvironmentKey {
    static let defaultValue: any SupabaseProtocol = MockSupabaseService()
}

extension EnvironmentValues {
    /// The Supabase backend service for the current view hierarchy.
    var supabase: any SupabaseProtocol {
        get { self[SupabaseKey.self] }
        set { self[SupabaseKey.self] = newValue }
    }
}

// MARK: - UIApplicationDelegate for Push Notifications

/// Bridge for handling push notification delegate methods and device token registration.
class CooksyAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registerDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[CooksyAppDelegate] Failed to register for push notifications: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if let deepLinkString = userInfo["deepLink"] as? String,
           let url = URL(string: deepLinkString) {
            DeepLinkService.shared.handle(url: url)
        }
        completionHandler(.noData)
    }
}
