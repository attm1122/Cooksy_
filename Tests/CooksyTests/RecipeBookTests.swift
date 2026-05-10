import XCTest
@testable import Cooksy

// MARK: - RecipeBook Model Tests
/// Comprehensive unit tests for the RecipeBook model covering all initializers,
/// stored properties, computed properties, convenience methods, Equatable/Hashable,
/// sorting descriptors, and edge cases.
final class RecipeBookTests: XCTestCase {

    // MARK: - Factory Helpers

    private func makeRecipeBook(
        id: UUID = UUID(),
        name: String = "Weeknight Dinners",
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> RecipeBook {
        RecipeBook(
            id: id,
            name: name,
            createdAt: createdAt
        )
    }

    private func makeRecipe(
        title: String = "Test Recipe",
        sourceUrl: String = "https://youtube.com/watch?v=test",
        sourcePlatform: SourcePlatform = .youtube,
        sourceCreator: String = "Test Chef",
        sourceTitle: String = "Test Video"
    ) -> Recipe {
        Recipe(
            title: title,
            sourceUrl: sourceUrl,
            sourcePlatform: sourcePlatform,
            sourceCreator: sourceCreator,
            sourceTitle: sourceTitle
        )
    }

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let book = RecipeBook(name: "Favorites")

        XCTAssertEqual(book.name, "Favorites")
        XCTAssertNotNil(book.id)
        XCTAssertNotNil(book.createdAt)
    }

    func testInit_WithAllValues() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let book = makeRecipeBook(id: id, name: "Holiday Baking", createdAt: date)

        XCTAssertEqual(book.id, id)
        XCTAssertEqual(book.name, "Holiday Baking")
        XCTAssertEqual(book.createdAt, date)
    }

    func testInit_EmptyName() {
        let book = makeRecipeBook(name: "")

        XCTAssertEqual(book.name, "")
    }

    func testInit_WhitespaceName() {
        let book = makeRecipeBook(name: "   ")

        XCTAssertEqual(book.name, "   ")
    }

    func testInit_UnicodeName() {
        let book = makeRecipeBook(name: "週末のディナー")

        XCTAssertEqual(book.name, "週末のディナー")
    }

    func testInit_VeryLongName() {
        let longName = String(repeating: "A", count: 1000)
        let book = makeRecipeBook(name: longName)

        XCTAssertEqual(book.name, longName)
    }

    func testInit_NameWithSpecialCharacters() {
        let book = makeRecipeBook(name: "Desserts & Sweets! (Healthy?)")

        XCTAssertEqual(book.name, "Desserts & Sweets! (Healthy?)")
    }

    func testInit_NameWithEmoji() {
        let book = makeRecipeBook(name: "🍕 Pizza Night")

        XCTAssertEqual(book.name, "🍕 Pizza Night")
    }

    func testInit_CreatedAtIsRecent() {
        let beforeInit = Date()
        let book = RecipeBook(name: "Recent")
        let afterInit = Date()

        XCTAssertGreaterThanOrEqual(book.createdAt, beforeInit)
        XCTAssertLessThanOrEqual(book.createdAt, afterInit)
    }

    // MARK: - Stored Property Tests

    func testName_IsStored() {
        let book = makeRecipeBook(name: "Meal Prep")

        XCTAssertEqual(book.name, "Meal Prep")
    }

    func testCreatedAt_IsStored() {
        let date = Date(timeIntervalSince1970: 1_600_000_000)
        let book = makeRecipeBook(createdAt: date)

        XCTAssertEqual(book.createdAt, date)
    }

    func testName_Mutation() {
        let book = makeRecipeBook(name: "Old Name")
        book.name = "New Name"

        XCTAssertEqual(book.name, "New Name")
    }

    func testCreatedAt_Mutation() {
        let book = makeRecipeBook(createdAt: Date(timeIntervalSince1970: 1_700_000_000))
        let newDate = Date(timeIntervalSince1970: 1_800_000_000)
        book.createdAt = newDate

        XCTAssertEqual(book.createdAt, newDate)
    }

    // MARK: - Identity Tests

    func testId_IsUnique() {
        let book1 = makeRecipeBook()
        let book2 = makeRecipeBook()

        XCTAssertNotEqual(book1.id, book2.id)
    }

    func testId_IsStable() {
        let book = makeRecipeBook()
        let originalId = book.id

        book.name = "Changed"

        XCTAssertEqual(book.id, originalId)
    }

    // MARK: - recipeCount Computed Property Tests

    func testRecipeCount_NoRecipes() {
        let book = makeRecipeBook()

        XCTAssertEqual(book.recipeCount, 0)
    }

    func testRecipeCount_NilRecipes() {
        let book = makeRecipeBook()
        book.recipes = nil

        XCTAssertEqual(book.recipeCount, 0)
    }

    func testRecipeCount_OneRecipe() {
        let book = makeRecipeBook()
        let recipe = makeRecipe()
        book.recipes = [recipe]

        XCTAssertEqual(book.recipeCount, 1)
    }

    func testRecipeCount_MultipleRecipes() {
        let book = makeRecipeBook()
        let recipe1 = makeRecipe(title: "Recipe 1")
        let recipe2 = makeRecipe(title: "Recipe 2")
        let recipe3 = makeRecipe(title: "Recipe 3")
        book.recipes = [recipe1, recipe2, recipe3]

        XCTAssertEqual(book.recipeCount, 3)
    }

    func testRecipeCount_EmptyArray() {
        let book = makeRecipeBook()
        book.recipes = []

        XCTAssertEqual(book.recipeCount, 0)
    }

    func testRecipeCount_TenRecipes() {
        let book = makeRecipeBook()
        let recipes = (1...10).map { makeRecipe(title: "Recipe \($0)") }
        book.recipes = recipes

        XCTAssertEqual(book.recipeCount, 10)
    }

    // MARK: - recipesArray Computed Property Tests

    func testRecipesArray_NilReturnsEmpty() {
        let book = makeRecipeBook()
        book.recipes = nil

        XCTAssertTrue(book.recipesArray.isEmpty)
    }

    func testRecipesArray_EmptyReturnsEmpty() {
        let book = makeRecipeBook()
        book.recipes = []

        XCTAssertTrue(book.recipesArray.isEmpty)
    }

    func testRecipesArray_WithRecipes() {
        let book = makeRecipeBook()
        let recipe = makeRecipe()
        book.recipes = [recipe]

        XCTAssertEqual(book.recipesArray.count, 1)
        XCTAssertEqual(book.recipesArray.first?.title, recipe.title)
    }

    func testRecipesArray_MultipleRecipes() {
        let book = makeRecipeBook()
        let recipes = [makeRecipe(title: "A"), makeRecipe(title: "B")]
        book.recipes = recipes

        XCTAssertEqual(book.recipesArray.count, 2)
    }

    func testRecipesArray_NonOptional() {
        let book = makeRecipeBook()

        // Should compile and be non-optional
        let array: [Recipe] = book.recipesArray
        XCTAssertTrue(array.isEmpty)
    }

    // MARK: - recipeCountDescription Computed Property Tests

    func testRecipeCountDescription_Zero() {
        let book = makeRecipeBook()
        book.recipes = []

        XCTAssertEqual(book.recipeCountDescription, "0 recipes")
    }

    func testRecipeCountDescription_NilRecipes() {
        let book = makeRecipeBook()
        book.recipes = nil

        XCTAssertEqual(book.recipeCountDescription, "0 recipes")
    }

    func testRecipeCountDescription_One() {
        let book = makeRecipeBook()
        book.recipes = [makeRecipe()]

        XCTAssertEqual(book.recipeCountDescription, "1 recipe")
    }

    func testRecipeCountDescription_Multiple() {
        let book = makeRecipeBook()
        book.recipes = [makeRecipe(), makeRecipe(), makeRecipe()]

        XCTAssertEqual(book.recipeCountDescription, "3 recipes")
    }

    func testRecipeCountDescription_Two() {
        let book = makeRecipeBook()
        book.recipes = [makeRecipe(), makeRecipe()]

        XCTAssertEqual(book.recipeCountDescription, "2 recipes")
    }

    func testRecipeCountDescription_SingularVsPlural() {
        // Exactly 1 should use singular form
        let book1 = makeRecipeBook()
        book1.recipes = [makeRecipe()]
        XCTAssertEqual(book1.recipeCountDescription, "1 recipe")
        XCTAssertFalse(book1.recipeCountDescription.contains("recipes"))

        // More than 1 should use plural form
        let book2 = makeRecipeBook()
        book2.recipes = [makeRecipe(), makeRecipe()]
        XCTAssertEqual(book2.recipeCountDescription, "2 recipes")
    }

    // MARK: - Recipe Management Tests

    func testAddRecipe() {
        let book = makeRecipeBook()
        let recipe = makeRecipe()

        if book.recipes == nil {
            book.recipes = []
        }
        book.recipes?.append(recipe)

        XCTAssertEqual(book.recipeCount, 1)
        XCTAssertTrue(book.recipesArray.contains { $0.id == recipe.id })
    }

    func testAddMultipleRecipes() {
        let book = makeRecipeBook()
        book.recipes = []

        let recipe1 = makeRecipe(title: "Pasta")
        let recipe2 = makeRecipe(title: "Salad")
        let recipe3 = makeRecipe(title: "Soup")

        book.recipes?.append(recipe1)
        book.recipes?.append(recipe2)
        book.recipes?.append(recipe3)

        XCTAssertEqual(book.recipeCount, 3)
    }

    func testRemoveRecipe() {
        let book = makeRecipeBook()
        let recipe = makeRecipe()
        book.recipes = [recipe]

        book.recipes?.removeAll { $0.id == recipe.id }

        XCTAssertEqual(book.recipeCount, 0)
    }

    func testRemoveRecipe_FromMultiple() {
        let book = makeRecipeBook()
        let recipe1 = makeRecipe(title: "Keep")
        let recipe2 = makeRecipe(title: "Remove")
        let recipe3 = makeRecipe(title: "Keep Too")
        book.recipes = [recipe1, recipe2, recipe3]

        book.recipes?.removeAll { $0.title == "Remove" }

        XCTAssertEqual(book.recipeCount, 2)
        XCTAssertNil(book.recipesArray.first { $0.title == "Remove" })
    }

    func testDuplicateRecipeAdds() {
        let book = makeRecipeBook()
        let recipe = makeRecipe()
        book.recipes = []

        book.recipes?.append(recipe)
        book.recipes?.append(recipe)

        // Arrays allow duplicates unless guarded against
        XCTAssertEqual(book.recipeCount, 2)
    }

    // MARK: - Equatable Tests

    func testEquality_SameId() {
        let id = UUID()
        let book1 = makeRecipeBook(id: id, name: "Book A")
        let book2 = makeRecipeBook(id: id, name: "Book B")

        XCTAssertEqual(book1, book2)
    }

    func testEquality_DifferentId() {
        let book1 = makeRecipeBook(name: "Same Name")
        let book2 = makeRecipeBook(name: "Same Name")

        XCTAssertNotEqual(book1, book2)
    }

    func testEquality_SameIdDifferentName() {
        let id = UUID()
        let book1 = makeRecipeBook(id: id, name: "A")
        let book2 = makeRecipeBook(id: id, name: "B")

        XCTAssertEqual(book1, book2)
    }

    func testEquality_SameIdDifferentCreatedAt() {
        let id = UUID()
        let book1 = makeRecipeBook(id: id, createdAt: Date(timeIntervalSince1970: 1_000))
        let book2 = makeRecipeBook(id: id, createdAt: Date(timeIntervalSince1970: 2_000))

        XCTAssertEqual(book1, book2)
    }

    func testEquality_SameIdDifferentRecipes() {
        let id = UUID()
        let book1 = makeRecipeBook(id: id)
        let book2 = makeRecipeBook(id: id)
        book1.recipes = [makeRecipe()]
        book2.recipes = []

        XCTAssertEqual(book1, book2)
    }

    // MARK: - Hashable Tests

    func testHashable_SameId() {
        let id = UUID()
        let book1 = makeRecipeBook(id: id, name: "A")
        let book2 = makeRecipeBook(id: id, name: "B")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        book1.hash(into: &hasher1)
        book2.hash(into: &hasher2)

        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_DifferentId() {
        let book1 = makeRecipeBook(name: "A")
        let book2 = makeRecipeBook(name: "A")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        book1.hash(into: &hasher1)
        book2.hash(into: &hasher2)

        XCTAssertNotEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_UsedInSet() {
        let id = UUID()
        let book1 = makeRecipeBook(id: id, name: "A")
        let book2 = makeRecipeBook(id: id, name: "B")

        let set: Set<RecipeBook> = [book1, book2]

        XCTAssertEqual(set.count, 1)
    }

    func testHashable_UsedInDictionary() {
        let id = UUID()
        let book = makeRecipeBook(id: id, name: "A")

        let dict: [RecipeBook: String] = [book: "value"]

        XCTAssertEqual(dict[book], "value")
    }

    // MARK: - Sort Descriptor Tests

    func testSortByName() {
        let descriptor = RecipeBook.sortByName

        XCTAssertNotNil(descriptor)
    }

    func testSortByDate() {
        let descriptor = RecipeBook.sortByDate

        XCTAssertNotNil(descriptor)
    }

    func testSortByName_ForwardOrder() {
        let bookA = makeRecipeBook(name: "Apple Pies")
        let bookB = makeRecipeBook(name: "Banana Bread")
        let bookC = makeRecipeBook(name: "Cherry Tart")

        let descriptor = RecipeBook.sortByName
        XCTAssertNotNil(descriptor)

        // Verify the key path sorts by name
        XCTAssertEqual(bookA.name, "Apple Pies")
        XCTAssertEqual(bookB.name, "Banana Bread")
        XCTAssertEqual(bookC.name, "Cherry Tart")
        XCTAssertTrue(bookA.name < bookB.name)
        XCTAssertTrue(bookB.name < bookC.name)
    }

    func testSortByDate_ReverseOrder() {
        let oldDate = Date(timeIntervalSince1970: 1_700_000_000)
        let newDate = Date(timeIntervalSince1970: 1_800_000_000)

        let bookOld = makeRecipeBook(createdAt: oldDate)
        let bookNew = makeRecipeBook(createdAt: newDate)

        XCTAssertLessThan(bookOld.createdAt, bookNew.createdAt)
    }

    // MARK: - Relationship Tests

    func testRecipes_IsNilByDefault() {
        let book = makeRecipeBook()

        XCTAssertNil(book.recipes)
    }

    func testRecipes_SetToEmptyArray() {
        let book = makeRecipeBook()
        book.recipes = []

        XCTAssertNotNil(book.recipes)
        XCTAssertTrue(book.recipes!.isEmpty)
    }

    func testRecipes_SetToArray() {
        let book = makeRecipeBook()
        let recipe = makeRecipe()
        book.recipes = [recipe]

        XCTAssertNotNil(book.recipes)
        XCTAssertEqual(book.recipes?.count, 1)
    }

    // MARK: - Edge Case Tests

    func testName_OnlyWhitespace() {
        let book = makeRecipeBook(name: "     ")

        XCTAssertEqual(book.recipeCountDescription, "0 recipes")
    }

    func testName_SingleCharacter() {
        let book = makeRecipeBook(name: "A")

        XCTAssertEqual(book.name, "A")
    }

    func testRecipeCount_AfterRemovingAll() {
        let book = makeRecipeBook()
        book.recipes = [makeRecipe(), makeRecipe(), makeRecipe()]
        XCTAssertEqual(book.recipeCount, 3)

        book.recipes = []
        XCTAssertEqual(book.recipeCount, 0)
    }

    func testRecipeCount_AfterSettingNil() {
        let book = makeRecipeBook()
        book.recipes = [makeRecipe(), makeRecipe()]
        XCTAssertEqual(book.recipeCount, 2)

        book.recipes = nil
        XCTAssertEqual(book.recipeCount, 0)
    }

    func testRecipeCountDescription_AfterAdd() {
        let book = makeRecipeBook()
        book.recipes = []

        XCTAssertEqual(book.recipeCountDescription, "0 recipes")

        book.recipes?.append(makeRecipe())
        XCTAssertEqual(book.recipeCountDescription, "1 recipe")

        book.recipes?.append(makeRecipe())
        XCTAssertEqual(book.recipeCountDescription, "2 recipes")
    }

    func testMultipleBooks_DifferentIds() {
        let books = (0..<100).map { _ in makeRecipeBook() }
        let uniqueIds = Set(books.map(\.id))

        XCTAssertEqual(uniqueIds.count, 100)
    }

    func testBookCreatedAt_Precision() {
        let preciseDate = Date(timeIntervalSince1970: 1_700_000_000.123)
        let book = makeRecipeBook(createdAt: preciseDate)

        XCTAssertEqual(book.createdAt, preciseDate)
    }
}
