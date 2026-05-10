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

    /// Production Supabase URL — less sensitive than keys but kept minimal.
    private static let defaultSupabaseUrl = "https://qirjjbmrgtailifhmakp.supabase.co"

    init() {
        // Apply runtime security protections FIRST, before any other initialization.
        RuntimeProtection.applyAll()

        // URL uses env var or default. The anon key is reconstructed from
        // XOR-obfuscated fragments — it never appears as a plain string in the binary.
        let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Self.defaultSupabaseUrl

        var supabaseKey = ""
        ObfuscatedKeys.withKeyString(.supabaseAnon) { key in
            supabaseKey = key
        }
        supabaseService = SupabaseService(url: supabaseUrl, key: supabaseKey)
        supabaseKey = String(repeating: "\0", count: supabaseKey.count)

        // Configure RevenueCat for subscriptions
        configureRevenueCat()

        // Register notification categories and inject dependencies
        PushNotificationService.shared.registerNotificationCategories()
        PushNotificationService.shared.configure(supabase: supabaseService)

        // SECURITY: Clear sensitive in-memory data on memory warning
        // This reduces the attack surface by purging cached responses
        // that may contain sensitive recipe data or auth tokens.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Clear URL cache to remove potentially sensitive cached responses
            URLCache.shared.removeAllCachedResponses()
        }
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
    /// Configures RevenueCat with the obfuscated API key.
    /// The key is reconstructed at runtime from XOR-obfuscated fragments.
    ///
    /// Products configured in the RevenueCat dashboard:
    /// - `monthly` — Monthly recurring subscription
    /// - `yearly` — Annual recurring subscription (best value)
    /// - `lifetime` — One-time purchase, permanent access
    ///
    /// Entitlement: `cooksy_pro` — Grants access to all premium features.
    private func configureRevenueCat() {
        var rcKey = ""
        ObfuscatedKeys.withKeyString(.revenueCat) { key in
            rcKey = key
        }
        Purchases.configure(
            with: Configuration.builder(withAPIKey: rcKey)
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
        #if DEBUG
        print("[CooksyAppDelegate] Failed to register for push notifications: \(error.localizedDescription)")
        #endif
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
