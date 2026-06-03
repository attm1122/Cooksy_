import Foundation
import SwiftUI
import SwiftData

// MARK: - HomeViewModel
/// Manages the Home screen: URL input, import orchestration, and the "recently saved" list.
///
/// ## Dependencies
/// - `SupabaseProtocol` — for network operations (import, fetching recipes).
/// - `ModelContext` — for SwiftData persistence of imported recipes.
///
/// ## Usage
/// Configure with dependencies before calling `importRecipe()` or `loadRecipes()`:
/// ```swift
/// let vm = HomeViewModel()
/// vm.configure(supabase: supabase, modelContext: modelContext, importService: importService)
/// ```
@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Dependencies

    private var supabase: (any SupabaseProtocol)?
    private var modelContext: ModelContext?
    private var importService: ImportService?

    // MARK: - UI State

    /// The video URL entered by the user.
    var sourceUrl: String = ""

    /// Error message for the URL field (validation or import failure).
    var urlError: String? = nil

    /// The recipe that was just successfully imported, for the completion banner.
    var completedRecipe: Recipe? = nil

    /// Controls visibility of the completion banner.
    var showCompletionBanner: Bool = false

    /// Recently saved recipes (from SwiftData or server).
    var recipes: [Recipe] = []

    // MARK: - Computed

    /// The user's first name for personalized greetings (securely from Keychain).
    var userFirstName: String {
        KeychainService.shared.firstName ?? ""
    }

    /// Time-aware greeting: "Good morning", "Good afternoon", or "Good evening".
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// Whether an import is currently in flight.
    var isImporting: Bool {
        importService?.isImporting ?? false
    }

    /// Whether the import button should be enabled.
    var canImport: Bool {
        !sourceUrl.isEmpty && !isImporting
    }

    // MARK: - Configuration

    /// Injects dependencies. Must be called before any business-logic methods.
    func configure(
        supabase: any SupabaseProtocol,
        modelContext: ModelContext,
        importService: ImportService
    ) {
        self.supabase = supabase
        self.modelContext = modelContext
        self.importService = importService
        importService.configure(supabase: supabase, modelContext: modelContext)
    }

    // MARK: - Import

    /// Validates the URL and kicks off the import pipeline.
    func importRecipe() async {
        urlError = nil

        guard !sourceUrl.isEmpty else {
            urlError = "Please enter a recipe URL."
            return
        }

        guard Validators.isSupportedURL(sourceUrl) else {
            urlError = "Please enter a valid link from YouTube, TikTok, or Instagram."
            return
        }

        // Network connectivity check — prevent import attempts when offline
        guard NetworkMonitor.shared.isConnected else {
            urlError = "No internet connection. Please check your network and try again."
            HapticsService.play(.error)
            return
        }

        guard let importService = importService else {
            urlError = "Import service not configured."
            return
        }

        HapticsService.play(.medium)

        await importService.importRecipe(url: sourceUrl)

        switch importService.progress {
        case .completed(let recipe):
            recipes.insert(recipe, at: 0)
            completedRecipe = recipe
            showCompletionBanner = true
            sourceUrl = ""
            HapticsService.play(.success)
            ReviewPromptService.shared.recordSuccessfulImport()

        case .failed(let error):
            urlError = error.localizedDescription
            HapticsService.play(.error)

        default:
            break
        }
    }

    /// Dismisses the recipe completion banner.
    func dismissCompletion() {
        withAnimation(.spring(duration: 0.35)) {
            showCompletionBanner = false
            completedRecipe = nil
        }
    }

    // MARK: - Load Recipes

    /// Loads recipes from SwiftData first, then syncs from the server.
    func loadRecipes() async {
        // 1. Load from SwiftData (fast, local)
        await loadFromSwiftData()

        // 2. Sync from server (background refresh)
        await syncFromServer()
    }

    /// Loads recipes from the local SwiftData store.
    private func loadFromSwiftData() async {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)]
        )

        do {
            let localRecipes = try modelContext.fetch(descriptor)
            if !localRecipes.isEmpty {
                recipes = localRecipes
            }
        } catch {
            // Silently fail — local data is a cache, not critical
        }
    }

    /// Fetches fresh recipes from Supabase and merges them into SwiftData.
    private func syncFromServer() async {
        guard let supabase = supabase, let modelContext = modelContext else { return }

        do {
            let serverRecipes = try await supabase.fetchRecipes()
            // Merge server recipes into local store (upsert)
            for dto in serverRecipes {
                let id = UUID(uuidString: dto.id)
                let existing = recipes.first(where: { $0.id == id })
                if existing == nil {
                    let recipe = dto.toModel(context: modelContext)
                    modelContext.insert(recipe)
                }
            }
            try modelContext.save()
            // Refresh local list after merge
            let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor<Recipe>(\.createdAt, order: .reverse)])
            recipes = try modelContext.fetch(descriptor)
        } catch {
            // Silently fail — server sync is a background refresh
        }
    }
}
