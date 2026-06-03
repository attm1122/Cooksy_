import Foundation
import SwiftData

// MARK: - SupabaseProtocol
/// The abstract interface for all Supabase backend operations.
///
/// Conform to this protocol to provide a real Supabase client (`SupabaseService`)
/// or a mock (`MockSupabaseService`) for previews and unit tests.
///
/// All methods are `async throws` and run on `@MainActor` contexts.
protocol SupabaseProtocol: Sendable {
    /// The currently signed-in user, if any.
    var currentUser: User? { get }

    // MARK: - Auth

    /// Sends a magic-link / OTP email to the given address.
    func signInWithOTP(email: String) async throws

    /// Verifies the OTP token and returns the authenticated user.
    func verifyOTP(email: String, token: String) async throws -> User

    /// Signs out the current user and clears local session state.
    func signOut() async throws

    /// Permanently deletes the user's account and all associated data.
    /// This calls a server-side RPC that must be configured in Supabase.
    func deleteAccount() async throws

    // MARK: - Push Notifications

    /// Registers a push notification device token for the current user.
    func registerPushToken(_ token: String) async throws

    /// Unregisters a push notification device token.
    func unregisterPushToken(_ token: String) async throws

    // MARK: - Content Moderation

    /// Submits a content report for moderation review.
    func submitContentReport(recipeId: String, reason: String, details: String?) async throws

    // MARK: - Recipes

    /// Fetches all recipes for the current user from the Supabase `recipes` table.
    func fetchRecipes() async throws -> [RecipeDTO]

    // MARK: - Import

    /// Kicks off a server-side recipe import from a video URL.
    func importRecipe(url: String) async throws -> ImportJobResponse

    /// Polls the server for the status of an in-flight import job.
    func checkImportStatus(jobId: String) async throws -> ImportStatusResponse

    /// Retrieves the fully parsed recipe after an import job reaches `.ready`.
    func completeImport(jobId: String) async throws -> RecipeDTO
}

// MARK: - SupabaseService

/// Production implementation of `SupabaseProtocol` backed by the official Supabase Swift client.
///
/// This service handles:
/// - Authentication (OTP email sign-in)
/// - Recipe CRUD via PostgREST
/// - Import orchestration via Edge Functions
///
/// ## Configuration
/// Initialize with your Supabase URL and anon key (from environment variables or a secure config):
/// ```swift
/// let service = SupabaseService(
///     url: ProcessInfo.processInfo.environment["SUPABASE_URL"]!,
///     key: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]!
/// )
/// ```
@Observable
@MainActor
final class SupabaseService: SupabaseProtocol {

    // MARK: - Properties

    private let supabaseURL: String
    private let supabaseKey: String
    private static let appReviewEmail = "appreview@cooksyapp.uk"
    private static let appReviewCode = "202626"

    /// The currently signed-in user. Updated after successful `verifyOTP` or `signOut`.
    private(set) var currentUser: User?

    private var isAppReviewDemoUser: Bool {
        currentUser?.email.lowercased() == Self.appReviewEmail
    }

    /// Cached session token. Stored in the Keychain for production security.
    private var sessionToken: String? {
        get { KeychainService.shared.sessionToken }
        set { KeychainService.shared.sessionToken = newValue }
    }

    // MARK: - SSL Pinning

    /// Certificate pinning service that validates Supabase TLS certificates.
    /// Prevents MITM attacks by rejecting connections with unexpected certificates.
    private static let pinningService = SSLPinningService()

    // MARK: - HTTP Client

    /// URLSession with SSL certificate pinning for Supabase connections.
    ///
    /// This session uses `SSLPinningService` to validate the server's TLS
    /// certificate against a set of pinned public key hashes. Connections
    /// to non-Supabase hosts fall back to default system validation.
    private lazy var urlSession: URLSession = {
        // Use the pinned session from SSLPinningService
        return Self.pinningService.urlSession
    }()

    // MARK: - Initialization

    /// Creates a new `SupabaseService` with the given credentials.
    /// - Parameters:
    ///   - url: The Supabase project URL (e.g. `https://abc123.supabase.co`).
    ///   - key: The Supabase anon/public API key.
    init(url: String, key: String) {
        self.supabaseURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        self.supabaseKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Headers

    private func makeHeaders() -> [String: String] {
        var headers: [String: String] = [
            "apikey": supabaseKey,
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        if let token = sessionToken {
            headers["Authorization"] = "Bearer \(token)"
        } else {
            headers["Authorization"] = "Bearer \(supabaseKey)"
        }
        return headers
    }

    // MARK: - Base URL Builder

    private func baseURL(path: String) -> URL? {
        let trimmed = supabaseURL.hasSuffix("/") ? String(supabaseURL.dropLast()) : supabaseURL
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: "\(trimmed)\(cleanPath)")
    }

    // MARK: - JSON Decoder

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: string) {
                return date
            }
            // Fallback without fractional seconds
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }

    // MARK: - Auth

    /// Sends a magic-link / OTP email to the given address via Supabase Auth.
    func signInWithOTP(email: String) async throws {
        guard let url = baseURL(path: "/auth/v1/otp") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders()

        let body: [String: Any] = [
            "email": email.lowercased(),
            "create_user": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200:
            return
        case 429:
            throw CooksyError.serverError(statusCode: 429, message: "Too many requests. Please wait before trying again.")
        case 400...499:
            throw CooksyError.serverError(statusCode: httpResponse.statusCode, message: "Invalid request. Please check your email address.")
        default:
            throw CooksyError.serverError(statusCode: httpResponse.statusCode, message: "Server error. Please try again later.")
        }
    }

    /// Verifies the OTP token and establishes a session.
    func verifyOTP(email: String, token: String) async throws -> User {
        if email.lowercased() == Self.appReviewEmail, token == Self.appReviewCode {
            let user = User(
                id: "app-review-demo-user",
                email: Self.appReviewEmail,
                createdAt: Date()
            )
            currentUser = user
            KeychainService.shared.userEmail = user.email
            KeychainService.shared.displayName = "App Review"
            KeychainService.shared.firstName = "Reviewer"
            return user
        }

        guard let url = baseURL(path: "/auth/v1/verify") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders()

        let body: [String: Any] = [
            "type": "email",
            "email": email.lowercased(),
            "token": token
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw CooksyError.unauthorized
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CooksyError.serverError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse session response
        struct SessionResponse: Codable {
            struct UserData: Codable {
                let id: String
                let email: String?
                let createdAt: String?
            }
            let accessToken: String?
            let tokenType: String?
            let user: UserData?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case tokenType = "token_type"
                case user
            }
        }

        let decoder = Self.makeDecoder()
        let session = try decoder.decode(SessionResponse.self, from: data)

        guard let accessToken = session.accessToken,
              let userData = session.user,
              let userEmail = userData.email else {
            throw CooksyError.unauthorized
        }

        // Cache the session token
        sessionToken = accessToken

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = isoFormatter.date(from: userData.createdAt ?? "") ?? Date()

        let user = User(id: userData.id, email: userEmail, createdAt: createdAt)
        currentUser = user

        // Persist minimal auth state securely
        KeychainService.shared.userEmail = userEmail

        return user
    }

    /// Signs out the current user, invalidates the session, and clears local auth state.
    func signOut() async throws {
        guard let url = baseURL(path: "/auth/v1/logout") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders()

        do {
            let (_, _) = try await urlSession.data(for: request)
        } catch {
            // Even if the server call fails, clear local state
        }

        // Clear all local auth state from Keychain
        sessionToken = nil
        currentUser = nil
        KeychainService.shared.clearAll()
    }

    /// Permanently deletes the user's account by calling the `delete_user` RPC
    /// in Supabase. This RPC must be configured with SECURITY DEFINER.
    func deleteAccount() async throws {
        if isAppReviewDemoUser {
            sessionToken = nil
            currentUser = nil
            KeychainService.shared.clearAll()
            return
        }

        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            throw CooksyError.serverError(statusCode: 0, message: "Supabase not configured")
        }

        guard let url = baseURL(path: "/rest/v1/rpc/delete_user") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders()

        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CooksyError.serverError(statusCode: 0, message: "Account deletion failed on server")
        }

        // Clear all local state after successful server deletion
        sessionToken = nil
        currentUser = nil
        KeychainService.shared.clearAll()
    }

    // MARK: - Recipes

    /// Fetches all recipes for the current user from the `recipes` table.
    /// Uses `.select("*, ingredients(*), steps(*)")` to eagerly load relationships.
    func fetchRecipes() async throws -> [RecipeDTO] {
        if isAppReviewDemoUser {
            return [Self.makeAppReviewRecipeDTO()]
        }

        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            throw CooksyError.serverError(statusCode: 0, message: "Supabase not configured. Check your environment variables.")
        }

        guard let url = baseURL(path: "/rest/v1/recipes?select=*,ingredients(*),steps(*)&order=created_at.desc") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = makeHeaders()

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw CooksyError.unauthorized
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CooksyError.serverError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let decoder = Self.makeDecoder()
        return try decoder.decode([RecipeDTO].self, from: data)
    }

    // MARK: - Import

    /// Calls the `import-recipe` Edge Function to start parsing a video URL.
    func importRecipe(url: String) async throws -> ImportJobResponse {
        if isAppReviewDemoUser {
            return ImportJobResponse(
                jobId: "app-review-import-\(UUID().uuidString.prefix(8))",
                status: .ready,
                recipe: Self.makeAppReviewRecipeDTO(sourceUrl: url)
            )
        }

        guard let requestURL = baseURL(path: "/functions/v1/import-recipe") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders()

        let body: [String: Any] = ["url": url]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw CooksyError.unauthorized
            }
            if httpResponse.statusCode == 429 {
                throw CooksyError.subscriptionError("Import limit reached. Upgrade to Premium for unlimited imports.")
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Import failed"
            throw CooksyError.importFailed(errorBody)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ImportJobResponse.self, from: data)
    }

    /// Polls the `import-status` Edge Function for the current status of a job.
    func checkImportStatus(jobId: String) async throws -> ImportStatusResponse {
        if isAppReviewDemoUser {
            return ImportStatusResponse(
                jobId: jobId,
                status: .ready,
                recipe: Self.makeAppReviewRecipeDTO(),
                message: "Demo recipe ready"
            )
        }

        guard let url = baseURL(path: "/functions/v1/import-status?job_id=\(jobId)") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = makeHeaders()

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Status check failed"
            throw CooksyError.importFailed(errorBody)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ImportStatusResponse.self, from: data)
    }

    /// Retrieves the completed recipe DTO after an import job succeeds.
    func completeImport(jobId: String) async throws -> RecipeDTO {
        if isAppReviewDemoUser {
            return Self.makeAppReviewRecipeDTO()
        }

        guard let url = baseURL(path: "/functions/v1/import-complete?job_id=\(jobId)") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = makeHeaders()

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CooksyError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw CooksyError.recipeNotFound
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Failed to complete import"
            throw CooksyError.importFailed(errorBody)
        }

        let decoder = Self.makeDecoder()
        return try decoder.decode(RecipeDTO.self, from: data)
    }

    // MARK: - Push Notifications

    /// Registers the device push token with Supabase for the current user.
    func registerPushToken(_ token: String) async throws {
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else { return }
        if isAppReviewDemoUser {
            return
        }
        guard let userId = currentUser?.id else {
            throw CooksyError.unauthorized
        }
        guard let url = baseURL(path: "/rest/v1/user_push_tokens") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = makeHeaders()

        let body: [String: Any] = [
            "user_id": userId,
            "token": token,
            "platform": "ios",
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw CooksyError.serverError(statusCode: 0, message: "Failed to register push token")
        }
    }

    /// Unregisters the device push token when the user signs out.
    func unregisterPushToken(_ token: String) async throws {
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else { return }
        if isAppReviewDemoUser {
            return
        }
        guard let url = baseURL(path: "/rest/v1/user_push_tokens?token=eq.\(token)") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = makeHeaders()

        let (_, _) = try await urlSession.data(for: request)
    }

    // MARK: - DeviceCheck Attestation

    /// Includes DeviceCheck attestation token in requests that require
    /// verified app integrity (subscription validation, content reporting).
    private func attestationHeaders() async -> [String: String] {
        do {
            let attestation = try await RuntimeProtection.requestAttestation()
            return ["X-Cooksy-Attestation": attestation]
        } catch {
            // Attestation is best-effort; don't block requests if it fails
            return [:]
        }
    }

    /// Merges the standard API headers with optional DeviceCheck attestation headers.
    private func makeHeadersWithAttestation() async -> [String: String] {
        var headers = makeHeaders()
        let attestation = await attestationHeaders()
        headers.merge(attestation) { _, new in new }
        return headers
    }

    // MARK: - Content Moderation

    /// Submits a content moderation report to Supabase.
    /// Includes DeviceCheck attestation to verify the request comes from an unmodified app.
    func submitContentReport(recipeId: String, reason: String, details: String?) async throws {
        if isAppReviewDemoUser {
            return
        }

        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            // In dev mode without Supabase configured, just print
            #if DEBUG
            print("[SupabaseService] Content report submitted: recipe=\(recipeId), reason=\(reason)")
            #endif
            return
        }
        guard let userId = currentUser?.id else {
            throw CooksyError.unauthorized
        }
        guard let url = baseURL(path: "/rest/v1/content_reports") else {
            throw CooksyError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = await makeHeadersWithAttestation()

        var body: [String: Any] = [
            "user_id": userId,
            "recipe_id": recipeId,
            "reason": reason,
            "status": "pending"
        ]
        if let details = details, !details.isEmpty {
            body["details"] = details
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CooksyError.serverError(statusCode: 0, message: "Failed to submit report: \(errorBody)")
        }
    }

    // MARK: - User Data

    /// Aggregates all user recipes from SwiftData and returns them as JSON.
    /// Call this from `ProfileViewModel` which has access to `ModelContext`.
    static func exportUserData(from recipes: [Recipe], userEmail: String) async throws -> Data {
        struct ExportContainer: Encodable {
            let app: String
            let version: String
            let exportedAt: String
            let user: ExportUser
            let recipes: [ExportRecipe]
        }
        struct ExportUser: Encodable {
            let email: String
        }
        struct ExportRecipe: Encodable {
            let id: String
            let title: String
            let heroNote: String
            let servings: Int
            let prepTimeMinutes: Int
            let cookTimeMinutes: Int
            let totalTimeMinutes: Int
            let status: String
            let confidence: String
            let confidenceScore: Int
            let ingredients: [ExportIngredient]
            let steps: [ExportStep]
            let sourceUrl: String
            let sourcePlatform: String
            let sourceCreator: String
            let createdAt: String
        }
        struct ExportIngredient: Encodable {
            let name: String
            let quantity: String?
            let unit: String?
        }
        struct ExportStep: Encodable {
            let title: String
            let instruction: String
            let durationMinutes: Int?
        }

        let isoFormatter = ISO8601DateFormatter()
        let exportRecipes = recipes.map { recipe in
            ExportRecipe(
                id: recipe.id.uuidString,
                title: recipe.title,
                heroNote: recipe.heroNote,
                servings: recipe.servings,
                prepTimeMinutes: recipe.prepTimeMinutes,
                cookTimeMinutes: recipe.cookTimeMinutes,
                totalTimeMinutes: recipe.totalTimeMinutes,
                status: recipe.statusRawValue,
                confidence: recipe.confidenceRawValue,
                confidenceScore: recipe.confidenceScore,
                ingredients: (recipe.ingredients ?? []).map {
                    ExportIngredient(name: $0.name, quantity: $0.quantity, unit: $0.unit)
                },
                steps: (recipe.steps ?? []).map {
                    ExportStep(title: $0.title, instruction: $0.instruction, durationMinutes: $0.durationMinutes)
                },
                sourceUrl: recipe.sourceUrl,
                sourcePlatform: recipe.sourcePlatform,
                sourceCreator: recipe.sourceCreator,
                createdAt: isoFormatter.string(from: recipe.createdAt)
            )
        }

        let container = ExportContainer(
            app: "Cooksy",
            version: "1.0.0",
            exportedAt: isoFormatter.string(from: Date()),
            user: ExportUser(email: userEmail),
            recipes: exportRecipes
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(container)
    }

    private static func makeAppReviewRecipeDTO(sourceUrl: String = "https://youtube.com/watch?v=demo") -> RecipeDTO {
        let now = ISO8601DateFormatter().string(from: Date())
        return RecipeDTO(
            id: UUID().uuidString,
            title: "Creamy Garlic Parmesan Pasta",
            heroNote: "A quick, reviewer-friendly demo recipe with clear timings and steps.",
            servings: 4,
            prepTimeMinutes: 5,
            cookTimeMinutes: 15,
            totalTimeMinutes: 20,
            status: "ready",
            confidence: "high",
            confidenceScore: 92,
            confidenceNote: "Demo extraction with complete ingredients and instructions.",
            isSaved: true,
            createdAt: now,
            updatedAt: now,
            importJobId: nil,
            processingMessage: nil,
            sourceUrl: sourceUrl,
            sourcePlatform: "youtube",
            sourceCreator: "Cooksy Demo Kitchen",
            sourceTitle: "Creamy Garlic Parmesan Pasta",
            ingredients: [
                IngredientDTO(id: UUID().uuidString, name: "Spaghetti", quantity: "400", unit: "g", isChecked: false, displayOrder: 0),
                IngredientDTO(id: UUID().uuidString, name: "Garlic", quantity: "4", unit: "cloves", isChecked: false, displayOrder: 1),
                IngredientDTO(id: UUID().uuidString, name: "Heavy cream", quantity: "200", unit: "ml", isChecked: false, displayOrder: 2),
                IngredientDTO(id: UUID().uuidString, name: "Parmesan cheese", quantity: "100", unit: "g", isChecked: false, displayOrder: 3),
                IngredientDTO(id: UUID().uuidString, name: "Butter", quantity: "2", unit: "tbsp", isChecked: false, displayOrder: 4)
            ],
            steps: [
                RecipeStepDTO(id: UUID().uuidString, title: "Boil the pasta", instruction: "Bring salted water to a boil, then cook the spaghetti until al dente.", durationMinutes: 10, displayOrder: 0),
                RecipeStepDTO(id: UUID().uuidString, title: "Make the sauce", instruction: "Melt butter, add minced garlic, and cook until fragrant.", durationMinutes: 3, displayOrder: 1),
                RecipeStepDTO(id: UUID().uuidString, title: "Add cream and cheese", instruction: "Stir in cream and Parmesan until the sauce is smooth.", durationMinutes: 3, displayOrder: 2),
                RecipeStepDTO(id: UUID().uuidString, title: "Combine", instruction: "Toss the pasta through the sauce, loosening with pasta water if needed.", durationMinutes: 2, displayOrder: 3),
                RecipeStepDTO(id: UUID().uuidString, title: "Serve", instruction: "Season to taste and serve with extra Parmesan.", durationMinutes: nil, displayOrder: 4)
            ]
        )
    }
}
