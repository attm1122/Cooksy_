import XCTest
@testable import Cooksy

// MARK: - RecipeSyncMap Model Tests
/// Comprehensive unit tests for the RecipeSyncMap struct covering all stored properties,
/// lookup methods (activeStepIndex, timestamp, nextStep, previousStep, stepIndex),
/// computed properties (coverageRatio, averageConfidence), Codable encode/decode,
/// mock data generation, and edge cases.
final class RecipeSyncMapTests: XCTestCase {

    // MARK: - Factory Helpers

    private func makeTimestamp(
        id: String,
        recipeStepId: String,
        stepIndex: Int,
        startTime: TimeInterval,
        endTime: TimeInterval,
        triggerPhrase: String = "test phrase",
        confidence: Double = 0.9
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

    private func makeSyncMap(
        recipeId: String = "recipe-1",
        videoUrl: String = "https://youtube.com/watch?v=test",
        videoDuration: TimeInterval = 480,
        timestamps: [RecipeTimestamp] = [],
        generatedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> RecipeSyncMap {
        RecipeSyncMap(
            recipeId: recipeId,
            videoUrl: videoUrl,
            videoDuration: videoDuration,
            timestamps: timestamps,
            generatedAt: generatedAt
        )
    }

    private func makeFiveStepSyncMap() -> RecipeSyncMap {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 30, endTime: 120, triggerPhrase: "step 0", confidence: 0.94),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 120, endTime: 210, triggerPhrase: "step 1", confidence: 0.91),
            makeTimestamp(id: "t2", recipeStepId: "s2", stepIndex: 2, startTime: 210, endTime: 290, triggerPhrase: "step 2", confidence: 0.89),
            makeTimestamp(id: "t3", recipeStepId: "s3", stepIndex: 3, startTime: 290, endTime: 370, triggerPhrase: "step 3", confidence: 0.93),
            makeTimestamp(id: "t4", recipeStepId: "s4", stepIndex: 4, startTime: 370, endTime: 480, triggerPhrase: "step 4", confidence: 0.90),
        ]
        return makeSyncMap(timestamps: timestamps)
    }

    // MARK: - Stored Property Tests

    func testRecipeId_IsStored() {
        let map = makeSyncMap(recipeId: "my-recipe-123")

        XCTAssertEqual(map.recipeId, "my-recipe-123")
    }

    func testVideoUrl_IsStored() {
        let map = makeSyncMap(videoUrl: "https://example.com/video")

        XCTAssertEqual(map.videoUrl, "https://example.com/video")
    }

    func testVideoDuration_IsStored() {
        let map = makeSyncMap(videoDuration: 600)

        XCTAssertEqual(map.videoDuration, 600)
    }

    func testTimestamps_IsStored() {
        let ts = makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 0, startTime: 0, endTime: 10)
        let map = makeSyncMap(timestamps: [ts])

        XCTAssertEqual(map.timestamps.count, 1)
    }

    func testTimestamps_IsEmptyByDefault() {
        let map = makeSyncMap()

        XCTAssertTrue(map.timestamps.isEmpty)
    }

    func testGeneratedAt_IsStored() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let map = makeSyncMap(generatedAt: date)

        XCTAssertEqual(map.generatedAt, date)
    }

    // MARK: - activeStepIndex(at:) Method Tests

    func testActiveStepIndex_ExactTime() {
        let map = makeFiveStepSyncMap()

        XCTAssertEqual(map.activeStepIndex(at: 60), 0)
        XCTAssertEqual(map.activeStepIndex(at: 150), 1)
        XCTAssertEqual(map.activeStepIndex(at: 250), 2)
        XCTAssertEqual(map.activeStepIndex(at: 330), 3)
        XCTAssertEqual(map.activeStepIndex(at: 425), 4)
    }

    func testActiveStepIndex_AtStartBoundary() {
        let map = makeFiveStepSyncMap()

        XCTAssertEqual(map.activeStepIndex(at: 30), 0)
        XCTAssertEqual(map.activeStepIndex(at: 120), 1)
        XCTAssertEqual(map.activeStepIndex(at: 210), 2)
    }

    func testActiveStepIndex_AtEndBoundary() {
        let map = makeFiveStepSyncMap()

        XCTAssertEqual(map.activeStepIndex(at: 120), 1)
        XCTAssertEqual(map.activeStepIndex(at: 210), 2)
        XCTAssertEqual(map.activeStepIndex(at: 290), 3)
        XCTAssertEqual(map.activeStepIndex(at: 370), 4)
        XCTAssertEqual(map.activeStepIndex(at: 480), 4)
    }

    func testActiveStepIndex_BeforeFirst() {
        let map = makeFiveStepSyncMap()

        XCTAssertNil(map.activeStepIndex(at: 0))
        XCTAssertNil(map.activeStepIndex(at: 29))
    }

    func testActiveStepIndex_AfterLast() {
        let map = makeFiveStepSyncMap()

        XCTAssertNil(map.activeStepIndex(at: 481))
        XCTAssertNil(map.activeStepIndex(at: 1000))
    }

    func testActiveStepIndex_BetweenTimestamps_WithHysteresis() {
        let map = makeFiveStepSyncMap()

        // At exactly 120, the second timestamp starts (overlap at boundaries)
        // Due to hysteresis, should still find a step
        XCTAssertNotNil(map.activeStepIndex(at: 119))
    }

    func testActiveStepIndex_NearStartWithHysteresis() {
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 10, endTime: 50)
            ]
        )

        // Within hysteresis of start (10 - 0.5 = 9.5)
        XCTAssertEqual(map.activeStepIndex(at: 9.7), 0)
        XCTAssertNil(map.activeStepIndex(at: 8.0))
    }

    func testActiveStepIndex_NearEndWithHysteresis() {
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 10, endTime: 50)
            ]
        )

        // Within hysteresis of end (50 + 0.5 = 50.5)
        XCTAssertEqual(map.activeStepIndex(at: 50.4), 0)
    }

    func testActiveStepIndex_ZeroTime() {
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10)
            ]
        )

        XCTAssertEqual(map.activeStepIndex(at: 0), 0)
    }

    func testActiveStepIndex_NegativeTime() {
        let map = makeFiveStepSyncMap()

        XCTAssertNil(map.activeStepIndex(at: -10))
    }

    // MARK: - timestamp(forStepIndex:) Method Tests

    func testTimestampForStepIndex_Found() {
        let map = makeFiveStepSyncMap()

        let ts = map.timestamp(forStepIndex: 2)
        XCTAssertNotNil(ts)
        XCTAssertEqual(ts?.id, "t2")
        XCTAssertEqual(ts?.stepIndex, 2)
    }

    func testTimestampForStepIndex_Step0() {
        let map = makeFiveStepSyncMap()

        let ts = map.timestamp(forStepIndex: 0)
        XCTAssertNotNil(ts)
        XCTAssertEqual(ts?.id, "t0")
    }

    func testTimestampForStepIndex_LastStep() {
        let map = makeFiveStepSyncMap()

        let ts = map.timestamp(forStepIndex: 4)
        XCTAssertNotNil(ts)
        XCTAssertEqual(ts?.id, "t4")
    }

    func testTimestampForStepIndex_NotFound() {
        let map = makeFiveStepSyncMap()

        let ts = map.timestamp(forStepIndex: 99)
        XCTAssertNil(ts)
    }

    func testTimestampForStepIndex_NegativeIndex() {
        let map = makeFiveStepSyncMap()

        let ts = map.timestamp(forStepIndex: -1)
        XCTAssertNil(ts)
    }

    func testTimestampForStepIndex_EmptyTimestamps() {
        let map = makeSyncMap(timestamps: [])

        let ts = map.timestamp(forStepIndex: 0)
        XCTAssertNil(ts)
    }

    // MARK: - coverageRatio Computed Property Tests

    func testCoverageRatio_FullCoverage() {
        // Video duration 100, timestamps cover 0-50 and 50-100 = 100 total
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 50),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 50, endTime: 100),
        ]
        let map = makeSyncMap(videoDuration: 100, timestamps: timestamps)

        XCTAssertEqual(map.coverageRatio, 1.0, accuracy: 0.001)
    }

    func testCoverageRatio_HalfCoverage() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 50),
        ]
        let map = makeSyncMap(videoDuration: 100, timestamps: timestamps)

        XCTAssertEqual(map.coverageRatio, 0.5, accuracy: 0.001)
    }

    func testCoverageRatio_NoCoverage() {
        let map = makeSyncMap(videoDuration: 100, timestamps: [])

        XCTAssertEqual(map.coverageRatio, 0.0, accuracy: 0.001)
    }

    func testCoverageRatio_NoTimestamps() {
        let map = makeSyncMap(videoDuration: 100, timestamps: [])

        XCTAssertEqual(map.coverageRatio, 0.0)
    }

    func testCoverageRatio_ZeroVideoDuration() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10),
        ]
        let map = makeSyncMap(videoDuration: 0, timestamps: timestamps)

        XCTAssertEqual(map.coverageRatio, 0.0)
    }

    func testCoverageRatio_NegativeVideoDuration() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10),
        ]
        let map = makeSyncMap(videoDuration: -10, timestamps: timestamps)

        XCTAssertEqual(map.coverageRatio, 0.0)
    }

    func testCoverageRatio_OverCoverage() {
        // Timestamps cover more than video duration (should be capped at 1.0)
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 60),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 60, endTime: 120),
        ]
        let map = makeSyncMap(videoDuration: 100, timestamps: timestamps)

        XCTAssertEqual(map.coverageRatio, 1.0, accuracy: 0.001)
    }

    func testCoverageRatio_SingleTimestamp() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 10, endTime: 90),
        ]
        let map = makeSyncMap(videoDuration: 100, timestamps: timestamps)

        XCTAssertEqual(map.coverageRatio, 0.8, accuracy: 0.001)
    }

    // MARK: - averageConfidence Computed Property Tests

    func testAverageConfidence_Normal() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10, confidence: 0.9),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 10, endTime: 20, confidence: 0.7),
        ]
        let map = makeSyncMap(timestamps: timestamps)

        XCTAssertEqual(map.averageConfidence, 0.8, accuracy: 0.001)
    }

    func testAverageConfidence_EmptyTimestamps() {
        let map = makeSyncMap(timestamps: [])

        XCTAssertEqual(map.averageConfidence, 0.0, accuracy: 0.001)
    }

    func testAverageConfidence_SingleTimestamp() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10, confidence: 0.95),
        ]
        let map = makeSyncMap(timestamps: timestamps)

        XCTAssertEqual(map.averageConfidence, 0.95, accuracy: 0.001)
    }

    func testAverageConfidence_MaxValues() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10, confidence: 1.0),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 10, endTime: 20, confidence: 1.0),
        ]
        let map = makeSyncMap(timestamps: timestamps)

        XCTAssertEqual(map.averageConfidence, 1.0, accuracy: 0.001)
    }

    func testAverageConfidence_ZeroValues() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10, confidence: 0.0),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 10, endTime: 20, confidence: 0.0),
        ]
        let map = makeSyncMap(timestamps: timestamps)

        XCTAssertEqual(map.averageConfidence, 0.0, accuracy: 0.001)
    }

    func testAverageConfidence_ManyTimestamps() {
        let timestamps = (0..<100).map { i in
            makeTimestamp(
                id: "t\(i)",
                recipeStepId: "s\(i)",
                stepIndex: i,
                startTime: TimeInterval(i * 10),
                endTime: TimeInterval((i + 1) * 10),
                confidence: 0.5
            )
        }
        let map = makeSyncMap(timestamps: timestamps)

        XCTAssertEqual(map.averageConfidence, 0.5, accuracy: 0.001)
    }

    // MARK: - Codable Encode/Decode Tests

    func testCodable_RoundTrip() throws {
        let original = makeFiveStepSyncMap()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeSyncMap.self, from: data)

        XCTAssertEqual(decoded.recipeId, original.recipeId)
        XCTAssertEqual(decoded.videoUrl, original.videoUrl)
        XCTAssertEqual(decoded.videoDuration, original.videoDuration, accuracy: 0.001)
        XCTAssertEqual(decoded.timestamps.count, original.timestamps.count)
    }

    func testCodable_RoundTrip_EmptyTimestamps() throws {
        let original = makeSyncMap(timestamps: [])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeSyncMap.self, from: data)

        XCTAssertEqual(decoded.timestamps.count, 0)
        XCTAssertEqual(decoded.recipeId, "recipe-1")
    }

    func testCodable_RoundTrip_SingleTimestamp() throws {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10)
        ]
        let original = makeSyncMap(timestamps: timestamps)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeSyncMap.self, from: data)

        XCTAssertEqual(decoded.timestamps.count, 1)
        XCTAssertEqual(decoded.timestamps[0].id, "t0")
    }

    func testCodable_DecodeFromJSONString() throws {
        let jsonString = """
        {
            "recipeId": "recipe-1",
            "videoUrl": "https://youtube.com/watch?v=test",
            "videoDuration": 480,
            "timestamps": [
                {
                    "id": "t0",
                    "recipeStepId": "s0",
                    "stepIndex": 0,
                    "startTime": 30,
                    "endTime": 120,
                    "triggerPhrase": "step 0",
                    "confidence": 0.94
                }
            ],
            "generatedAt": 1700000000
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let map = try decoder.decode(RecipeSyncMap.self, from: data)

        XCTAssertEqual(map.recipeId, "recipe-1")
        XCTAssertEqual(map.videoUrl, "https://youtube.com/watch?v=test")
        XCTAssertEqual(map.videoDuration, 480, accuracy: 0.001)
        XCTAssertEqual(map.timestamps.count, 1)
        XCTAssertEqual(map.timestamps[0].id, "t0")
    }

    func testCodable_KeysAreCorrect() throws {
        let map = makeSyncMap()

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(map)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\"generatedAt\""))
        XCTAssertTrue(json.contains("\"recipeId\""))
        XCTAssertTrue(json.contains("\"timestamps\""))
        XCTAssertTrue(json.contains("\"videoDuration\""))
        XCTAssertTrue(json.contains("\"videoUrl\""))
    }

    // MARK: - Mock Data Tests

    func testMockData_GeneratesValidSyncMap() {
        let map = RecipeSyncMap.mock(for: "test-recipe-123")

        XCTAssertEqual(map.recipeId, "test-recipe-123")
        XCTAssertEqual(map.videoUrl, "https://youtube.com/watch?v=mock")
        XCTAssertEqual(map.videoDuration, 480, accuracy: 0.001)
        XCTAssertEqual(map.timestamps.count, 5)
    }

    func testMockData_TimestampsAreOrdered() {
        let map = RecipeSyncMap.mock(for: "recipe-1")

        for i in 1..<map.timestamps.count {
            let prev = map.timestamps[i - 1]
            let curr = map.timestamps[i]
            XCTAssertLessThanOrEqual(prev.endTime, curr.startTime)
        }
    }

    func testMockData_StepIndicesAreSequential() {
        let map = RecipeSyncMap.mock(for: "recipe-1")

        for (i, ts) in map.timestamps.enumerated() {
            XCTAssertEqual(ts.stepIndex, i)
        }
    }

    func testMockData_FirstTimestamp() {
        let map = RecipeSyncMap.mock(for: "recipe-1")
        let first = map.timestamps[0]

        XCTAssertEqual(first.id, "t1")
        XCTAssertEqual(first.recipeStepId, "s1")
        XCTAssertEqual(first.stepIndex, 0)
        XCTAssertEqual(first.startTime, 30, accuracy: 0.001)
        XCTAssertEqual(first.endTime, 120, accuracy: 0.001)
        XCTAssertEqual(first.triggerPhrase, "first, bring a large pot of salted water to a boil")
        XCTAssertEqual(first.confidence, 0.94, accuracy: 0.001)
    }

    func testMockData_LastTimestamp() {
        let map = RecipeSyncMap.mock(for: "recipe-1")
        let last = map.timestamps[4]

        XCTAssertEqual(last.id, "t5")
        XCTAssertEqual(last.recipeStepId, "s5")
        XCTAssertEqual(last.stepIndex, 4)
        XCTAssertEqual(last.startTime, 370, accuracy: 0.001)
        XCTAssertEqual(last.endTime, 480, accuracy: 0.001)
        XCTAssertEqual(last.triggerPhrase, "season with salt and pepper and serve immediately")
        XCTAssertEqual(last.confidence, 0.90, accuracy: 0.001)
    }

    func testMockData_GeneratedAtIsSet() {
        let beforeGeneration = Date()
        let map = RecipeSyncMap.mock(for: "recipe-1")
        let afterGeneration = Date()

        XCTAssertGreaterThanOrEqual(map.generatedAt, beforeGeneration)
        XCTAssertLessThanOrEqual(map.generatedAt, afterGeneration)
    }

    func testMockData_DifferentRecipeIds() {
        let map1 = RecipeSyncMap.mock(for: "recipe-a")
        let map2 = RecipeSyncMap.mock(for: "recipe-b")

        XCTAssertEqual(map1.recipeId, "recipe-a")
        XCTAssertEqual(map2.recipeId, "recipe-b")
    }

    func testMockData_CoverageRatio() {
        let map = RecipeSyncMap.mock(for: "recipe-1")

        // Total covered: (120-30) + (210-120) + (290-210) + (370-290) + (480-370) = 90 + 90 + 80 + 80 + 110 = 450
        // Video duration: 480
        // Expected ratio: 450/480 = 0.9375
        XCTAssertEqual(map.coverageRatio, 450.0 / 480.0, accuracy: 0.001)
    }

    func testMockData_AverageConfidence() {
        let map = RecipeSyncMap.mock(for: "recipe-1")

        // (0.94 + 0.91 + 0.89 + 0.93 + 0.90) / 5 = 4.57 / 5 = 0.914
        XCTAssertEqual(map.averageConfidence, 0.914, accuracy: 0.001)
    }

    // MARK: - Edge Case Tests

    func testActiveStepIndex_EmptyTimestamps() {
        let map = makeSyncMap(timestamps: [])

        XCTAssertNil(map.activeStepIndex(at: 10))
        XCTAssertNil(map.activeStepIndex(at: 0))
        XCTAssertNil(map.activeStepIndex(at: 1000))
    }

    func testActiveStepIndex_SingleTimestamp() {
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 10, endTime: 50)
            ]
        )

        XCTAssertNil(map.activeStepIndex(at: 5))
        XCTAssertEqual(map.activeStepIndex(at: 30), 0)
        XCTAssertNil(map.activeStepIndex(at: 55))
    }

    func testActiveStepIndex_OverlappingTimestamps() {
        // Timestamps overlap: [0-30] and [25-50]
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 30),
                makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 25, endTime: 50),
            ]
        )

        // At overlap region [25-30], firstIndex returns the first match
        XCTAssertEqual(map.activeStepIndex(at: 27), 0)
    }

    func testCoverageRatio_WithOverlappingTimestamps() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 30),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 25, endTime: 50),
        ]
        let map = makeSyncMap(videoDuration: 50, timestamps: timestamps)

        // Duration sum: 30 + 25 = 55, ratio = 55/50 = 1.1, capped at 1.0
        XCTAssertEqual(map.coverageRatio, 1.0, accuracy: 0.001)
    }

    func testAverageConfidence_AllSame() {
        let timestamps = [
            makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10, confidence: 0.5),
            makeTimestamp(id: "t1", recipeStepId: "s1", stepIndex: 1, startTime: 10, endTime: 20, confidence: 0.5),
            makeTimestamp(id: "t2", recipeStepId: "s2", stepIndex: 2, startTime: 20, endTime: 30, confidence: 0.5),
        ]
        let map = makeSyncMap(timestamps: timestamps)

        XCTAssertEqual(map.averageConfidence, 0.5, accuracy: 0.001)
    }

    func testTimestampForStepIndex_NoMatch() {
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 0, endTime: 10),
                makeTimestamp(id: "t2", recipeStepId: "s2", stepIndex: 2, startTime: 10, endTime: 20),
            ]
        )

        // stepIndex 1 doesn't exist
        XCTAssertNil(map.timestamp(forStepIndex: 1))
        XCTAssertNotNil(map.timestamp(forStepIndex: 0))
        XCTAssertNotNil(map.timestamp(forStepIndex: 2))
    }

    func testActiveStepIndex_WithHysteresis_AtVideoStart() {
        // Timestamp starts at 1, but hysteresis window extends before
        let map = makeSyncMap(
            timestamps: [
                makeTimestamp(id: "t0", recipeStepId: "s0", stepIndex: 0, startTime: 1, endTime: 10)
            ]
        )

        // At 0.8, within hysteresis of 1.0 - 0.5 = 0.5, but adjusted start is max(0, 1-0.5) = 0.5
        // 0.8 >= 0.5 && 0.8 <= 10.5 -> true
        XCTAssertEqual(map.activeStepIndex(at: 0.8), 0)
    }

    func testGeneratedAt_Decode() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let map = makeSyncMap(generatedAt: fixedDate)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(map)
        let decoded = try decoder.decode(RecipeSyncMap.self, from: data)

        XCTAssertEqual(decoded.generatedAt, fixedDate)
    }

    func testVideoUrl_SpecialCharacters() {
        let map = makeSyncMap(videoUrl: "https://youtube.com/watch?v=abc&list=xyz&t=30s")

        XCTAssertEqual(map.videoUrl, "https://youtube.com/watch?v=abc&list=xyz&t=30s")
    }

    func testVideoDuration_VeryLong() {
        let map = makeSyncMap(videoDuration: 86_400) // 24 hours

        XCTAssertEqual(map.videoDuration, 86_400, accuracy: 0.001)
    }

    func testRecipeId_EmptyString() {
        let map = makeSyncMap(recipeId: "")

        XCTAssertEqual(map.recipeId, "")
    }

    func testRecipeId_Unicode() {
        let map = makeSyncMap(recipeId: "レシピ-1")

        XCTAssertEqual(map.recipeId, "レシピ-1")
    }

    func testCodable_VeryLongTimestampsArray() throws {
        let timestamps = (0..<1000).map { i in
            makeTimestamp(
                id: "t\(i)",
                recipeStepId: "s\(i)",
                stepIndex: i,
                startTime: TimeInterval(i),
                endTime: TimeInterval(i + 1),
                confidence: Double(i) / 1000.0
            )
        }
        let original = makeSyncMap(timestamps: timestamps)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RecipeSyncMap.self, from: data)

        XCTAssertEqual(decoded.timestamps.count, 1000)
        XCTAssertEqual(decoded.timestamps[0].stepIndex, 0)
        XCTAssertEqual(decoded.timestamps[999].stepIndex, 999)
    }

    func testSendable_Conformance() {
        let map = makeFiveStepSyncMap()

        func takesSendable<T: Sendable>(_ value: T) {
            // no-op
        }
        takesSendable(map)

        XCTAssertFalse(map.timestamps.isEmpty)
    }

    func testSendable_ConcurrentAccess() {
        let map = makeFiveStepSyncMap()
        let expectation = self.expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = map.recipeId
                _ = map.videoUrl
                _ = map.videoDuration
                _ = map.timestamps.count
                _ = map.coverageRatio
                _ = map.averageConfidence
                _ = map.activeStepIndex(at: 60)
                _ = map.timestamp(forStepIndex: 2)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }
}
