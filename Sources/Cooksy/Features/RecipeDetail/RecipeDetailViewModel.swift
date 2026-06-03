import Foundation
import SwiftData

// MARK: - RecipeDetailViewModel
/// View model for the recipe detail screen.
///
/// Manages the display state of a recipe, including navigation to cooking mode and edit flows,
/// as well as user interactions like toggling the saved state and checking off ingredients.
///
/// ## SwiftData Integration
/// Changes to `isSaved` and ingredient `isChecked` states are persisted immediately
/// via the injected `ModelContext`.
@Observable
@MainActor
final class RecipeDetailViewModel {

    // MARK: - Dependencies

    private let supabase: (any SupabaseProtocol)?
    private let modelContext: ModelContext?

    // MARK: - State

    /// The recipe being displayed. This is a reference to the shared Core `Recipe` model.
    var recipe: Recipe

    /// Whether the cooking mode full-screen presentation is active.
    var showCookingMode: Bool = false

    /// Whether the cook-along video sync sheet is active.
    var showCookAlong: Bool = false

    /// Whether the edit sheet is presented.
    var showEditSheet: Bool = false

    /// Whether the share sheet is presented.
    var showShareSheet: Bool = false

    /// The items to share via `UIActivityViewController`.
    /// Populated by `prepareShare()` before the sheet is presented.
    var shareItems: [Any] = []

    // MARK: - Initialization

    /// Creates a new view model for the given recipe.
    /// - Parameters:
    ///   - recipe: The `Recipe` to display and interact with.
    ///   - supabase: The Supabase service for remote operations. Defaults to `nil`.
    ///   - modelContext: The SwiftData context for persisting changes. Defaults to `nil`.
    init(
        recipe: Recipe,
        supabase: (any SupabaseProtocol)? = nil,
        modelContext: ModelContext? = nil
    ) {
        self.recipe = recipe
        self.supabase = supabase
        self.modelContext = modelContext
    }

    // MARK: - Actions

    /// Toggles the saved/bookmarked state of the recipe and persists to SwiftData.
    ///
    /// Triggers a success haptic when saving, a light haptic when unsaving,
    /// and touches the recipe's `updatedAt` timestamp.
    func toggleSave() {
        recipe.isSaved.toggle()
        recipe.touch()
        HapticsService.play(recipe.isSaved ? .success : .light)

        do {
            try modelContext?.save()
        } catch {
            // Revert on persistence failure
            recipe.isSaved.toggle()
        }
    }

    /// Toggles the checked state of an ingredient and persists to SwiftData.
    /// - Parameter ingredient: The `Ingredient` to toggle. Must belong to this recipe.
    func toggleIngredient(_ ingredient: Ingredient) {
        ingredient.isChecked.toggle()
        recipe.touch()
        HapticsService.light()

        do {
            try modelContext?.save()
        } catch {
            // Revert on failure
            ingredient.isChecked.toggle()
        }
    }

    /// Opens the cooking mode full-screen experience.
    ///
    /// Sets `showCookingMode` to `true` and triggers a medium haptic.
    func startCooking() {
        HapticsService.medium()
        showCookingMode = true
    }

    /// Opens the cook-along video sync experience.
    ///
    /// Sets `showCookAlong` to `true` and triggers a medium haptic.
    func startCookAlong() {
        HapticsService.medium()
        showCookAlong = true
    }

    /// Opens the recipe edit sheet.
    ///
    /// Sets `showEditSheet` to `true`.
    func editRecipe() {
        showEditSheet = true
    }

    /// Prepares share items and presents the system share sheet.
    ///
    /// Generates a shareable text + URL combination and triggers a medium haptic.
    /// Call this from the share button in the UI.
    func prepareShare() {
        HapticsService.medium()
        let text = "Check out this recipe on Cooksy: \(recipe.title)"
        let url = URL(string: DeepLinkService.recipeWebLink(recipeId: recipe.id.uuidString))!
        shareItems = [text, url]
        showShareSheet = true
    }

    /// Deletes the recipe from SwiftData (cascades to ingredients and steps).
    /// - Returns: `true` if deletion succeeded.
    func deleteRecipe() -> Bool {
        guard let modelContext = modelContext else { return false }
        modelContext.delete(recipe)
        do {
            try modelContext.save()
            return true
        } catch {
            return false
        }
    }
}
