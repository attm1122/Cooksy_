import Foundation
import SwiftData

// MARK: - RecipesViewModel
/// Manages the recipes list: loading, filtering, searching, and deletion —
/// all backed by SwiftData with server sync.
///
/// ## Data Flow
/// 1. On `loadRecipes()`: loads from SwiftData first (instant), then syncs from server.
/// 2. `filteredRecipes` is a computed property combining status filter + search query.
/// 3. Deletions cascade through SwiftData (removing ingredients and steps automatically).
@MainActor
@Observable
final class RecipesViewModel {

    // MARK: - Dependencies

    private var supabase: (any SupabaseProtocol)?
    private var modelContext: ModelContext?

    // MARK: - State

    /// All loaded recipes from SwiftData.
    var recipes: [Recipe] = []

    /// Current search query string.
    var searchQuery: String = ""

    /// Selected status filter. `nil` means show all.
    var selectedFilter: RecipeStatus? = nil

    /// Whether recipes are being loaded.
    private(set) var isLoading: Bool = false

    /// Error message if loading failed.
    private(set) var errorMessage: String?

    // MARK: - Computed

    /// Recipes filtered by selected status and search query.
    var filteredRecipes: [Recipe] {
        var result = recipes

        // Filter by status
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }

        // Filter by search query (title, heroNote, source creator/title)
        if !searchQuery.isEmpty {
            let lowercasedQuery = searchQuery.lowercased()
            result = result.filter { recipe in
                let matchesTitle = recipe.title.lowercased().contains(lowercasedQuery)
                let matchesNote = recipe.heroNote.lowercased().contains(lowercasedQuery)
                let matchesSource = recipe.sourceCreator.lowercased().contains(lowercasedQuery)
                    || recipe.sourceTitle.lowercased().contains(lowercasedQuery)
                return matchesTitle || matchesNote || matchesSource
            }
        }

        return result
    }

    // MARK: - Configuration

    /// Injects dependencies. Must be called before `loadRecipes()`.
    func configure(supabase: any SupabaseProtocol, modelContext: ModelContext) {
        self.supabase = supabase
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Loads recipes from SwiftData first, then syncs from the server.
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil

        // 1. Load from local SwiftData (fast)
        await loadFromSwiftData()

        // 2. Sync from server (background refresh)
        await syncFromServer()

        isLoading = false
    }

    /// Fetches recipes from the local SwiftData store.
    private func loadFromSwiftData() async {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)]
        )

        do {
            recipes = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load saved recipes."
        }
    }

    /// Fetches fresh recipes from Supabase and upserts them into SwiftData.
    private func syncFromServer() async {
        guard let supabase = supabase, let modelContext = modelContext else { return }

        do {
            let serverRecipes = try await supabase.fetchRecipes()

            // Upsert: insert only recipes we don't already have locally
            let localIds = Set(recipes.map(\.id.uuidString))
            for dto in serverRecipes where !localIds.contains(dto.id) {
                let recipe = dto.toModel(context: modelContext)
                modelContext.insert(recipe)
            }

            try modelContext.save()

            // Refresh the list after merge
            let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)])
            recipes = try modelContext.fetch(descriptor)
        } catch {
            // Silently fail — server sync is a background refresh.
            // The user still sees locally cached recipes.
        }
    }

    // MARK: - CRUD

    /// Deletes a recipe from SwiftData (cascades to ingredients and steps).
    func deleteRecipe(_ recipe: Recipe) {
        guard let modelContext = modelContext else { return }

        modelContext.delete(recipe)
        recipes.removeAll { $0.id == recipe.id }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete recipe. Please try again."
        }
    }

    /// Toggles the saved/bookmarked state of a recipe in SwiftData.
    func toggleSave(_ recipe: Recipe) {
        recipe.isSaved.toggle()
        recipe.touch()
        HapticsService.play(recipe.isSaved ? .success : .light)

        do {
            try modelContext?.save()
        } catch {
            // Revert on failure
            recipe.isSaved.toggle()
        }
    }
}
