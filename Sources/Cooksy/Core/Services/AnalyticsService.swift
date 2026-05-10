import Foundation

/// Lightweight analytics service for tracking user events.
///
/// In DEBUG: prints events to console.
/// In RELEASE: buffers events to UserDefaults for later flushing when a real provider is wired.
///
/// To wire a real provider (e.g., Firebase, Mixpanel, PostHog):
/// 1. Add the provider SDK via SPM
/// 2. Replace the body of `flush()` with your provider's track call
/// 3. Call `flush()` on app launch (after provider init)
@Observable
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private let bufferKey = "analytics_event_buffer"
    private let maxBufferSize = 100

    /// Track a named event with optional string properties.
    func track(_ event: String, properties: [String: String] = [:]) {
        #if DEBUG
        print("[Analytics] \(event): \(properties)")
        #endif
        bufferEvent(name: event, properties: properties)
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

    /// Flushes buffered events. Call this after wiring a real analytics provider.
    /// Returns the number of events flushed.
    @discardableResult
    func flush() -> Int {
        let events = loadBuffer()
        guard !events.isEmpty else { return 0 }

        #if DEBUG
        print("[Analytics] Flushing \(events.count) buffered events")
        for event in events {
            print("[Analytics] Flush: \(event.name): \(event.properties)")
        }
        #endif

        clearBuffer()
        return events.count
    }

    // MARK: - Private

    private struct BufferedEvent: Codable {
        let name: String
        let properties: [String: String]
        let timestamp: Date
    }

    private func bufferEvent(name: String, properties: [String: String]) {
        var buffer = loadBuffer()
        buffer.append(BufferedEvent(name: name, properties: properties, timestamp: Date()))

        // Keep only the most recent maxBufferSize events
        if buffer.count > maxBufferSize {
            buffer = Array(buffer.suffix(maxBufferSize))
        }

        saveBuffer(buffer)
    }

    private func loadBuffer() -> [BufferedEvent] {
        guard let data = UserDefaults.standard.data(forKey: bufferKey),
              let events = try? JSONDecoder().decode([BufferedEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func saveBuffer(_ events: [BufferedEvent]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: bufferKey)
    }

    private func clearBuffer() {
        UserDefaults.standard.removeObject(forKey: bufferKey)
    }
}
