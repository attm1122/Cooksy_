import XCTest
@testable import Cooksy

// MARK: - CookingModeViewModelTests
/// Comprehensive unit tests for the CookingModeViewModel full-screen cooking experience.
///
/// Tests cover step navigation (previous/next/restart), computed properties (currentStep,
/// progress, hasNext, hasPrevious), ingredient state management, and edge cases (empty
/// recipe, single step, boundary conditions).
@MainActor
final class CookingModeViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: CookingModeViewModel!
    private var recipe: Recipe!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        recipe = makeRecipeWithSteps()
        sut = CookingModeViewModel(recipe: recipe)
    }

    override func tearDown() {
        sut = nil
        recipe = nil
        super.tearDown()
    }

    // MARK: - Factory Methods

    private func makeRecipeWithSteps() -> Recipe {
        let recipe = Recipe(
            title: "Cooking Mode Test Recipe",
            servings: 4,
            sourceUrl: "https://youtube.com/watch?v=test",
            sourcePlatform: .youtube,
            sourceCreator: "Test Chef",
            sourceTitle: "Test Video"
        )
        let step1 = RecipeStep(title: "Preheat", instruction: "Preheat oven to 350F", durationMinutes: 15, displayOrder: 0)
        let step2 = RecipeStep(title: "Mix Dry", instruction: "Mix flour and sugar in a bowl", durationMinutes: 5, displayOrder: 1)
        let step3 = RecipeStep(title: "Mix Wet", instruction: "Mix butter and eggs", durationMinutes: 5, displayOrder: 2)
        let step4 = RecipeStep(title: "Combine", instruction: "Combine wet and dry ingredients", durationMinutes: 3, displayOrder: 3)
        let step5 = RecipeStep(title: "Bake", instruction: "Bake for 25 minutes until golden", durationMinutes: 25, displayOrder: 4)
        recipe.steps = [step1, step2, step3, step4, step5]
        return recipe
    }

    private func makeRecipeWithIngredients() -> Recipe {
        let recipe = makeRecipeWithSteps()
        let flour = Ingredient(name: "All-purpose flour", quantity: "2", unit: "cups", displayOrder: 0)
        let sugar = Ingredient(name: "Sugar", quantity: "1", unit: "cup", displayOrder: 1)
        let butter = Ingredient(name: "Butter", quantity: "0.5", unit: "cup", displayOrder: 2)
        let eggs = Ingredient(name: "Eggs", quantity: "2", unit: nil, displayOrder: 3)
        recipe.ingredients = [flour, sugar, butter, eggs]
        return recipe
    }

    private func makeEmptyRecipe() -> Recipe {
        Recipe(
            title: "Empty Recipe",
            servings: 1,
            sourceUrl: "https://youtube.com/watch?v=empty",
            sourcePlatform: .youtube,
            sourceCreator: "Nobody",
            sourceTitle: "Empty"
        )
    }

    private func makeSingleStepRecipe() -> Recipe {
        let recipe = Recipe(
            title: "Single Step Recipe",
            servings: 1,
            sourceUrl: "https://youtube.com/watch?v=single",
            sourcePlatform: .youtube,
            sourceCreator: "Chef",
            sourceTitle: "One Step"
        )
        let step = RecipeStep(title: "Just Do It", instruction: "The only step", durationMinutes: 5, displayOrder: 0)
        recipe.steps = [step]
        return recipe
    }

    // MARK: - Initial State Tests

    func test_initialState_currentStepIndexIsZero() {
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func test_initialState_currentStepIsFirstStep() {
        XCTAssertEqual(sut.currentStep?.title, "Preheat")
    }

    func test_initialState_progress() {
        // 5 steps, at index 0: (0+1)/5 = 0.2
        XCTAssertEqual(sut.progress, 0.2, accuracy: 0.001)
    }

    func test_initialState_hasNext_isTrue() {
        XCTAssertTrue(sut.hasNext)
    }

    func test_initialState_hasPrevious_isFalse() {
        XCTAssertFalse(sut.hasPrevious)
    }

    // MARK: - nextStep Tests

    func test_nextStep_advancesFrom0To1() {
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 1)
        XCTAssertEqual(sut.currentStep?.title, "Mix Dry")
    }

    func test_nextStep_advancesFrom1To2() {
        sut.currentStepIndex = 1
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 2)
        XCTAssertEqual(sut.currentStep?.title, "Mix Wet")
    }

    func test_nextStep_sequentialAdvance() {
        sut.nextStep()
        sut.nextStep()
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 3)
        XCTAssertEqual(sut.currentStep?.title, "Combine")
    }

    func test_nextStep_toLastStep() {
        sut.currentStepIndex = 3
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 4)
        XCTAssertEqual(sut.currentStep?.title, "Bake")
    }

    func test_nextStep_atLastStep_doesNotAdvance() {
        sut.currentStepIndex = 4
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 4)
    }

    func test_nextStep_atLastStep_triggersSuccessHaptic() {
        sut.currentStepIndex = 4
        // nextStep() at last step triggers success haptic
        // This is a behavioral test - we verify it doesn't crash
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 4)
    }

    func test_nextStep_multipleBeyondLast() {
        sut.currentStepIndex = 4
        sut.nextStep()
        sut.nextStep()
        sut.nextStep()
        XCTAssertEqual(sut.currentStepIndex, 4)
    }

    // MARK: - previousStep Tests

    func test_previousStep_from1To0() {
        sut.currentStepIndex = 1
        sut.previousStep()
        XCTAssertEqual(sut.currentStepIndex, 0)
        XCTAssertEqual(sut.currentStep?.title, "Preheat")
    }

    func test_previousStep_from4To3() {
        sut.currentStepIndex = 4
        sut.previousStep()
        XCTAssertEqual(sut.currentStepIndex, 3)
        XCTAssertEqual(sut.currentStep?.title, "Combine")
    }

    func test_previousStep_atFirstStep_doesNotGoBack() {
        sut.currentStepIndex = 0
        sut.previousStep()
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func test_previousStep_multipleBeyondFirst() {
        sut.currentStepIndex = 0
        sut.previousStep()
        sut.previousStep()
        sut.previousStep()
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func test_previousStep_sequentialBack() {
        sut.currentStepIndex = 4
        sut.previousStep()
        sut.previousStep()
        sut.previousStep()
        sut.previousStep()
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    // MARK: - restart Tests

    func test_restart_setsIndexToZero() {
        sut.currentStepIndex = 4
        sut.restart()
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func test_restart_setsIndexToZeroFromAnyIndex() {
        sut.currentStepIndex = 2
        sut.restart()
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func test_restart_afterCompleteNavigation() {
        sut.currentStepIndex = 4
        sut.restart()
        XCTAssertEqual(sut.currentStepIndex, 0)
        XCTAssertEqual(sut.currentStep?.title, "Preheat")
    }

    func test_restart_multipleTimes() {
        sut.currentStepIndex = 3
        sut.restart()
        sut.currentStepIndex = 4
        sut.restart()
        sut.currentStepIndex = 2
        sut.restart()
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    // MARK: - currentStep Computed Property Tests

    func test_currentStep_returnsCorrectStepAtEachIndex() {
        let expectedTitles = ["Preheat", "Mix Dry", "Mix Wet", "Combine", "Bake"]
        for (index, expectedTitle) in expectedTitles.enumerated() {
            sut.currentStepIndex = index
            XCTAssertEqual(sut.currentStep?.title, expectedTitle, "Failed at index \(index)")
        }
    }

    func test_currentStep_returnsNilForNegativeIndex() {
        sut.currentStepIndex = -1
        XCTAssertNil(sut.currentStep)
    }

    func test_currentStep_returnsNilForOutOfBoundsIndex() {
        sut.currentStepIndex = 100
        XCTAssertNil(sut.currentStep)
    }

    func test_currentStep_hasInstruction() {
        sut.currentStepIndex = 0
        XCTAssertFalse(sut.currentStep?.instruction.isEmpty ?? true)
    }

    func test_currentStep_hasDuration() {
        sut.currentStepIndex = 0
        XCTAssertNotNil(sut.currentStep?.durationMinutes)
    }

    // MARK: - progress Computed Property Tests

    func test_progress_atStep0() {
        sut.currentStepIndex = 0
        // (0 + 1) / 5 = 0.2
        XCTAssertEqual(sut.progress, 0.2, accuracy: 0.001)
    }

    func test_progress_atStep1() {
        sut.currentStepIndex = 1
        // (1 + 1) / 5 = 0.4
        XCTAssertEqual(sut.progress, 0.4, accuracy: 0.001)
    }

    func test_progress_atStep2() {
        sut.currentStepIndex = 2
        // (2 + 1) / 5 = 0.6
        XCTAssertEqual(sut.progress, 0.6, accuracy: 0.001)
    }

    func test_progress_atStep3() {
        sut.currentStepIndex = 3
        // (3 + 1) / 5 = 0.8
        XCTAssertEqual(sut.progress, 0.8, accuracy: 0.001)
    }

    func test_progress_atStep4() {
        sut.currentStepIndex = 4
        // (4 + 1) / 5 = 1.0
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.001)
    }

    func test_progress_goesFromZeroToOne() {
        sut.currentStepIndex = 0
        let firstProgress = sut.progress
        sut.currentStepIndex = 4
        let lastProgress = sut.progress
        XCTAssertLessThan(firstProgress, lastProgress)
        XCTAssertGreaterThanOrEqual(firstProgress, 0)
        XCTAssertLessThanOrEqual(lastProgress, 1)
    }

    // MARK: - hasNext Computed Property Tests

    func test_hasNext_atStep0_isTrue() {
        sut.currentStepIndex = 0
        XCTAssertTrue(sut.hasNext)
    }

    func test_hasNext_atStep3_isTrue() {
        sut.currentStepIndex = 3
        XCTAssertTrue(sut.hasNext)
    }

    func test_hasNext_atLastStep_isFalse() {
        sut.currentStepIndex = 4
        XCTAssertFalse(sut.hasNext)
    }

    // MARK: - hasPrevious Computed Property Tests

    func test_hasPrevious_atStep0_isFalse() {
        sut.currentStepIndex = 0
        XCTAssertFalse(sut.hasPrevious)
    }

    func test_hasPrevious_atStep1_isTrue() {
        sut.currentStepIndex = 1
        XCTAssertTrue(sut.hasPrevious)
    }

    func test_hasPrevious_atLastStep_isTrue() {
        sut.currentStepIndex = 4
        XCTAssertTrue(sut.hasPrevious)
    }

    // MARK: - Edge Cases - Empty Recipe

    func test_emptyRecipe_currentStepIsNil() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        XCTAssertNil(vm.currentStep)
    }

    func test_emptyRecipe_progressIsZero() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        XCTAssertEqual(vm.progress, 0)
    }

    func test_emptyRecipe_hasNext_isFalse() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        XCTAssertFalse(vm.hasNext)
    }

    func test_emptyRecipe_hasPrevious_isFalse() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        XCTAssertFalse(vm.hasPrevious)
    }

    func test_emptyRecipe_nextStep_doesNotCrash() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        vm.nextStep()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    func test_emptyRecipe_previousStep_doesNotCrash() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        vm.previousStep()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    func test_emptyRecipe_restart_doesNotCrash() {
        let emptyRecipe = makeEmptyRecipe()
        let vm = CookingModeViewModel(recipe: emptyRecipe)
        vm.restart()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    // MARK: - Edge Cases - Single Step Recipe

    func test_singleStepRecipe_currentStepIsFirstStep() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        XCTAssertEqual(vm.currentStep?.title, "Just Do It")
    }

    func test_singleStepRecipe_progressIsOne() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        // (0 + 1) / 1 = 1.0
        XCTAssertEqual(vm.progress, 1.0, accuracy: 0.001)
    }

    func test_singleStepRecipe_hasNext_isFalse() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        XCTAssertFalse(vm.hasNext)
    }

    func test_singleStepRecipe_hasPrevious_isFalse() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        XCTAssertFalse(vm.hasPrevious)
    }

    func test_singleStepRecipe_nextStep_doesNotAdvance() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        vm.nextStep()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    func test_singleStepRecipe_previousStep_doesNotGoBack() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        vm.previousStep()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    func test_singleStepRecipe_restart_returnsToZero() {
        let singleRecipe = makeSingleStepRecipe()
        let vm = CookingModeViewModel(recipe: singleRecipe)
        // No way to advance, so restart should stay at 0
        vm.restart()
        XCTAssertEqual(vm.currentStepIndex, 0)
    }

    // MARK: - Full Navigation Cycle

    func test_fullNavigationForward() {
        let expectedIndices = [0, 1, 2, 3, 4]
        for expectedIndex in expectedIndices {
            XCTAssertEqual(sut.currentStepIndex, expectedIndex)
            sut.nextStep()
        }
        // Should be stuck at last
        XCTAssertEqual(sut.currentStepIndex, 4)
    }

    func test_fullNavigationBackward() {
        sut.currentStepIndex = 4
        let expectedIndices = [4, 3, 2, 1, 0]
        for expectedIndex in expectedIndices {
            XCTAssertEqual(sut.currentStepIndex, expectedIndex)
            sut.previousStep()
        }
        // Should be stuck at first
        XCTAssertEqual(sut.currentStepIndex, 0)
    }

    func test_fullNavigationForwardAndBack() {
        // Go all the way forward
        while sut.hasNext {
            sut.nextStep()
        }
        XCTAssertEqual(sut.currentStepIndex, 4)
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.001)

        // Go all the way back
        while sut.hasPrevious {
            sut.previousStep()
        }
        XCTAssertEqual(sut.currentStepIndex, 0)
        XCTAssertEqual(sut.progress, 0.2, accuracy: 0.001)
    }

    func test_completeCycle_startToEndToStart() {
        sut.nextStep() // 1
        sut.nextStep() // 2
        sut.nextStep() // 3
        sut.nextStep() // 4
        XCTAssertEqual(sut.currentStepIndex, 4)
        XCTAssertFalse(sut.hasNext)

        sut.previousStep() // 3
        sut.previousStep() // 2
        sut.previousStep() // 1
        sut.previousStep() // 0
        XCTAssertEqual(sut.currentStepIndex, 0)
        XCTAssertFalse(sut.hasPrevious)
    }

    // MARK: - Recipe State

    func test_recipeIsReference() {
        sut.recipe.title = "Modified Title"
        XCTAssertEqual(recipe.title, "Modified Title")
    }

    func test_recipeStepsAreAccessible() {
        XCTAssertEqual(recipe.sortedSteps.count, 5)
    }

    func test_recipeStepOrder() {
        let steps = recipe.sortedSteps
        for (index, step) in steps.enumerated() {
            XCTAssertEqual(step.displayOrder, index)
        }
    }

    // MARK: - Step Duration Formatting

    func test_stepFormattedDuration_under60Minutes() {
        let step = RecipeStep(title: "Quick Step", instruction: "Do it fast", durationMinutes: 15, displayOrder: 0)
        XCTAssertEqual(step.formattedDuration, "15 min")
    }

    func test_stepFormattedDuration_exactHour() {
        let step = RecipeStep(title: "Hour Step", instruction: "Wait an hour", durationMinutes: 60, displayOrder: 0)
        XCTAssertEqual(step.formattedDuration, "1 hr")
    }

    func test_stepFormattedDuration_hourAndMinutes() {
        let step = RecipeStep(title: "Long Step", instruction: "Wait a while", durationMinutes: 90, displayOrder: 0)
        XCTAssertEqual(step.formattedDuration, "1 hr 30 min")
    }

    func test_stepFormattedDuration_nil() {
        let step = RecipeStep(title: "No Duration", instruction: "Just do it", durationMinutes: nil, displayOrder: 0)
        XCTAssertEqual(step.formattedDuration, "No time estimate")
    }

    func test_stepLabel() {
        let step = RecipeStep(title: "Preheat", instruction: "Preheat oven", durationMinutes: 15, displayOrder: 0)
        XCTAssertEqual(step.stepLabel, "Step 1: Preheat")
    }

    func test_stepLabel_differentOrder() {
        let step = RecipeStep(title: "Bake", instruction: "Bake it", durationMinutes: 25, displayOrder: 4)
        XCTAssertEqual(step.stepLabel, "Step 5: Bake")
    }

    // MARK: - Ingredient State Management

    func test_ingredientIsCheckedDefaultFalse() {
        let ingredient = Ingredient(name: "Flour", quantity: "2", unit: "cups", displayOrder: 0)
        XCTAssertFalse(ingredient.isChecked)
    }

    func test_ingredientCanBeChecked() {
        let ingredient = Ingredient(name: "Flour", quantity: "2", unit: "cups", displayOrder: 0)
        ingredient.isChecked = true
        XCTAssertTrue(ingredient.isChecked)
    }

    func test_ingredientToggle() {
        let ingredient = Ingredient(name: "Flour", quantity: "2", unit: "cups", displayOrder: 0)
        ingredient.isChecked.toggle()
        XCTAssertTrue(ingredient.isChecked)
        ingredient.isChecked.toggle()
        XCTAssertFalse(ingredient.isChecked)
    }

    func test_recipeWithIngredients_sortedIngredients() {
        let recipeWithIngredients = makeRecipeWithIngredients()
        let ingredients = recipeWithIngredients.sortedIngredients
        XCTAssertEqual(ingredients.count, 4)
        XCTAssertEqual(ingredients[0].name, "All-purpose flour")
        XCTAssertEqual(ingredients[1].name, "Sugar")
        XCTAssertEqual(ingredients[2].name, "Butter")
        XCTAssertEqual(ingredients[3].name, "Eggs")
    }

    func test_ingredientDisplayText_allFields() {
        let ingredient = Ingredient(name: "Flour", quantity: "2", unit: "cups", displayOrder: 0)
        XCTAssertEqual(ingredient.displayText, "2 cups Flour")
    }

    func test_ingredientDisplayText_nameOnly() {
        let ingredient = Ingredient(name: "Salt", displayOrder: 0)
        XCTAssertEqual(ingredient.displayText, "Salt")
    }

    func test_ingredientShortDisplayText_withQuantityAndUnit() {
        let ingredient = Ingredient(name: "Flour", quantity: "2", unit: "cups", displayOrder: 0)
        XCTAssertEqual(ingredient.shortDisplayText, "2 cups")
    }

    func test_ingredientShortDisplayText_quantityOnly() {
        let ingredient = Ingredient(name: "Salt", quantity: "1", unit: nil, displayOrder: 0)
        XCTAssertEqual(ingredient.shortDisplayText, "1")
    }

    // MARK: - currentStepIndex Mutability

    func test_currentStepIndex_canBeSetDirectly() {
        sut.currentStepIndex = 3
        XCTAssertEqual(sut.currentStepIndex, 3)
    }

    func test_currentStepIndex_negativeValue() {
        sut.currentStepIndex = -5
        XCTAssertNil(sut.currentStep)
    }

    func test_currentStepIndex_veryLargeValue() {
        sut.currentStepIndex = 999
        XCTAssertNil(sut.currentStep)
    }

    // MARK: - Multiple ViewModels Share Recipe

    func test_multipleViewModels_shareRecipeReference() {
        let vm1 = CookingModeViewModel(recipe: recipe)
        let vm2 = CookingModeViewModel(recipe: recipe)
        vm1.currentStepIndex = 3
        vm2.currentStepIndex = 1
        XCTAssertEqual(vm1.currentStepIndex, 3)
        XCTAssertEqual(vm2.currentStepIndex, 1)
        // Recipe is shared but indices are independent
        XCTAssertEqual(vm1.currentStep?.title, "Combine")
        XCTAssertEqual(vm2.currentStep?.title, "Mix Dry")
    }

    // MARK: - Restart Resets Everything

    func test_restart_afterNavigation() {
        sut.currentStepIndex = 4
        sut.restart()
        XCTAssertEqual(sut.currentStepIndex, 0)
        XCTAssertTrue(sut.hasNext)
        XCTAssertFalse(sut.hasPrevious)
        XCTAssertEqual(sut.currentStep?.title, "Preheat")
    }

    func test_restart_preservesRecipe() {
        sut.currentStepIndex = 4
        let originalTitle = sut.recipe.title
        sut.restart()
        XCTAssertEqual(sut.recipe.title, originalTitle)
        XCTAssertEqual(sut.recipe.sortedSteps.count, 5)
    }

    // MARK: - Progress Bounds

    func test_progress_neverNegative() {
        sut.currentStepIndex = 0
        XCTAssertGreaterThanOrEqual(sut.progress, 0)
    }

    func test_progress_atMostOneWithFiveSteps() {
        sut.currentStepIndex = 4
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.001)
    }

    func test_progress_increasesMonotonically() {
        var previousProgress: Double = -1
        for index in 0..<5 {
            sut.currentStepIndex = index
            let currentProgress = sut.progress
            XCTAssertGreaterThan(currentProgress, previousProgress)
            previousProgress = currentProgress
        }
    }

    // MARK: - RecipeStep Equatable

    func test_recipeStepEquality_sameId() {
        let id = UUID()
        let step1 = RecipeStep(id: id, title: "A", instruction: "First")
        let step2 = RecipeStep(id: id, title: "B", instruction: "Second")
        XCTAssertEqual(step1, step2)
    }

    func test_recipeStepEquality_differentId() {
        let step1 = RecipeStep(title: "A", instruction: "First")
        let step2 = RecipeStep(title: "A", instruction: "First")
        XCTAssertNotEqual(step1, step2)
    }

    // MARK: - Ingredient Equatable

    func test_ingredientEquality_sameId() {
        let id = UUID()
        let ing1 = Ingredient(id: id, name: "Flour", quantity: "2", unit: "cups")
        let ing2 = Ingredient(id: id, name: "Sugar", quantity: "1", unit: "cup")
        XCTAssertEqual(ing1, ing2)
    }

    func test_ingredientEquality_differentId() {
        let ing1 = Ingredient(name: "Flour", quantity: "2", unit: "cups")
        let ing2 = Ingredient(name: "Flour", quantity: "2", unit: "cups")
        XCTAssertNotEqual(ing1, ing2)
    }

    // MARK: - Total Steps Count

    func test_totalSteps_count() {
        XCTAssertEqual(recipe.sortedSteps.count, 5)
    }

    func test_totalSteps_matchesProgressDenominator() {
        // progress = (currentStepIndex + 1) / totalSteps
        // At last step: progress = 1.0 means totalSteps = currentStepIndex + 1
        sut.currentStepIndex = 4
        let totalFromProgress = Int(Double(sut.currentStepIndex + 1) / sut.progress)
        XCTAssertEqual(totalFromProgress, 5)
    }
}
