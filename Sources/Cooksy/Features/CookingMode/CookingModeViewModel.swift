import SwiftUI
import SwiftData

// MARK: - CookingModeViewModel

/// View model for the full-screen cooking mode experience.
///
/// Manages the current step index, computes the active step from the recipe's
/// `sortedSteps` array, tracks overall progress, and handles navigation between
/// previous and next steps.
@Observable
final class CookingModeViewModel {

    // MARK: State

    /// The recipe being cooked. Uses the Core `Recipe` model.
    var recipe: Recipe

    /// The index of the currently displayed step in `recipe.sortedSteps`.
    var currentStepIndex: Int = 0

    // MARK: Computed Properties

    /// The currently active step from the recipe's sorted steps array.
    ///
    /// Returns the step at `currentStepIndex` if within bounds, otherwise `nil`.
    var currentStep: RecipeStep? {
        let steps = recipe.sortedSteps
        guard currentStepIndex >= 0, currentStepIndex < steps.count else {
            return nil
        }
        return steps[currentStepIndex]
    }

    /// The overall progress as a fraction from 0.0 to 1.0.
    ///
    /// Calculated as `(currentStepIndex + 1) / totalSteps`.
    var progress: Double {
        let steps = recipe.sortedSteps
        guard !steps.isEmpty else { return 0 }
        return Double(currentStepIndex + 1) / Double(steps.count)
    }

    /// Whether there is a next step available.
    var hasNext: Bool {
        currentStepIndex < recipe.sortedSteps.count - 1
    }

    /// Whether there is a previous step available.
    var hasPrevious: Bool {
        currentStepIndex > 0
    }

    // MARK: Initialization

    /// Creates a new cooking mode view model for the given recipe.
    /// - Parameter recipe: The `Recipe` to cook through.
    init(recipe: Recipe) {
        self.recipe = recipe
    }

    // MARK: Actions

    /// Advances to the next step if available.
    ///
    /// Triggers a success haptic when completing the final step,
    /// and a light haptic for intermediate steps.
    func nextStep() {
        guard hasNext else {
            HapticsService.success()
            return
        }
        currentStepIndex += 1
        HapticsService.light()
    }

    /// Goes back to the previous step if available.
    ///
    /// Triggers a light haptic on success.
    func previousStep() {
        guard hasPrevious else { return }
        currentStepIndex -= 1
        HapticsService.light()
    }

    /// Resets the cooking session back to the first step.
    ///
    /// Triggers a warning haptic to indicate the reset action.
    func restart() {
        currentStepIndex = 0
        HapticsService.warning()
    }
}
