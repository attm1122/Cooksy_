import SwiftUI
import SwiftData

// MARK: - RecipeEditViewModel

/// View model for the recipe edit screen.
///
/// Manages editable copies of the recipe's fields, handles adding and removing
/// ingredients and steps, and persists changes back to SwiftData via `ModelContext`.
///
/// ## SwiftData Integration
/// Changes are committed to the `ModelContext` on `save()`, ensuring all edits
/// persist across app launches.
@Observable
@MainActor
final class RecipeEditViewModel {

    // MARK: - Dependencies

    /// The SwiftData context for persisting changes.
    private let modelContext: ModelContext?

    // MARK: - State

    /// The recipe being edited. Changes are written directly to this model instance.
    var recipe: Recipe

    /// Working copy of ingredients for editing.
    var ingredients: [Ingredient]

    /// Working copy of steps for editing.
    var steps: [RecipeStep]

    /// Whether there are unsaved changes.
    var hasChanges: Bool = false

    // MARK: - Initialization

    /// Creates a new edit view model for the given recipe.
    /// - Parameter recipe: The `Recipe` to edit.
    init(recipe: Recipe) {
        self.recipe = recipe
        self.modelContext = nil
        // Create working copies from the recipe's sorted collections
        self.ingredients = recipe.sortedIngredients
        self.steps = recipe.sortedSteps
    }

    /// Injects the SwiftData `ModelContext` after initialization.
    /// Called by the view's `.task` modifier when the environment is available.
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Ingredient Management

    /// Adds a new empty ingredient to the list.
    func addIngredient() {
        let newOrder = ingredients.count
        let ingredient = Ingredient(
            name: "",
            displayOrder: newOrder
        )
        ingredients.append(ingredient)
        hasChanges = true
        HapticsService.light()
    }

    /// Removes an ingredient at the given index set.
    /// - Parameter offsets: The index set to remove.
    func removeIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        reassignIngredientOrders()
        hasChanges = true
    }

    /// Moves an ingredient from one position to another.
    /// - Parameters:
    ///   - source: The source index set.
    ///   - destination: The destination index.
    func moveIngredient(from source: IndexSet, to destination: Int) {
        ingredients.move(fromOffsets: source, toOffset: destination)
        reassignIngredientOrders()
        hasChanges = true
    }

    private func reassignIngredientOrders() {
        for (index, ingredient) in ingredients.enumerated() {
            ingredient.displayOrder = index
        }
    }

    // MARK: - Step Management

    /// Adds a new empty step to the list.
    func addStep() {
        let newOrder = steps.count
        let step = RecipeStep(
            title: "",
            instruction: "",
            displayOrder: newOrder
        )
        steps.append(step)
        hasChanges = true
        HapticsService.light()
    }

    /// Removes a step at the given index set.
    /// - Parameter offsets: The index set to remove.
    func removeStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        reassignStepOrders()
        hasChanges = true
    }

    /// Moves a step from one position to another.
    /// - Parameters:
    ///   - source: The source index set.
    ///   - destination: The destination index.
    func moveStep(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)
        reassignStepOrders()
        hasChanges = true
    }

    private func reassignStepOrders() {
        for (index, step) in steps.enumerated() {
            step.displayOrder = index
        }
    }

    // MARK: - Save

    /// Persists the edited fields back to the recipe and saves to SwiftData.
    ///
    /// Updates the recipe's `ingredients` and `steps` relationships with
    /// the working copies, calls `recipe.touch()`, and commits to `ModelContext`.
    func save() {
        recipe.ingredients = ingredients
        recipe.steps = steps
        recipe.touch()
        hasChanges = false
        HapticsService.success()

        // Persist to SwiftData if a context is available
        do {
            try modelContext?.save()
        } catch {
            // Handle save failure — could show an alert
            // But don't revert the changes; the user can retry
        }
    }
}
