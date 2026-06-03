import Foundation

// MARK: - TimestampExtractionService

/// Extracts timestamps from a trusted timed transcript and matches recipe steps
/// to spoken phrases. Audio transcription is intentionally handled by the secure
/// backend so private AI vendor keys are never bundled into the iOS app.
@Observable
@MainActor
final class TimestampExtractionService {

    // MARK: - Dependencies

    private let cache: SyncMapCache

    // MARK: - Initialization

    /// Creates a new TimestampExtractionService.
    /// - Parameters:
    ///   - cache: Cache layer for persisting sync maps (defaults to in-memory)
    init(
        cache: SyncMapCache = InMemorySyncMapCache()
    ) {
        self.cache = cache
    }

    // MARK: - Public API

    /// Extract timestamps for a recipe's steps from its source video.
    /// - Parameters:
    ///   - recipe: The recipe with steps to map
    ///   - videoUrl: The source video URL
    /// - Returns: A RecipeSyncMap connecting each step to video time ranges
    func extractTimestamps(for recipe: Recipe, videoUrl: String) async throws -> RecipeSyncMap {

        // 1. Check cache first
        if let cached = try? await cache.load(for: recipe.id.uuidString) {
            return cached
        }

        throw CooksyError.transcriptionUnavailable(
            "Cook-along requires server-side transcription. This feature will be available in a future update."
        )
    }

    /// Extract timestamps from a backend-generated timed transcript.
    func extractTimestampsProduction(
        for recipe: Recipe,
        videoUrl: String,
        videoDuration: TimeInterval,
        transcript: TimedTranscript
    ) async throws -> RecipeSyncMap {

        // Check cache
        if let cached = try? await cache.load(for: recipe.id.uuidString) {
            return cached
        }

        let timestamps = matchStepsToTranscription(
            steps: recipe.steps,
            transcription: transcript,
            videoDuration: videoDuration
        )

        guard !timestamps.isEmpty else {
            throw CooksyError.noMatchingStepsFound
        }

        let syncMap = RecipeSyncMap(
            recipeId: recipe.id.uuidString,
            videoUrl: videoUrl,
            videoDuration: videoDuration,
            timestamps: timestamps,
            generatedAt: Date()
        )

        // Cache result
        try? await cache.save(syncMap)

        return syncMap
    }

    /// Check if a sync map already exists for this recipe.
    func hasExistingSyncMap(for recipeId: String) async -> Bool {
        (try? await cache.load(for: recipeId)) != nil
    }

    /// Load a cached sync map.
    func loadSyncMap(for recipeId: String) async -> RecipeSyncMap? {
        try? await cache.load(for: recipeId)
    }

    /// Save a sync map to cache.
    func saveSyncMap(_ syncMap: RecipeSyncMap) async {
        try? await cache.save(syncMap)
    }

}

// MARK: - Sync Map Cache Protocol

/// Abstract cache for RecipeSyncMap persistence.
protocol SyncMapCache: Sendable {
    func load(for recipeId: String) async throws -> RecipeSyncMap?
    func save(_ syncMap: RecipeSyncMap) async throws
    func delete(for recipeId: String) async throws
}

// MARK: - In-Memory Cache (Development)

/// In-memory cache for development and previews.
actor InMemorySyncMapCache: SyncMapCache {
    private var storage: [String: RecipeSyncMap] = [:]

    func load(for recipeId: String) -> RecipeSyncMap? {
        storage[recipeId]
    }

    func save(_ syncMap: RecipeSyncMap) {
        storage[syncMap.recipeId] = syncMap
    }

    func delete(for recipeId: String) {
        storage.removeValue(forKey: recipeId)
    }
}

// MARK: - Timed Transcript

/// Backend-generated transcript with word-level timestamps.
struct TimedTranscript: Codable, Sendable {
    struct Word: Codable, Sendable {
        let word: String
        let start: Double
        let end: Double
    }

    struct Segment: Codable, Sendable {
        let id: Int
        let start: Double
        let end: Double
        let text: String
        let words: [Word]?
    }

    let text: String
    let words: [Word]?
    let segments: [Segment]?
}

// MARK: - Transcript Matching

extension TimestampExtractionService {

    /// Match recipe steps to transcription words using NLP techniques.
    ///
    /// Algorithm:
    /// 1. Tokenize each recipe step into keywords (ingredients + action verbs)
    /// 2. Slide a window over transcription words
    /// 3. Score each window by keyword overlap (TF-IDF weighted)
    /// 4. Assign the highest-scoring window to each step
    /// 5. Apply confidence based on overlap ratio
    func matchStepsToTranscription(
        steps: [RecipeStep],
        transcription: TimedTranscript,
        videoDuration: TimeInterval
    ) -> [RecipeTimestamp] {

        // Collect all words from transcription
        let allWords: [TimedTranscript.Word]
        if let words = transcription.words, !words.isEmpty {
            allWords = words
        } else if let segments = transcription.segments {
            allWords = segments.compactMap(\.words).flatMap { $0 }
        } else {
            return []
        }

        guard !allWords.isEmpty else { return [] }

        // Window size in words (roughly a phrase)
        let windowSize = 15
        let stride = 3

        var timestamps: [RecipeTimestamp] = []

        for step in steps.sorted(by: { $0.index < $1.index }) {
            let stepKeywords = extractKeywords(from: step)
            guard !stepKeywords.isEmpty else { continue }

            var bestScore: Double = 0
            var bestStart: Double = 0
            var bestEnd: Double = 0

            // Slide window over words
            var windowStart = 0
            while windowStart + windowSize <= allWords.count {
                let window = Array(allWords[windowStart..<min(windowStart + windowSize, allWords.count)])
                let windowText = window.map(\.word.lowercased())

                let score = scoreWindow(windowText: windowText, stepKeywords: stepKeywords)

                if score > bestScore {
                    bestScore = score
                    bestStart = window.first?.start ?? 0
                    bestEnd = window.last?.end ?? videoDuration
                }

                windowStart += stride
            }

            // Handle remaining words at the end
            if windowStart < allWords.count {
                let window = Array(allWords[windowStart...])
                let windowText = window.map(\.word.lowercased())
                let score = scoreWindow(windowText: windowText, stepKeywords: stepKeywords)
                if score > bestScore {
                    bestScore = score
                    bestStart = window.first?.start ?? 0
                    bestEnd = window.last?.end ?? videoDuration
                }
            }

            // Only include if we found a reasonable match
            let confidence = min(bestScore / Double(stepKeywords.count), 1.0)
            guard confidence > 0.15 else { continue }

            let timestamp = RecipeTimestamp(
                id: "\(step.id.uuidString)_ts",
                recipeStepId: step.id.uuidString,
                stepIndex: step.index,
                startTime: bestStart,
                endTime: bestEnd,
                triggerPhrase: allWords
                    .filter { $0.start >= bestStart && $0.end <= bestEnd }
                    .map(\.word)
                    .joined(separator: " "),
                confidence: confidence
            )

            timestamps.append(timestamp)
        }

        // Resolve overlaps: if two timestamps overlap significantly, merge or adjust
        return resolveOverlaps(timestamps)
    }

    // MARK: - Private: NLP Helpers

    /// Extract searchable keywords from a recipe step.
    /// Prioritizes ingredient names and cooking action verbs.
    private func extractKeywords(from step: RecipeStep) -> [String] {
        var keywords: [String] = []

        // Add ingredient names
        keywords.append(contentsOf: step.ingredients.map { $0.lowercased() })

        // Extract action verbs and key nouns from instruction
        let instruction = step.instruction.lowercased()
        let actionWords = [
            "chop", "dice", "mince", "slice", "cut", "grate",
            "mix", "stir", "whisk", "fold", "combine",
            "heat", "boil", "simmer", "fry", "saute", "bake", "roast",
            "add", "pour", "toss", "drain", "season", "marinate",
            "preheat", "cook", "melt", "blend", "serve"
        ]

        for word in actionWords where instruction.contains(word) {
            keywords.append(word)
        }

        // Extract noun phrases (simplified: words after action verbs)
        let words = instruction.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 2 }

        keywords.append(contentsOf: words)

        // Deduplicate while preserving order
        var seen = Set<String>()
        return keywords.filter { seen.insert($0).inserted }
    }

    /// Score a window of transcription words against step keywords.
    /// Uses exact matching with small edit-distance tolerance.
    private func scoreWindow(windowText: [String], stepKeywords: [String]) -> Double {
        var score: Double = 0

        for keyword in stepKeywords {
            for word in windowText {
                if word == keyword {
                    score += 1.0
                } else if levenshteinDistance(word, keyword) <= 1 && keyword.count > 4 {
                    // Fuzzy match for longer words
                    score += 0.7
                }
            }
        }

        return score
    }

    /// Compute Levenshtein distance between two strings.
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let empty = Array(repeating: 0, count: s2.count + 1)
        var last = Array(0...s2.count)

        for (i, c1) in s1.enumerated() {
            var cur = [i + 1] + empty.dropLast()
            for (j, c2) in s2.enumerated() {
                cur[j + 1] = c1 == c2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }

        return last[s2.count]
    }

    /// Resolve overlapping timestamps by adjusting boundaries.
    private func resolveOverlaps(_ timestamps: [RecipeTimestamp]) -> [RecipeTimestamp] {
        guard timestamps.count > 1 else { return timestamps }

        var result = timestamps.sorted { $0.startTime < $1.startTime }

        for i in 0..<(result.count - 1) {
            if result[i].endTime > result[i + 1].startTime {
                let midpoint = (result[i].endTime + result[i + 1].startTime) / 2
                result[i] = RecipeTimestamp(
                    id: result[i].id,
                    recipeStepId: result[i].recipeStepId,
                    stepIndex: result[i].stepIndex,
                    startTime: result[i].startTime,
                    endTime: midpoint,
                    triggerPhrase: result[i].triggerPhrase,
                    confidence: result[i].confidence
                )
                result[i + 1] = RecipeTimestamp(
                    id: result[i + 1].id,
                    recipeStepId: result[i + 1].recipeStepId,
                    stepIndex: result[i + 1].stepIndex,
                    startTime: midpoint,
                    endTime: result[i + 1].endTime,
                    triggerPhrase: result[i + 1].triggerPhrase,
                    confidence: result[i + 1].confidence
                )
            }
        }

        return result
    }
}
