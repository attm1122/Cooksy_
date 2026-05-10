import XCTest
@testable import Cooksy

// MARK: - RecipeTimestamp Model Tests
/// Comprehensive unit tests for the RecipeTimestamp struct covering all stored properties,
/// the contains(_:) method, Codable encode/decode round-trips, Sendable conformance,
/// the duration computed property, and edge cases.
final class RecipeTimestampTests: XCTestCase {

    // MARK: - Factory Helpers

    private func makeTimestamp(
        id: String = "ts1",
        recipeStepId: String = "step1",
        stepIndex: Int = 0,
        startTime: TimeInterval = 30.0,
        endTime: TimeInterval = 120.0,
        triggerPhrase: String = "now add the garlic",
        confidence: Double = 0.94
    ) -> RecipeTimestamp {
        RecipeTimestamp(
            id: id,
            recipeStepId: recipeStepId,
            stepIndex: stepIndex,
            startTime: startTime,
            endTime: endTime,
            triggerPhrase: triggerPhrase,
            confidence: confidence
        )
    }

    // MARK: - Stored Property Tests

    func testId_IsStored() {
        let ts = makeTimestamp(id: "custom-id-123")

        XCTAssertEqual(ts.id, "custom-id-123")
    }

    func testRecipeStepId_IsStored() {
        let ts = makeTimestamp(recipeStepId: "step-42")

        XCTAssertEqual(ts.recipeStepId, "step-42")
    }

    func testStepIndex_IsStored() {
        let ts = makeTimestamp(stepIndex: 5)

        XCTAssertEqual(ts.stepIndex, 5)
    }

    func testStartTime_IsStored() {
        let ts = makeTimestamp(startTime: 45.5)

        XCTAssertEqual(ts.startTime, 45.5)
    }

    func testEndTime_IsStored() {
        let ts = makeTimestamp(endTime: 200.0)

        XCTAssertEqual(ts.endTime, 200.0)
    }

    func testTriggerPhrase_IsStored() {
        let ts = makeTimestamp(triggerPhrase: "first, bring water to a boil")

        XCTAssertEqual(ts.triggerPhrase, "first, bring water to a boil")
    }

    func testConfidence_IsStored() {
        let ts = makeTimestamp(confidence: 0.87)

        XCTAssertEqual(ts.confidence, 0.87)
    }

    // MARK: - duration Computed Property Tests

    func testDuration_NormalRange() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertEqual(ts.duration, 90)
    }

    func testDuration_ExactSecond() {
        let ts = makeTimestamp(startTime: 10, endTime: 11)

        XCTAssertEqual(ts.duration, 1)
    }

    func testDuration_ZeroDuration() {
        let ts = makeTimestamp(startTime: 50, endTime: 50)

        XCTAssertEqual(ts.duration, 0)
    }

    func testDuration_FractionalSeconds() {
        let ts = makeTimestamp(startTime: 45.3, endTime: 128.7)

        XCTAssertEqual(ts.duration, 83.4, accuracy: 0.001)
    }

    func testDuration_Negative() {
        // endTime before startTime produces negative duration
        let ts = makeTimestamp(startTime: 120, endTime: 30)

        XCTAssertEqual(ts.duration, -90)
    }

    func testDuration_VeryLong() {
        let ts = makeTimestamp(startTime: 0, endTime: 3600)

        XCTAssertEqual(ts.duration, 3600)
    }

    // MARK: - contains(_:) Method Tests

    func testContains_TimeWithinRange() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertTrue(ts.contains(60))
    }

    func testContains_TimeAtStartBoundary() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertTrue(ts.contains(30))
    }

    func testContains_TimeAtEndBoundary() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertTrue(ts.contains(120))
    }

    func testContains_TimeBeforeRange() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertFalse(ts.contains(29))
    }

    func testContains_TimeJustBeforeStart() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertFalse(ts.contains(29.999))
    }

    func testContains_TimeAfterRange() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertFalse(ts.contains(121))
    }

    func testContains_TimeJustAfterEnd() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertFalse(ts.contains(120.001))
    }

    func testContains_ZeroTime() {
        let ts = makeTimestamp(startTime: 0, endTime: 10)

        XCTAssertTrue(ts.contains(0))
    }

    func testContains_ExactEnd() {
        let ts = makeTimestamp(startTime: 0, endTime: 10)

        XCTAssertTrue(ts.contains(10))
    }

    func testContains_FractionalTime() {
        let ts = makeTimestamp(startTime: 30.5, endTime: 60.5)

        XCTAssertTrue(ts.contains(45.5))
    }

    func testContains_FractionalTimeAtStartBoundary() {
        let ts = makeTimestamp(startTime: 30.5, endTime: 60.5)

        XCTAssertTrue(ts.contains(30.5))
    }

    func testContains_FractionalTimeAtEndBoundary() {
        let ts = makeTimestamp(startTime: 30.5, endTime: 60.5)

        XCTAssertTrue(ts.contains(60.5))
    }

    func testContains_VeryLargeTime() {
        let ts = makeTimestamp(startTime: 1000, endTime: 2000)

        XCTAssertTrue(ts.contains(1500))
        XCTAssertFalse(ts.contains(500))
        XCTAssertFalse(ts.contains(2500))
    }

    func testContains_NegativeTime() {
        let ts = makeTimestamp(startTime: 10, endTime: 20)

        XCTAssertFalse(ts.contains(-5))
    }

    func testContains_ZeroDurationTimestamp() {
        let ts = makeTimestamp(startTime: 50, endTime: 50)

        XCTAssertTrue(ts.contains(50))
        XCTAssertFalse(ts.contains(49.999))
        XCTAssertFalse(ts.contains(50.001))
    }

    // MARK: - Codable Encode/Decode Tests

    func testCodable_RoundTrip() throws {
        let original = makeTimestamp()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.recipeStepId, original.recipeStepId)
        XCTAssertEqual(decoded.stepIndex, original.stepIndex)
        XCTAssertEqual(decoded.startTime, original.startTime, accuracy: 0.001)
        XCTAssertEqual(decoded.endTime, original.endTime, accuracy: 0.001)
        XCTAssertEqual(decoded.triggerPhrase, original.triggerPhrase)
        XCTAssertEqual(decoded.confidence, original.confidence, accuracy: 0.001)
    }

    func testCodable_RoundTrip_CustomValues() throws {
        let original = makeTimestamp(
            id: "custom-ts",
            recipeStepId: "custom-step",
            stepIndex: 3,
            startTime: 45.5,
            endTime: 128.7,
            triggerPhrase: "custom trigger phrase",
            confidence: 0.77
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.id, "custom-ts")
        XCTAssertEqual(decoded.recipeStepId, "custom-step")
        XCTAssertEqual(decoded.stepIndex, 3)
        XCTAssertEqual(decoded.startTime, 45.5, accuracy: 0.001)
        XCTAssertEqual(decoded.endTime, 128.7, accuracy: 0.001)
        XCTAssertEqual(decoded.triggerPhrase, "custom trigger phrase")
        XCTAssertEqual(decoded.confidence, 0.77, accuracy: 0.001)
    }

    func testCodable_DecodeFromJSONString() throws {
        let jsonString = """
        {
            "id": "t1",
            "recipeStepId": "s1",
            "stepIndex": 0,
            "startTime": 30.0,
            "endTime": 120.0,
            "triggerPhrase": "now add the garlic",
            "confidence": 0.94
        }
        """

        let decoder = JSONDecoder()
        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let ts = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(ts.id, "t1")
        XCTAssertEqual(ts.recipeStepId, "s1")
        XCTAssertEqual(ts.stepIndex, 0)
        XCTAssertEqual(ts.startTime, 30.0, accuracy: 0.001)
        XCTAssertEqual(ts.endTime, 120.0, accuracy: 0.001)
        XCTAssertEqual(ts.triggerPhrase, "now add the garlic")
        XCTAssertEqual(ts.confidence, 0.94, accuracy: 0.001)
    }

    func testCodable_KeysAreCorrect() throws {
        let ts = makeTimestamp()

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(ts)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\"confidence\""))
        XCTAssertTrue(json.contains("\"endTime\""))
        XCTAssertTrue(json.contains("\"id\""))
        XCTAssertTrue(json.contains("\"recipeStepId\""))
        XCTAssertTrue(json.contains("\"startTime\""))
        XCTAssertTrue(json.contains("\"stepIndex\""))
        XCTAssertTrue(json.contains("\"triggerPhrase\""))
    }

    func testCodable_ZeroConfidence() throws {
        let original = makeTimestamp(confidence: 0.0)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.confidence, 0.0, accuracy: 0.001)
    }

    func testCodable_MaxConfidence() throws {
        let original = makeTimestamp(confidence: 1.0)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.confidence, 1.0, accuracy: 0.001)
    }

    func testCodable_UnicodeTriggerPhrase() throws {
        let original = makeTimestamp(triggerPhrase: "次に、にんにくを加えます")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.triggerPhrase, "次に、にんにくを加えます")
    }

    func testCodable_EmptyTriggerPhrase() throws {
        let original = makeTimestamp(triggerPhrase: "")

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.triggerPhrase, "")
    }

    func testCodable_NegativeTimes() throws {
        let original = makeTimestamp(startTime: -10, endTime: -5)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeTimestamp.self, from: data)

        XCTAssertEqual(decoded.startTime, -10, accuracy: 0.001)
        XCTAssertEqual(decoded.endTime, -5, accuracy: 0.001)
    }

    // MARK: - Sendable Conformance Tests

    func testSendable_Conformance() {
        let ts = makeTimestamp()

        func takesSendable<T: Sendable>(_ value: T) {
            // no-op
        }
        takesSendable(ts)

        XCTAssertEqual(ts.confidence, 0.94, accuracy: 0.001)
    }

    func testSendable_ConcurrentAccess() {
        let ts = makeTimestamp()
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = ts.id
                _ = ts.recipeStepId
                _ = ts.stepIndex
                _ = ts.startTime
                _ = ts.endTime
                _ = ts.triggerPhrase
                _ = ts.confidence
                _ = ts.duration
                _ = ts.contains(60)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Identifiable Tests

    func testIdentifiable_IdProperty() {
        let ts = makeTimestamp(id: "unique-id")

        XCTAssertEqual(ts.id, "unique-id")
    }

    func testIdentifiable_DifferentIds() {
        let ts1 = makeTimestamp(id: "id-1")
        let ts2 = makeTimestamp(id: "id-2")

        XCTAssertNotEqual(ts1.id, ts2.id)
    }

    // MARK: - Edge Case Tests

    func testContains_JustInsideStart() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertTrue(ts.contains(30.001))
    }

    func testContains_JustInsideEnd() {
        let ts = makeTimestamp(startTime: 30, endTime: 120)

        XCTAssertTrue(ts.contains(119.999))
    }

    func testConfidence_Zero() {
        let ts = makeTimestamp(confidence: 0.0)

        XCTAssertEqual(ts.confidence, 0.0, accuracy: 0.0001)
    }

    func testConfidence_One() {
        let ts = makeTimestamp(confidence: 1.0)

        XCTAssertEqual(ts.confidence, 1.0, accuracy: 0.0001)
    }

    func testConfidence_MidRange() {
        let ts = makeTimestamp(confidence: 0.5)

        XCTAssertEqual(ts.confidence, 0.5, accuracy: 0.0001)
    }

    func testConfidence_VeryLow() {
        let ts = makeTimestamp(confidence: 0.01)

        XCTAssertEqual(ts.confidence, 0.01, accuracy: 0.0001)
    }

    func testConfidence_AboveOne() {
        // Values above 1.0 are technically storable (no validation)
        let ts = makeTimestamp(confidence: 1.5)

        XCTAssertEqual(ts.confidence, 1.5, accuracy: 0.0001)
    }

    func testConfidence_Negative() {
        // Negative confidence is technically storable (no validation)
        let ts = makeTimestamp(confidence: -0.5)

        XCTAssertEqual(ts.confidence, -0.5, accuracy: 0.0001)
    }

    func testStepIndex_Zero() {
        let ts = makeTimestamp(stepIndex: 0)

        XCTAssertEqual(ts.stepIndex, 0)
    }

    func testStepIndex_Large() {
        let ts = makeTimestamp(stepIndex: 1000)

        XCTAssertEqual(ts.stepIndex, 1000)
    }

    func testStepIndex_Negative() {
        // Negative step indices are technically storable (no validation)
        let ts = makeTimestamp(stepIndex: -1)

        XCTAssertEqual(ts.stepIndex, -1)
    }

    func testZeroDuration_ContainsStart() {
        let ts = makeTimestamp(startTime: 50, endTime: 50)

        XCTAssertTrue(ts.contains(50))
    }

    func testZeroDuration_DoesNotContainNearby() {
        let ts = makeTimestamp(startTime: 50, endTime: 50)

        XCTAssertFalse(ts.contains(49))
        XCTAssertFalse(ts.contains(51))
    }

    func testTriggerPhrase_VeryLong() {
        let longPhrase = String(repeating: "now ", count: 100)
        let ts = makeTimestamp(triggerPhrase: longPhrase)

        XCTAssertEqual(ts.triggerPhrase, longPhrase)
    }

    func testTriggerPhrase_SingleCharacter() {
        let ts = makeTimestamp(triggerPhrase: "a")

        XCTAssertEqual(ts.triggerPhrase, "a")
    }

    func testStartTime_EndTime_Equal_Zero() {
        let ts = makeTimestamp(startTime: 0, endTime: 0)

        XCTAssertEqual(ts.startTime, 0)
        XCTAssertEqual(ts.endTime, 0)
        XCTAssertEqual(ts.duration, 0)
        XCTAssertTrue(ts.contains(0))
    }

    func testContains_AtVeryLargeTime() {
        let ts = makeTimestamp(startTime: 0, endTime: 1_000_000)

        XCTAssertTrue(ts.contains(500_000))
        XCTAssertFalse(ts.contains(1_000_001))
    }

    func testDuration_LargeRange() {
        let ts = makeTimestamp(startTime: 0, endTime: 86_400)

        XCTAssertEqual(ts.duration, 86_400)
    }
}
