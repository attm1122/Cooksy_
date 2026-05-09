import Foundation

// MARK: - RecipeTimestamp

/// Maps a recipe step to a specific time range in the source video.
/// When the video plays between startTime and endTime, this step is "active."
struct RecipeTimestamp: Codable, Identifiable, Sendable {
    let id: String
    let recipeStepId: String
    let stepIndex: Int              // 0-based display order
    let startTime: TimeInterval     // e.g. 45.3 seconds
    let endTime: TimeInterval       // e.g. 128.7 seconds
    let triggerPhrase: String       // What the creator said: "now add the garlic"
    let confidence: Double          // 0.0...1.0

    /// Is the given video time within this step's range?
    func contains(_ time: TimeInterval) -> Bool {
        time >= startTime && time <= endTime
    }

    var duration: TimeInterval {
        endTime - startTime
    }
}

// MARK: - RecipeSyncMap

/// The complete sync map for a recipe + video pair.
struct RecipeSyncMap: Codable, Sendable {
    let recipeId: String
    let videoUrl: String
    let videoDuration: TimeInterval
    let timestamps: [RecipeTimestamp]
    let generatedAt: Date

    /// Hysteresis window (in seconds) to prevent flickering between adjacent steps.
    private static let hysteresis: TimeInterval = 0.5

    /// Look up which step index should be active at a given video time.
    /// Uses 0.5s hysteresis to prevent flickering between steps.
    func activeStepIndex(at time: TimeInterval) -> Int? {
        // First, try to find a timestamp that strictly contains the time
        if let index = timestamps.firstIndex(where: { $0.contains(time) }) {
            return index
        }

        // With hysteresis: if time is within hysteresis of a step's start,
        // prefer that step to avoid flickering when transitioning
        for (index, timestamp) in timestamps.enumerated() {
            let adjustedStart = max(0, timestamp.startTime - Self.hysteresis)
            let adjustedEnd = timestamp.endTime + Self.hysteresis
            if time >= adjustedStart && time <= adjustedEnd {
                return index
            }
        }

        return nil
    }

    /// Get the timestamp for a specific step index
    func timestamp(forStepIndex index: Int) -> RecipeTimestamp? {
        timestamps.first { $0.stepIndex == index }
    }

    /// Percentage of video duration covered by recipe steps (0.0...1.0)
    var coverageRatio: Double {
        guard videoDuration > 0 else { return 0 }
        let covered = timestamps.reduce(0) { $0 + $1.duration }
        return min(covered / videoDuration, 1.0)
    }

    /// Average confidence across all timestamps
    var averageConfidence: Double {
        guard !timestamps.isEmpty else { return 0 }
        return timestamps.map(\.confidence).reduce(0, +) / Double(timestamps.count)
    }
}

// MARK: - Mock Data

extension RecipeSyncMap {
    static func mock(for recipeId: String) -> RecipeSyncMap {
        RecipeSyncMap(
            recipeId: recipeId,
            videoUrl: "https://youtube.com/watch?v=mock",
            videoDuration: 480,
            timestamps: [
                RecipeTimestamp(
                    id: "t1",
                    recipeStepId: "s1",
                    stepIndex: 0,
                    startTime: 30,
                    endTime: 120,
                    triggerPhrase: "first, bring a large pot of salted water to a boil",
                    confidence: 0.94
                ),
                RecipeTimestamp(
                    id: "t2",
                    recipeStepId: "s2",
                    stepIndex: 1,
                    startTime: 120,
                    endTime: 210,
                    triggerPhrase: "while the pasta cooks, melt butter in a large pan",
                    confidence: 0.91
                ),
                RecipeTimestamp(
                    id: "t3",
                    recipeStepId: "s3",
                    stepIndex: 2,
                    startTime: 210,
                    endTime: 290,
                    triggerPhrase: "add the heavy cream and bring to a gentle simmer",
                    confidence: 0.89
                ),
                RecipeTimestamp(
                    id: "t4",
                    recipeStepId: "s4",
                    stepIndex: 3,
                    startTime: 290,
                    endTime: 370,
                    triggerPhrase: "drain the pasta and add it to the sauce",
                    confidence: 0.93
                ),
                RecipeTimestamp(
                    id: "t5",
                    recipeStepId: "s5",
                    stepIndex: 4,
                    startTime: 370,
                    endTime: 480,
                    triggerPhrase: "season with salt and pepper and serve immediately",
                    confidence: 0.90
                ),
            ],
            generatedAt: Date()
        )
    }
}
