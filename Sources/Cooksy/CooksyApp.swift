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

    /// Production Supabase anon key — provided by the project owner.
    ///
    /// SECURITY NOTE: This is the public anon key (not the service_role key).
    /// It is safe to embed in the client as it has limited permissions.
    /// For production builds, override via SUPABASE_ANON_KEY environment variable.
    private static let defaultSupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpcmpqYm1yZ3RhaWxpZmhtYWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyODk1ODgsImV4cCI6MjA5MDg2NTU4OH0.F2uXHw6STtQojZKpSPcKFV_5C31NBJy3E3XqgFRUj1o"

    init() {
        // Apply runtime security protections FIRST, before any other initialization.
        // This includes: anti-debugging (ptrace PT_DENY_ATTACH), code injection
        // detection, method swizzling detection, and periodic debugger checks.
        RuntimeProtection.applyAll()

        // Use environment variable if available (for CI/development flexibility),
        // otherwise fall back to the production URL.
        let supabaseUrl = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? Self.defaultSupabaseUrl
        // Use environment variable if available, otherwise fall back to the default key.
        let supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? Self.defaultSupabaseAnonKey
        supabaseService = SupabaseService(url: supabaseUrl, key: supabaseKey)

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
