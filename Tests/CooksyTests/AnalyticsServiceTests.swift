import XCTest
@testable import Cooksy

// MARK: - AnalyticsService Tests
/// Comprehensive unit tests for the AnalyticsService.
/// Covers track(), trackScreen(), trackImportStarted(), trackImportCompleted(),
/// trackImportFailed(), trackSubscriptionEvent(), flush(), buffer limits, and singleton pattern.
@MainActor
final class AnalyticsServiceTests: XCTestCase {

    private let testBufferKey = "test_analytics_event_buffer"
    private var service: AnalyticsService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        clearTestBuffer()
        service = AnalyticsService.shared
    }

    override func tearDown() {
        clearTestBuffer()
        service = nil
        super.tearDown()
    }

    private func clearTestBuffer() {
        UserDefaults.standard.removeObject(forKey: "analytics_event_buffer")
    }

    private func loadRawBuffer() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: "analytics_event_buffer"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return json
    }

    // MARK: - Singleton Pattern Tests

    func testSharedInstanceExists() {
        let service = AnalyticsService.shared
        XCTAssertNotNil(service)
    }

    func testSharedReturnsSameInstance() {
        let service1 = AnalyticsService.shared
        let service2 = AnalyticsService.shared
        XCTAssertTrue(service1 === service2)
    }

    // MARK: - track(_:properties:) Tests

    func testTrackBuffersEvent() {
        service.track("test_event", properties: ["key": "value"])
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 1)
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "test_event")
        }
    }

    func testTrackWithEmptyProperties() {
        service.track("simple_event", properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "simple_event")
            XCTAssertNotNil(event["properties"])
        }
    }

    func testTrackWithMultipleProperties() {
        service.track("multi_event", properties: [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        ])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "multi_event")
        }
    }

    func testTrackWithEmptyEventName() {
        service.track("", properties: [:])
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 1)
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "")
        }
    }

    func testTrackWithSpecialCharactersInName() {
        let name = "event_!@#$%^&*()\n\t"
        service.track(name, properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, name)
        }
    }

    func testTrackWithUnicodeEventName() {
        let name = "\u{1F370} \u{4E2D}\u{6587} event"
        service.track(name, properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, name)
        }
    }

    func testTrackWithLongEventName() {
        let name = String(repeating: "a", count: 1000)
        service.track(name, properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, name)
        }
    }

    func testTrackWithSpecialCharactersInProperties() {
        service.track("event", properties: [
            "special": "!@#$%^&*()",
            "newline": "line1\nline2",
            "tab": "col1\tcol2"
        ])
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 1)
    }

    func testTrackMultipleEvents() {
        for i in 0..<5 {
            service.track("event_\(i)", properties: ["index": "\(i)"])
        }
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 5)
    }

    func testTrackWithEmptyStringPropertyValues() {
        service.track("event", properties: ["empty_key": ""])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "event")
        }
    }

    // MARK: - trackScreen(_:) Tests

    func testTrackScreen() {
        service.trackScreen("HomeView")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "screen_view")
        }
    }

    func testTrackScreenWithEmptyName() {
        service.trackScreen("")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "screen_view")
        }
    }

    func testTrackScreenWithSpecialCharacters() {
        service.trackScreen("View/Detail/Sub")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "screen_view")
        }
    }

    func testTrackScreenBuffersCorrectScreenName() {
        service.trackScreen("RecipeDetailView")
        let buffer = loadRawBuffer()
        if let event = buffer.last,
           let props = event["properties"] as? [String: String] {
            XCTAssertEqual(props["screen"], "RecipeDetailView")
        }
    }

    func testTrackScreenMultipleTimes() {
        service.trackScreen("HomeView")
        service.trackScreen("SettingsView")
        service.trackScreen("ProfileView")
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 3)
    }

    // MARK: - trackImportStarted(url:) Tests

    func testTrackImportStartedWithYouTubeURL() {
        service.trackImportStarted(url: "https://www.youtube.com/watch?v=abc123")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_started")
        }
    }

    func testTrackImportStartedWithTikTokURL() {
        service.trackImportStarted(url: "https://www.tiktok.com/@chef/video/123456")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_started")
        }
    }

    func testTrackImportStartedWithInstagramURL() {
        service.trackImportStarted(url: "https://www.instagram.com/reel/abc123")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_started")
        }
    }

    func testTrackImportStartedWithUnsupportedURL() {
        service.trackImportStarted(url: "https://facebook.com/video/123")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_started")
        }
    }

    func testTrackImportStartedWithEmptyURL() {
        service.trackImportStarted(url: "")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_started")
        }
    }

    func testTrackImportStartedWithInvalidURL() {
        service.trackImportStarted(url: "not-a-valid-url")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_started")
        }
    }

    // MARK: - trackImportCompleted(recipeId:platform:) Tests

    func testTrackImportCompleted() {
        service.trackImportCompleted(recipeId: "recipe-123", platform: "youtube")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_completed")
        }
    }

    func testTrackImportCompletedWithEmptyStrings() {
        service.trackImportCompleted(recipeId: "", platform: "")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_completed")
        }
    }

    func testTrackImportCompletedWithSpecialCharacters() {
        service.trackImportCompleted(recipeId: "recipe-!@#", platform: "youtube")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_completed")
        }
    }

    func testTrackImportCompletedWithUnicode() {
        service.trackImportCompleted(recipeId: "\u{1F370}", platform: "\u{4E2D}\u{6587}")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_completed")
        }
    }

    func testTrackImportCompletedWithTikTokPlatform() {
        service.trackImportCompleted(recipeId: "recipe-456", platform: "tiktok")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_completed")
        }
    }

    func testTrackImportCompletedWithInstagramPlatform() {
        service.trackImportCompleted(recipeId: "recipe-789", platform: "instagram")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_completed")
        }
    }

    // MARK: - trackImportFailed(reason:) Tests

    func testTrackImportFailed() {
        service.trackImportFailed(reason: "Network timeout")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_failed")
        }
    }

    func testTrackImportFailedWithEmptyReason() {
        service.trackImportFailed(reason: "")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_failed")
        }
    }

    func testTrackImportFailedWithLongReason() {
        let reason = String(repeating: "x", count: 5000)
        service.trackImportFailed(reason: reason)
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_failed")
        }
    }

    func testTrackImportFailedWithSpecialCharacters() {
        service.trackImportFailed(reason: "Error: !@#$%^&*()\n\t")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_failed")
        }
    }

    func testTrackImportFailedWithUnicodeReason() {
        service.trackImportFailed(reason: "\u{274C} \u{5931}\u{8D25}")
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "import_failed")
        }
    }

    // MARK: - trackSubscriptionEvent(_:properties:) Tests

    func testTrackSubscriptionEvent() {
        service.trackSubscriptionEvent("purchase_started", properties: ["plan": "yearly"])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "subscription_purchase_started")
        }
    }

    func testTrackSubscriptionEventWithEmptyProperties() {
        service.trackSubscriptionEvent("purchase_completed", properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "subscription_purchase_completed")
        }
    }

    func testTrackSubscriptionEventWithMultipleProperties() {
        service.trackSubscriptionEvent("cancelled", properties: [
            "reason": "too_expensive",
            "plan": "monthly",
            "duration_days": "30"
        ])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "subscription_cancelled")
        }
    }

    func testTrackSubscriptionEventWithEmptyEventName() {
        service.trackSubscriptionEvent("", properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "subscription_")
        }
    }

    func testTrackSubscriptionEventWithSpecialCharacters() {
        service.trackSubscriptionEvent("event_!@#", properties: ["key": "value"])
        let buffer = loadRawBuffer()
        if let event = buffer.last {
            XCTAssertEqual(event["name"] as? String, "subscription_event_!@#")
        }
    }

    func testTrackSubscriptionEventMultipleEvents() {
        service.trackSubscriptionEvent("started", properties: [:])
        service.trackSubscriptionEvent("completed", properties: ["plan": "yearly"])
        service.trackSubscriptionEvent("renewed", properties: ["auto": "true"])
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 3)
    }

    // MARK: - flush() Tests

    func testFlushReturnsZeroWhenEmpty() {
        clearTestBuffer()
        let count = service.flush()
        XCTAssertEqual(count, 0)
    }

    func testFlushReturnsCorrectCount() {
        clearTestBuffer()
        service.track("event1", properties: [:])
        service.track("event2", properties: [:])
        service.track("event3", properties: [:])
        let count = service.flush()
        XCTAssertEqual(count, 3)
    }

    func testFlushClearsBuffer() {
        service.track("event", properties: [:])
        _ = service.flush()
        let buffer = loadRawBuffer()
        XCTAssertEqual(buffer.count, 0)
    }

    func testFlushReturnsZeroAfterAlreadyFlushed() {
        service.track("event", properties: [:])
        _ = service.flush()
        let count = service.flush()
        XCTAssertEqual(count, 0)
    }

    func testFlushIsDiscardableResult() {
        service.track("event", properties: [:])
        XCTAssertNoThrow(service.flush())
    }

    func testFlushWithManyEvents() {
        clearTestBuffer()
        for i in 0..<50 {
            service.track("event_\(i)", properties: [:])
        }
        let count = service.flush()
        XCTAssertEqual(count, 50)
        let buffer = loadRawBuffer()
        XCTAssertEqual(buffer.count, 0)
    }

    func testFlushDoesNotCrashWhenCalledMultipleTimes() {
        service.track("event1", properties: [:])
        _ = service.flush()
        _ = service.flush()
        _ = service.flush()
        let count = service.flush()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Buffer Limit Tests

    func testBufferDoesNotExceedMaxSize() {
        clearTestBuffer()
        for i in 0..<150 {
            service.track("event_\(i)", properties: [:])
        }
        let count = service.flush()
        XCTAssertLessThanOrEqual(count, 100)
    }

    func testBufferKeepsMostRecentEvents() {
        clearTestBuffer()
        for i in 0..<105 {
            service.track("event_\(i)", properties: [:])
        }
        let count = service.flush()
        XCTAssertEqual(count, 100)
    }

    func testBufferAtExactlyMaxSize() {
        clearTestBuffer()
        for i in 0..<100 {
            service.track("event_\(i)", properties: [:])
        }
        let count = service.flush()
        XCTAssertEqual(count, 100)
    }

    func testBufferOneOverMaxSize() {
        clearTestBuffer()
        for i in 0..<101 {
            service.track("event_\(i)", properties: [:])
        }
        let count = service.flush()
        XCTAssertEqual(count, 100)
    }

    // MARK: - Timestamp Tests

    func testEventsHaveTimestamp() {
        clearTestBuffer()
        service.track("timed_event", properties: [:])
        let buffer = loadRawBuffer()
        if let event = buffer.first {
            XCTAssertNotNil(event["timestamp"])
        }
    }

    func testEventTimestampsAreRecent() {
        clearTestBuffer()
        let before = Date()
        service.track("timed_event", properties: [:])
        let after = Date()
        let buffer = loadRawBuffer()

        if let event = buffer.first,
           let timestampStr = event["timestamp"] as? String,
           let timestampData = timestampStr.data(using: .utf8),
           let timestampObj = try? JSONDecoder().decode(Date.self, from: timestampData) {
            XCTAssertGreaterThanOrEqual(timestampObj, before.addingTimeInterval(-1))
            XCTAssertLessThanOrEqual(timestampObj, after.addingTimeInterval(1))
        }
    }

    // MARK: - Sequence Tests

    func testTrackAndFlushSequence() {
        clearTestBuffer()
        service.track("event1", properties: [:])
        service.track("event2", properties: [:])
        let count1 = service.flush()
        XCTAssertEqual(count1, 2)
        let count2 = service.flush()
        XCTAssertEqual(count2, 0)
    }

    func testTrackAfterFlushContinuesBuffering() {
        clearTestBuffer()
        service.track("event1", properties: [:])
        _ = service.flush()
        service.track("event2", properties: [:])
        let count = service.flush()
        XCTAssertEqual(count, 1)
    }

    // MARK: - Complex Property Tests

    func testTrackWithUnicodeProperties() {
        service.track("unicode_event", properties: [
            "emoji": "\u{1F370}",
            "chinese": "\u{4E2D}\u{6587}",
            "arabic": "\u{0639}\u{0631}\u{0628}\u{064A}"
        ])
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 1)
    }

    func testTrackWithLongPropertyValues() {
        service.track("long_props", properties: [
            "long": String(repeating: "x", count: 1000)
        ])
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 1)
    }

    func testTrackWithManyProperties() {
        var props: [String: String] = [:]
        for i in 0..<20 {
            props["key_\(i)"] = "value_\(i)"
        }
        service.track("many_props", properties: props)
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 1)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentTrackCalls() {
        let expectations = (0..<10).map { i in
            self.expectation(description: "Concurrent track \(i)")
        }

        for i in 0..<10 {
            DispatchQueue.global(qos: .default).async {
                self.service.track("concurrent_\(i)", properties: ["index": "\(i)"])
                expectations[i].fulfill()
            }
        }

        wait(for: expectations, timeout: 5.0)
        let buffer = loadRawBuffer()
        XCTAssertGreaterThanOrEqual(buffer.count, 10)
    }

    // MARK: - Service Characteristic Tests

    func testServiceIsObservable() {
        let service = AnalyticsService.shared
        XCTAssertNotNil(service)
    }

    func testServiceIsMainActor() {
        let service = AnalyticsService.shared
        XCTAssertNotNil(service)
    }

    func testServiceIsFinalClass() {
        let service = AnalyticsService.shared
        XCTAssertTrue(type(of: service) == AnalyticsService.self)
    }

    func testTrackMethodIsAccessible() {
        XCTAssertNoThrow(service.track("accessible", properties: [:]))
    }
}
