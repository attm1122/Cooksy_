import XCTest
@testable import Cooksy

// MARK: - RecipeDetailViewModelTests
/// Comprehensive unit tests for the RecipeDetailViewModel recipe display and interaction state.
///
/// Tests cover all boolean state toggles (save, cooking mode, cook-along, edit, share),
/// ingredient checking, share item preparation, recipe deletion, and initial state.
@MainActor
final class RecipeDetailViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: RecipeDetailViewModel!
    private var recipe: Recipe!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        recipe = makeRecipe()
        sut = RecipeDetailViewModel(recipe: recipe)
    }

    override func tearDown() {
        sut = nil
        recipe = nil
        super.tearDown()
    }

    // MARK: - Factory Methods

    private func makeRecipe(
        title: String = "Test Recipe",
        servings: Int = 4,
        isSaved: Bool = false,
        sourceUrl: String = "https://youtube.com/watch?v=test",
        sourcePlatform: SourcePlatform = .youtube,
        sourceCreator: String = "Test Chef",
        sourceTitle: String = "Test Video"
    ) -> Recipe {
        let recipe = Recipe(
            title: title,
            servings: servings,
            isSaved: isSaved,
            sourceUrl: sourceUrl,
            sourcePlatform: sourcePlatform,
            sourceCreator: sourceCreator,
            sourceTitle: sourceTitle
        )
        return recipe
    }

    private func makeRecipeWithIngredients() -> Recipe {
        let recipe = makeRecipe()
        let flour = Ingredient(name: "All-purpose flour", quantity: "2", unit: "cups", displayOrder: 0)
        let sugar = Ingredient(name: "Sugar", quantity: "1", unit: "cup", displayOrder: 1)
        let butter = Ingredient(name: "Butter", quantity: "0.5", unit: "cup", displayOrder: 2)
        recipe.ingredients = [flour, sugar, butter]
        return recipe
    }

    private func makeRecipeWithSteps() -> Recipe {
        let recipe = makeRecipe()
        let step1 = RecipeStep(title: "Preheat", instruction: "Preheat oven to 350F", durationMinutes: 15, displayOrder: 0)
        let step2 = RecipeStep(title: "Mix", instruction: "Mix dry ingredients together", durationMinutes: 5, displayOrder: 1)
        let step3 = RecipeStep(title: "Bake", instruction: "Bake for 25 minutes", durationMinutes: 25, displayOrder: 2)
        recipe.steps = [step1, step2, step3]
        return recipe
    }

    // MARK: - Initial State Tests

    func test_initialState_recipeIsAssigned() {
        XCTAssertEqual(sut.recipe.title, "Test Recipe")
    }

    func test_initialState_showCookingModeIsFalse() {
        XCTAssertFalse(sut.showCookingMode)
    }

    func test_initialState_showCookAlongIsFalse() {
        XCTAssertFalse(sut.showCookAlong)
    }

    func test_initialState_showEditSheetIsFalse() {
        XCTAssertFalse(sut.showEditSheet)
    }

    func test_initialState_showShareSheetIsFalse() {
        XCTAssertFalse(sut.showShareSheet)
    }

    func test_initialState_shareItemsIsEmpty() {
        XCTAssertTrue(sut.shareItems.isEmpty)
    }

    // MARK: - toggleSave() Tests

    func test_toggleSave_flipsIsSavedFromFalseToTrue() {
        recipe.isSaved = false
        sut.toggleSave()
        XCTAssertTrue(recipe.isSaved)
    }

    func test_toggleSave_flipsIsSavedFromTrueToFalse() {
        recipe.isSaved = true
        sut.toggleSave()
        XCTAssertFalse(recipe.isSaved)
    }

    func test_toggleSave_touchesRecipe() {
        let before = recipe.updatedAt
        Thread.sleep(forTimeInterval: 0.01)
        sut.toggleSave()
        XCTAssertGreaterThan(recipe.updatedAt, before)
    }

    func test_toggleSave_doubleToggleRestoresOriginal() {
        let original = recipe.isSaved
        sut.toggleSave()
        sut.toggleSave()
        XCTAssertEqual(recipe.isSaved, original)
    }

    func test_toggleSave_multipleToggles() {
        recipe.isSaved = false
        sut.toggleSave() // true
        sut.toggleSave() // false
        sut.toggleSave() // true
        XCTAssertTrue(recipe.isSaved)
    }

    // MARK: - toggleIngredient() Tests

    func test_toggleIngredient_flipsIsChecked() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        guard let ingredient = recipe.sortedIngredients.first else {
            XCTFail("Recipe should have ingredients")
            return
        }
        let original = ingredient.isChecked
        sut.toggleIngredient(ingredient)
        XCTAssertNotEqual(ingredient.isChecked, original)
    }

    func test_toggleIngredient_uncheckedBecomesChecked() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        let ingredient = recipe.sortedIngredients[0]
        ingredient.isChecked = false
        sut.toggleIngredient(ingredient)
        XCTAssertTrue(ingredient.isChecked)
    }

    func test_toggleIngredient_checkedBecomesUnchecked() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        let ingredient = recipe.sortedIngredients[0]
        ingredient.isChecked = true
        sut.toggleIngredient(ingredient)
        XCTAssertFalse(ingredient.isChecked)
    }

    func test_toggleIngredient_touchesRecipe() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        let before = recipe.updatedAt
        Thread.sleep(forTimeInterval: 0.01)
        let ingredient = recipe.sortedIngredients[0]
        sut.toggleIngredient(ingredient)
        XCTAssertGreaterThan(recipe.updatedAt, before)
    }

    func test_toggleIngredient_doesNotAffectOtherIngredients() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        let ingredient0 = recipe.sortedIngredients[0]
        let ingredient1 = recipe.sortedIngredients[1]
        ingredient0.isChecked = false
        ingredient1.isChecked = false
        sut.toggleIngredient(ingredient0)
        XCTAssertTrue(ingredient0.isChecked)
        XCTAssertFalse(ingredient1.isChecked)
    }

    // MARK: - startCooking() Tests

    func test_startCooking_setsShowCookingModeToTrue() {
        sut.startCooking()
        XCTAssertTrue(sut.showCookingMode)
    }

    func test_startCooking_fromAlreadyTrue() {
        sut.startCooking()
        sut.startCooking()
        XCTAssertTrue(sut.showCookingMode)
    }

    // MARK: - startCookAlong() Tests

    func test_startCookAlong_setsShowCookAlongToTrue() {
        sut.startCookAlong()
        XCTAssertTrue(sut.showCookAlong)
    }

    func test_startCookAlong_fromAlreadyTrue() {
        sut.startCookAlong()
        sut.startCookAlong()
        XCTAssertTrue(sut.showCookAlong)
    }

    // MARK: - editRecipe() Tests

    func test_editRecipe_setsShowEditSheetToTrue() {
        sut.editRecipe()
        XCTAssertTrue(sut.showEditSheet)
    }

    func test_editRecipe_multipleCalls() {
        sut.editRecipe()
        sut.editRecipe()
        XCTAssertTrue(sut.showEditSheet)
    }

    // MARK: - prepareShare() Tests

    func test_prepareShare_setsShowShareSheetToTrue() {
        sut.prepareShare()
        XCTAssertTrue(sut.showShareSheet)
    }

    func test_prepareShare_populatesShareItems() {
        sut.prepareShare()
        XCTAssertFalse(sut.shareItems.isEmpty)
    }

    func test_prepareShare_shareItemsContainsText() {
        sut.prepareShare()
        let textItem = sut.shareItems.first { item in
            if let str = item as? String {
                return str.contains("Check out this recipe")
            }
            return false
        }
        XCTAssertNotNil(textItem)
    }

    func test_prepareShare_shareItemsContainsURL() {
        sut.prepareShare()
        let urlItem = sut.shareItems.first { item in
            item is URL
        }
        XCTAssertNotNil(urlItem)
    }

    func test_prepareShare_shareTextContainsRecipeTitle() {
        sut.prepareShare()
        guard let textItem = sut.shareItems.first as? String else {
            XCTFail("First share item should be a String")
            return
        }
        XCTAssertTrue(textItem.contains(recipe.title))
    }

    func test_prepareShare_shareURLIsValid() {
        sut.prepareShare()
        guard let urlItem = sut.shareItems.first(where: { $0 is URL }) as? URL else {
            XCTFail("Share items should contain a URL")
            return
        }
        XCTAssertTrue(urlItem.absoluteString.contains("cooksy.app"))
    }

    func test_prepareShare_resetsAndRepopulates() {
        sut.prepareShare()
        let firstItems = sut.shareItems
        sut.showShareSheet = false
        sut.shareItems = []
        sut.prepareShare()
        XCTAssertEqual(sut.shareItems.count, firstItems.count)
    }

    // MARK: - deleteRecipe() Tests (without ModelContext)

    func test_deleteRecipe_withoutModelContext_returnsFalse() {
        let result = sut.deleteRecipe()
        XCTAssertFalse(result)
    }

    // MARK: - Boolean State Independence

    func test_cookingModeAndCookAlongAreIndependent() {
        sut.startCooking()
        XCTAssertTrue(sut.showCookingMode)
        XCTAssertFalse(sut.showCookAlong)

        sut.startCookAlong()
        XCTAssertTrue(sut.showCookingMode)
        XCTAssertTrue(sut.showCookAlong)
    }

    func test_editSheetDoesNotAffectCookingMode() {
        sut.startCooking()
        sut.editRecipe()
        XCTAssertTrue(sut.showCookingMode)
        XCTAssertTrue(sut.showEditSheet)
    }

    func test_shareDoesNotAffectOtherStates() {
        sut.startCooking()
        sut.startCookAlong()
        sut.editRecipe()
        sut.prepareShare()
        XCTAssertTrue(sut.showCookingMode)
        XCTAssertTrue(sut.showCookAlong)
        XCTAssertTrue(sut.showEditSheet)
        XCTAssertTrue(sut.showShareSheet)
    }

    // MARK: - Recipe Reference Semantics

    func test_recipeIsReferenceType() {
        let sharedRecipe = recipe!
        sut.recipe.title = "Modified Title"
        XCTAssertEqual(sharedRecipe.title, "Modified Title")
    }

    func test_recipeTitleAssignment() {
        sut.recipe.title = "New Title"
        XCTAssertEqual(sut.recipe.title, "New Title")
    }

    // MARK: - Multiple Simultaneous Toggles

    func test_rapidToggleSave() {
        recipe.isSaved = false
        sut.toggleSave() // true
        sut.toggleSave() // false
        sut.toggleSave() // true
        sut.toggleSave() // false
        sut.toggleSave() // true
        XCTAssertTrue(recipe.isSaved)
    }

    func test_rapidToggleIngredient() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        let ingredient = recipe.sortedIngredients[0]
        sut.toggleIngredient(ingredient)
        sut.toggleIngredient(ingredient)
        sut.toggleIngredient(ingredient)
        sut.toggleIngredient(ingredient)
        // Toggled 4 times, should be back to original (false)
        XCTAssertFalse(ingredient.isChecked)
    }

    // MARK: - Share Items Count

    func test_prepareShare_createsExactlyTwoItems() {
        sut.prepareShare()
        XCTAssertEqual(sut.shareItems.count, 2)
    }

    func test_prepareShare_firstItemIsString() {
        sut.prepareShare()
        XCTAssertTrue(sut.shareItems[0] is String)
    }

    func test_prepareShare_secondItemIsURL() {
        sut.prepareShare()
        XCTAssertTrue(sut.shareItems[1] is URL)
    }

    // MARK: - State Reset Tests

    func test_canResetAllSheets() {
        sut.startCooking()
        sut.startCookAlong()
        sut.editRecipe()
        sut.prepareShare()

        sut.showCookingMode = false
        sut.showCookAlong = false
        sut.showEditSheet = false
        sut.showShareSheet = false

        XCTAssertFalse(sut.showCookingMode)
        XCTAssertFalse(sut.showCookAlong)
        XCTAssertFalse(sut.showEditSheet)
        XCTAssertFalse(sut.showShareSheet)
    }

    // MARK: - Recipe with Steps Computed Property

    func test_recipeSortedSteps() {
        let recipe = makeRecipeWithSteps()
        sut = RecipeDetailViewModel(recipe: recipe)
        let steps = recipe.sortedSteps
        XCTAssertEqual(steps.count, 3)
        XCTAssertEqual(steps[0].title, "Preheat")
        XCTAssertEqual(steps[1].title, "Mix")
        XCTAssertEqual(steps[2].title, "Bake")
    }

    func test_recipeSortedIngredients() {
        let recipe = makeRecipeWithIngredients()
        sut = RecipeDetailViewModel(recipe: recipe)
        let ingredients = recipe.sortedIngredients
        XCTAssertEqual(ingredients.count, 3)
        XCTAssertEqual(ingredients[0].name, "All-purpose flour")
    }

    func test_recipeInitialSavedState() {
        let savedRecipe = makeRecipe(isSaved: true)
        let vm = RecipeDetailViewModel(recipe: savedRecipe)
        XCTAssertTrue(vm.recipe.isSaved)
    }

    func test_recipeInitialUnsavedState() {
        let unsavedRecipe = makeRecipe(isSaved: false)
        let vm = RecipeDetailViewModel(recipe: unsavedRecipe)
        XCTAssertFalse(vm.recipe.isSaved)
    }

    // MARK: - Recipe Summary

    func test_recipeSummaryContainsServings() {
        let summary = sut.recipe.summaryLine
        XCTAssertTrue(summary.contains("\(recipe.servings)"))
    }

    func test_recipeSummaryContainsCreator() {
        let summary = sut.recipe.summaryLine
        XCTAssertTrue(summary.contains(recipe.sourceCreator))
    }

    // MARK: - All Boolean States Default False

    func test_allSheetStatesDefaultToFalse() {
        XCTAssertFalse(sut.showCookingMode)
        XCTAssertFalse(sut.showCookAlong)
        XCTAssertFalse(sut.showEditSheet)
        XCTAssertFalse(sut.showShareSheet)
    }

    func test_noFalsePositivesForInitialState() {
        // Ensure that a fresh VM has all flags at false
        let freshVM = RecipeDetailViewModel(recipe: makeRecipe())
        XCTAssertFalse(freshVM.showCookingMode)
        XCTAssertFalse(freshVM.showCookAlong)
        XCTAssertFalse(freshVM.showEditSheet)
        XCTAssertFalse(freshVM.showShareSheet)
        XCTAssertTrue(freshVM.shareItems.isEmpty)
    }
}
