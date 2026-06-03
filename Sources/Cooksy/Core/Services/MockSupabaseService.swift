import Foundation

// MARK: - MockSupabaseService
/// A mock implementation of `SupabaseProtocol` for SwiftUI previews and unit tests.
///
/// All network operations are replaced with deterministic, instant (or fast) responses.
/// Auth operations simulate a single hardcoded user; recipe and import methods return
/// empty or predictable results.
///
/// ## Usage
/// ```swift
/// #Preview {
///     HomeView()
///         .environment(\.supabase, MockSupabaseService())
/// }
/// ```
@Observable
@MainActor
final class MockSupabaseService: SupabaseProtocol {

    // MARK: - Configuration

    /// Delay for simulated network operations (nanoseconds). Default = 0.3s.
    var simulatedDelayNanoseconds: UInt64 = 300_000_000

    /// Whether `signInWithOTP` should throw a network error. Default = `false`.
    var shouldFailAuth: Bool = false

    // MARK: - State

    /// The currently signed-in user. Starts as `nil` (not authenticated).
    private(set) var currentUser: User? = nil

    // MARK: - Auth

    func signInWithOTP(email: String) async throws {
        if shouldFailAuth {
            throw CooksyError.networkError(URLError(.notConnectedToInternet))
        }
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        // Simulate "email sent" — no state change until verifyOTP.
    }

    func verifyOTP(email: String, token: String) async throws -> User {
        if shouldFailAuth {
            throw CooksyError.unauthorized
        }
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        let user = User(
            id: "mock-user-\(email.hashValue)",
            email: email,
            createdAt: Date().addingTimeInterval(-86400 * 30)
        )
        currentUser = user
        KeychainService.shared.userEmail = email
        return user
    }

    func signOut() async throws {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        currentUser = nil
        KeychainService.shared.clearAll()
    }

    func deleteAccount() async throws {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        currentUser = nil
        KeychainService.shared.clearAll()
        // In mock mode, account deletion simulates success
    }

    // MARK: - Push Notifications

    func registerPushToken(_ token: String) async throws {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        // Mock: token "registered" successfully
    }

    func unregisterPushToken(_ token: String) async throws {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        // Mock: token "unregistered" successfully
    }

    // MARK: - Content Moderation

    func submitContentReport(recipeId: String, reason: String, details: String?) async throws {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        #if DEBUG
        print("[MockSupabaseService] Content report submitted: recipe=\(recipeId), reason=\(reason)")
        #endif
    }

    // MARK: - Recipes

    func fetchRecipes() async throws -> [RecipeDTO] {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        return []
    }

    // MARK: - Import

    func importRecipe(url: String) async throws -> ImportJobResponse {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        return ImportJobResponse(
            jobId: "mock-job-\(UUID().uuidString.prefix(8))",
            status: .processing,
            recipe: nil
        )
    }

    func checkImportStatus(jobId: String) async throws -> ImportStatusResponse {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        // Simulate progression: first call returns processing, subsequent calls return ready.
        // For the mock, we always return ready with a sample recipe after the first check.
        return ImportStatusResponse(
            jobId: jobId,
            status: .ready,
            recipe: createMockRecipeDTO(),
            message: "Recipe extracted successfully"
        )
    }

    func completeImport(jobId: String) async throws -> RecipeDTO {
        try await Task.sleep(nanoseconds: simulatedDelayNanoseconds * 2)
        return createMockRecipeDTO()
    }

    // MARK: - Helpers

    private func createMockRecipeDTO() -> RecipeDTO {
        RecipeDTO(
            id: UUID().uuidString,
            title: "Creamy Garlic Parmesan Pasta",
            heroNote: "A rich and creamy pasta dish ready in 20 minutes",
            servings: 4,
            prepTimeMinutes: 5,
            cookTimeMinutes: 15,
            totalTimeMinutes: 20,
            status: "ready",
            confidence: "high",
            confidenceScore: 92,
            confidenceNote: "High confidence recipe with clear instructions",
            isSaved: true,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            importJobId: nil,
            processingMessage: nil,
            sourceUrl: "https://youtube.com/watch?v=mock",
            sourcePlatform: "youtube",
            sourceCreator: "Chef John",
            sourceTitle: "Easy Pasta Recipe",
            ingredients: [
                IngredientDTO(id: UUID().uuidString, name: "Spaghetti", quantity: "400", unit: "g", isChecked: false, displayOrder: 0),
                IngredientDTO(id: UUID().uuidString, name: "Garlic", quantity: "4", unit: "cloves", isChecked: false, displayOrder: 1),
                IngredientDTO(id: UUID().uuidString, name: "Heavy cream", quantity: "200", unit: "ml", isChecked: false, displayOrder: 2),
                IngredientDTO(id: UUID().uuidString, name: "Parmesan cheese", quantity: "100", unit: "g", isChecked: false, displayOrder: 3),
                IngredientDTO(id: UUID().uuidString, name: "Butter", quantity: "2", unit: "tbsp", isChecked: false, displayOrder: 4)
            ],
            steps: [
                RecipeStepDTO(id: UUID().uuidString, title: "Boil the pasta", instruction: "Bring a large pot of salted water to a boil. Add the spaghetti and cook according to package directions until al dente.", durationMinutes: 10, displayOrder: 0),
                RecipeStepDTO(id: UUID().uuidString, title: "Make the sauce", instruction: "While pasta cooks, melt butter in a large pan over medium heat. Add minced garlic and saute for 1 minute until fragrant.", durationMinutes: 3, displayOrder: 1),
                RecipeStepDTO(id: UUID().uuidString, title: "Add cream and cheese", instruction: "Pour in heavy cream and bring to a gentle simmer. Add grated Parmesan and stir until melted and smooth.", durationMinutes: 3, displayOrder: 2),
                RecipeStepDTO(id: UUID().uuidString, title: "Combine", instruction: "Drain pasta, reserving 1/2 cup pasta water. Add pasta to the sauce, tossing to coat.", durationMinutes: 2, displayOrder: 3),
                RecipeStepDTO(id: UUID().uuidString, title: "Serve", instruction: "Season with salt and pepper. Serve immediately with extra Parmesan on top.", durationMinutes: nil, displayOrder: 4)
            ]
        )
    }
}
