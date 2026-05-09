import Foundation

/// Lightweight analytics service for tracking user events.
/// Swallows events in release builds unless a real analytics provider (e.g., Mixpanel,
/// Amplitude, PostHog) is wired in.
@Observable
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    /// Track a named event with optional string properties.
    func track(_ event: String, properties: [String: String] = [:]) {
        #if DEBUG
        print("[Analytics] \(event): \(properties)")
        #endif
        // TODO: Wire to real analytics provider in production
    }

    /// Convenience for tracking screen views.
    func trackScreen(_ name: String) {
        track("screen_view", properties: ["screen": name])
    }

    /// Track recipe import events.
    func trackImportStarted(url: String) {
        let platform = Validators.platformForURL(url)?.rawValue ?? "unknown"
        track("import_started", properties: ["platform": platform])
    }

    func trackImportCompleted(recipeId: String, platform: String) {
        track("import_completed", properties: [
            "recipe_id": recipeId,
            "platform": platform
        ])
    }

    func trackImportFailed(reason: String) {
        track("import_failed", properties: ["reason": reason])
    }

    /// Track subscription events.
    func trackSubscriptionEvent(_ event: String, properties: [String: String] = [:]) {
        track("subscription_\(event)", properties: properties)
    }
}
