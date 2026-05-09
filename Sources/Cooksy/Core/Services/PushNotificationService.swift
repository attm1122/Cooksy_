import Foundation
import UserNotifications
import UIKit

// MARK: - Push Notification Service
/// Manages push notification permissions, device token registration,
/// and handling incoming notifications including deep linking to recipes.
@Observable
@MainActor
final class PushNotificationService: NSObject {
    
    // MARK: - Singleton
    
    static let shared = PushNotificationService()
    
    // MARK: - Published State
    
    /// Whether the user has granted push notification permission
    private(set) var isAuthorized = false
    
    /// The device token for push notifications (nil until registered)
    private(set) var deviceToken: String?
    
    /// The pending deep link URL from a notification tap
    var pendingDeepLink: URL?
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission Request
    
    /// Requests push notification authorization from the user.
    /// Should be called after the user has experienced value in the app
    /// (e.g., after their first recipe import).
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            isAuthorized = granted
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("[PushNotificationService] Failed to request authorization: \(error.localizedDescription)")
            isAuthorized = false
            return false
        }
    }
    
    /// Checks the current authorization status without prompting the user.
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = (settings.authorizationStatus == .authorized)
    }
    
    // MARK: - Device Token

    /// The Supabase service for push token registration. Injected from `CooksyApp`.
    private var supabase: (any SupabaseProtocol)?

    /// Injects the Supabase service dependency.
    /// - Parameter supabase: The Supabase service (real or mock).
    func configure(supabase: any SupabaseProtocol) {
        self.supabase = supabase
    }

    /// Registers the device token with Supabase for server-side push delivery.
    /// - Parameter tokenData: The raw device token data from UIApplicationDelegate
    func registerDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token

        // Register with Supabase
        Task {
            do {
                try await supabase?.registerPushToken(token)
                print("[PushNotificationService] Device token registered successfully")
            } catch {
                print("[PushNotificationService] Failed to register token: \(error.localizedDescription)")
            }
        }
    }

    /// Clears the device token when the user signs out.
    func clearDeviceToken() {
        guard let token = deviceToken else { return }
        deviceToken = nil

        Task {
            do {
                try await supabase?.unregisterPushToken(token)
            } catch {
                print("[PushNotificationService] Failed to unregister token: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Local Notifications
    
    /// Schedules a local notification for when a recipe import is complete.
    /// - Parameters:
    ///   - recipeId: The ID of the completed recipe
    ///   - recipeTitle: The title of the recipe for the notification body
    func scheduleImportCompleteNotification(recipeId: String, recipeTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "Recipe Ready!"
        content.body = "\"\(recipeTitle)\" has been imported and is ready to cook."
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "import_complete",
            "recipeId": recipeId,
            "deepLink": "cooksy://recipe/\(recipeId)"
        ]
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "import-\(recipeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error {
                print("[PushNotificationService] Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancels a pending import notification (e.g., if user opens the app before it fires).
    /// - Parameter recipeId: The recipe ID used in the notification identifier
    func cancelImportNotification(recipeId: String) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["import-\(recipeId)"]
        )
    }
    
    /// Clears the app badge count.
    func clearBadge() {
        notificationCenter.setBadgeCount(0)
    }
    
    // MARK: - Notification Categories
    
    /// Registers custom notification categories with action buttons.
    func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_RECIPE",
            title: "View Recipe",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )
        
        let importCategory = UNNotificationCategory(
            identifier: "IMPORT_COMPLETE",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([importCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is delivered while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when the user taps on a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract deep link from notification payload
        if let deepLinkString = userInfo["deepLink"] as? String,
           let url = URL(string: deepLinkString) {
            pendingDeepLink = url
            
            // Post a notification that the app can observe to handle navigation
            NotificationCenter.default.post(
                name: .didReceiveDeepLink,
                object: nil,
                userInfo: ["url": url]
            )
        }
        
        // Clear badge when user interacts with a notification
        clearBadge()
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a deep link is received from a push notification
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}
