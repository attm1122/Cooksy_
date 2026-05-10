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
/// - `REVENUECAT_API_KEY` - Your RevenueCat public API key
@main
struct CooksyApp: App {

    // MARK: - Dependencies

    /// The Supabase service (or mock) that powers all backend operations.
    private let supabaseService: any SupabaseProtocol

    // MARK: - Initialization

    init() {
        let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""

        if supabaseUrl.isEmpty || supabaseKey.isEmpty {
            print("[Cooksy] ERROR: SUPABASE_URL and SUPABASE_ANON_KEY environment variables must be set. Set them in your Xcode scheme or CI environment.")
        }

        // Always use the real service. It will throw clear errors at runtime if misconfigured.
        // MockSupabaseService is available explicitly for previews and tests only.
        let resolvedUrl = supabaseUrl.isEmpty ? "https://placeholder.supabase.co" : supabaseUrl
        let resolvedKey = supabaseKey.isEmpty ? "placeholder-key" : supabaseKey
        supabaseService = SupabaseService(url: resolvedUrl, key: resolvedKey)

        // Configure RevenueCat
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

    private func configureRevenueCat() {
        // Load RevenueCat API key from environment
        let revenueCatKey = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] ?? ""

        if !revenueCatKey.isEmpty {
            Purchases.configure(withAPIKey: revenueCatKey)
        } else {
            // In development without a key, configure with empty key
            // RevenueCat will operate in a limited mode (no actual purchases)
            Purchases.configure(withAPIKey: "appl_dev_placeholder_key")
        }

        // Optional: Set user ID if already authenticated
        if let userEmail = UserDefaults.standard.string(forKey: "userEmail") {
            Purchases.shared.logIn(userEmail) { _, _, _ in }
        }
    }
}

// MARK: - Environment Key

/// The `@Environment` key used to inject `SupabaseProtocol` throughout the view hierarchy.
private struct SupabaseKey: EnvironmentKey {
    static let defaultValue: any SupabaseProtocol = MockSupabaseService()
}

extension EnvironmentValues {
    /// The Supabase backend service (real or mock) for the current view hierarchy.
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
        // Handle silent push notifications for background processing
        if let deepLinkString = userInfo["deepLink"] as? String,
           let url = URL(string: deepLinkString) {
            DeepLinkService.shared.handle(url: url)
        }
        completionHandler(.noData)
    }
}
