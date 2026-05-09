import Foundation

// MARK: - Supporting Types (Stubs for compilation)

/// Represents a recipe with steps to be synced to video.
/// In the full Cooksy app, this is a full SwiftData model.
struct Recipe: Identifiable, Sendable {
    let id: UUID
    let title: String
    let steps: [RecipeStep]
}

/// A single step in a recipe.
/// In the full Cooksy app, this is part of the Recipe model.
struct RecipeStep: Identifiable, Sendable {
    let id: UUID
    let index: Int
    let instruction: String
    let ingredients: [String]
}

/// Supported video source platforms.
enum SourcePlatform: String, Codable, Sendable, CaseIterable {
    case youtube
    case tiktok
    case instagram
}

/// Cooksy-specific errors.
enum CooksyError: Error, Sendable {
    case unknown
    case networkFailure(underlying: Error)
    case transcriptionFailed(reason: String)
    case invalidVideoURL
    case syncMapNotFound
    case cacheFailure
    case whisperAPIFailure(statusCode: Int, message: String)
    case noMatchingStepsFound
}

// MARK: - TimestampExtractionService

/// Extracts timestamps from a video by transcribing audio and matching
/// recipe steps to spoken phrases.
///
/// In production: Uses OpenAI Whisper API for transcription with word-level timestamps,
/// then NLP matching to map spoken phrases to recipe steps.
/// For MVP: Returns mock data or simple heuristic-based timestamps.
@Observable
@MainActor
final class TimestampExtractionService {

    // MARK: - Dependencies

    private let apiKey: String
    private let cache: SyncMapCache
    private let session: URLSession

    // MARK: - Initialization

    /// Creates a new TimestampExtractionService.
    /// - Parameters:
    ///   - apiKey: OpenAI API key for Whisper transcription
    ///   - cache: Cache layer for persisting sync maps (defaults to in-memory)
    ///   - session: URLSession for network requests
    init(
        apiKey: String = "",
        cache: SyncMapCache = InMemorySyncMapCache(),
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.cache = cache
        self.session = session
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

        // 2. Production path: Transcribe and match
        //    For now, simulate processing delay and return mock data
        // TODO: Replace with real Whisper transcription + NLP matching
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let syncMap = RecipeSyncMap.mock(for: recipe.id.uuidString)

        // 3. Cache the result
        try? await cache.save(syncMap)

        return syncMap
    }

    /// Extract timestamps using the full production pipeline:
    /// download audio → Whisper transcription → NLP matching.
    func extractTimestampsProduction(
        for recipe: Recipe,
        videoUrl: String,
        videoDuration: TimeInterval
    ) async throws -> RecipeSyncMap {

        // Check cache
        if let cached = try? await cache.load(for: recipe.id.uuidString) {
            return cached
        }

        // Step 1: Download video audio track
        let audioURL = try await downloadAudioTrack(from: videoUrl)

        // Step 2: Transcribe with Whisper (word-level timestamps)
        let transcription = try await transcribeWithWhisper(audioUrl: audioURL)

        // Step 3: Match recipe steps to transcription
        let timestamps = matchStepsToTranscription(
            steps: recipe.steps,
            transcription: transcription,
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

    // MARK: - Private: Production Pipeline

    private func downloadAudioTrack(from videoUrl: String) async throws -> URL {
        // TODO: Implement audio extraction using AVAssetExportSession
        // or a backend service that extracts audio from video
        throw CooksyError.unknown
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

// MARK: - Whisper API Integration

/// OpenAI Whisper API response structure (word-level timestamps)
struct WhisperTranscription: Codable, Sendable {
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

// MARK: - Whisper API + NLP Matching

extension TimestampExtractionService {

    /// Production: Call OpenAI Whisper API for word-level transcription.
    ///
    /// Endpoint: POST https://api.openai.com/v1/audio/transcriptions
    /// Model: whisper-1
    /// Required parameter: `timestamp_granularities[]=word`
    func transcribeWithWhisper(audioUrl: URL) async throws -> WhisperTranscription {
        guard !apiKey.isEmpty else {
            throw CooksyError.transcriptionFailed(reason: "API key not configured")
        }

        let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Build multipart form data
        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        // File
        let audioData = try Data(contentsOf: audioUrl)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)

        // Word-level timestamps
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp_granularities[]\"\r\n\r\n".data(using: .utf8)!)
        body.append("word\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.transcriptionFailed(reason: "Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CooksyError.whisperAPIFailure(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try JSONDecoder().decode(WhisperTranscription.self, from: data)
    }

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
        transcription: WhisperTranscription,
        videoDuration: TimeInterval
    ) -> [RecipeTimestamp] {

        // Collect all words from transcription
        let allWords: [WhisperTranscription.Word]
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
