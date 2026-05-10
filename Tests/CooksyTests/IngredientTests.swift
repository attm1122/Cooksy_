import XCTest
@testable import Cooksy

// MARK: - Ingredient Model Tests
/// Comprehensive unit tests for the Ingredient model covering all initializers,
/// stored properties, computed properties, Equatable/Hashable conformance, and edge cases.
final class IngredientTests: XCTestCase {

    // MARK: - Factory Helpers

    private func makeIngredient(
        id: UUID = UUID(),
        name: String = "All-purpose flour",
        quantity: String? = "2",
        unit: String? = "cups",
        isChecked: Bool = false,
        displayOrder: Int = 0
    ) -> Ingredient {
        Ingredient(
            id: id,
            name: name,
            quantity: quantity,
            unit: unit,
            isChecked: isChecked,
            displayOrder: displayOrder
        )
    }

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let ingredient = Ingredient(name: "Salt")

        XCTAssertFalse(ingredient.name.isEmpty)
        XCTAssertEqual(ingredient.name, "Salt")
        XCTAssertNil(ingredient.quantity)
        XCTAssertNil(ingredient.unit)
        XCTAssertFalse(ingredient.isChecked)
        XCTAssertEqual(ingredient.displayOrder, 0)
        XCTAssertNotNil(ingredient.id)
    }

    func testInit_WithAllValues() {
        let id = UUID()
        let ingredient = makeIngredient(
            id: id,
            name: "Olive oil",
            quantity: "3",
            unit: "tablespoons",
            isChecked: true,
            displayOrder: 5
        )

        XCTAssertEqual(ingredient.id, id)
        XCTAssertEqual(ingredient.name, "Olive oil")
        XCTAssertEqual(ingredient.quantity, "3")
        XCTAssertEqual(ingredient.unit, "tablespoons")
        XCTAssertTrue(ingredient.isChecked)
        XCTAssertEqual(ingredient.displayOrder, 5)
    }

    func testInit_WithNilQuantity() {
        let ingredient = makeIngredient(name: "Salt", quantity: nil, unit: nil)

        XCTAssertEqual(ingredient.name, "Salt")
        XCTAssertNil(ingredient.quantity)
        XCTAssertNil(ingredient.unit)
    }

    func testInit_WithEmptyStrings() {
        let ingredient = makeIngredient(name: "", quantity: "", unit: "")

        XCTAssertEqual(ingredient.name, "")
        XCTAssertEqual(ingredient.quantity, "")
        XCTAssertEqual(ingredient.unit, "")
    }

    func testInit_NegativeDisplayOrder() {
        let ingredient = makeIngredient(name: "Eggs", displayOrder: -1)

        XCTAssertEqual(ingredient.displayOrder, -1)
    }

    func testInit_UnicodeName() {
        let ingredient = makeIngredient(name: "こんにちは", quantity: "1", unit: "個")

        XCTAssertEqual(ingredient.name, "こんにちは")
        XCTAssertEqual(ingredient.quantity, "1")
        XCTAssertEqual(ingredient.unit, "個")
    }

    func testInit_LargeDisplayOrder() {
        let ingredient = makeIngredient(name: "Vanilla", displayOrder: 999)

        XCTAssertEqual(ingredient.displayOrder, 999)
    }

    // MARK: - Stored Property Tests

    func testName_IsStored() {
        let ingredient = makeIngredient(name: "Sugar")

        XCTAssertEqual(ingredient.name, "Sugar")
    }

    func testQuantity_IsStored() {
        let ingredient = makeIngredient(quantity: "1/2")

        XCTAssertEqual(ingredient.quantity, "1/2")
    }

    func testUnit_IsStored() {
        let ingredient = makeIngredient(unit: "grams")

        XCTAssertEqual(ingredient.unit, "grams")
    }

    func testIsChecked_IsStored() {
        let ingredient = makeIngredient(isChecked: true)

        XCTAssertTrue(ingredient.isChecked)
    }

    func testDisplayOrder_IsStored() {
        let ingredient = makeIngredient(displayOrder: 3)

        XCTAssertEqual(ingredient.displayOrder, 3)
    }

    func testName_Mutation() {
        let ingredient = makeIngredient(name: "Old Name")
        ingredient.name = "New Name"

        XCTAssertEqual(ingredient.name, "New Name")
    }

    func testQuantity_Mutation() {
        let ingredient = makeIngredient(quantity: "1")
        ingredient.quantity = "2"

        XCTAssertEqual(ingredient.quantity, "2")
    }

    func testQuantity_MutationToNil() {
        let ingredient = makeIngredient(quantity: "1")
        ingredient.quantity = nil

        XCTAssertNil(ingredient.quantity)
    }

    func testUnit_Mutation() {
        let ingredient = makeIngredient(unit: "cups")
        ingredient.unit = "ml"

        XCTAssertEqual(ingredient.unit, "ml")
    }

    func testIsChecked_Mutation() {
        let ingredient = makeIngredient(isChecked: false)
        ingredient.isChecked = true

        XCTAssertTrue(ingredient.isChecked)
    }

    func testDisplayOrder_Mutation() {
        let ingredient = makeIngredient(displayOrder: 0)
        ingredient.displayOrder = 10

        XCTAssertEqual(ingredient.displayOrder, 10)
    }

    // MARK: - displayText Computed Property Tests

    func testDisplayText_AllFields() {
        let ingredient = makeIngredient(name: "flour", quantity: "2", unit: "cups")

        XCTAssertEqual(ingredient.displayText, "2 cups flour")
    }

    func testDisplayText_NameOnly() {
        let ingredient = makeIngredient(name: "Salt", quantity: nil, unit: nil)

        XCTAssertEqual(ingredient.displayText, "Salt")
    }

    func testDisplayText_NameAndQuantityOnly() {
        let ingredient = makeIngredient(name: "eggs", quantity: "3", unit: nil)

        XCTAssertEqual(ingredient.displayText, "3 eggs")
    }

    func testDisplayText_NameAndUnitOnly() {
        let ingredient = makeIngredient(name: "milk", quantity: nil, unit: "cup")

        XCTAssertEqual(ingredient.displayText, "cup milk")
    }

    func testDisplayText_EmptyQuantity() {
        let ingredient = makeIngredient(name: "pepper", quantity: "", unit: "tsp")

        XCTAssertEqual(ingredient.displayText, "tsp pepper")
    }

    func testDisplayText_EmptyUnit() {
        let ingredient = makeIngredient(name: "water", quantity: "1", unit: "")

        XCTAssertEqual(ingredient.displayText, "1 water")
    }

    func testDisplayText_BothEmpty() {
        let ingredient = makeIngredient(name: "ice", quantity: "", unit: "")

        XCTAssertEqual(ingredient.displayText, "ice")
    }

    func testDisplayText_FractionalQuantity() {
        let ingredient = makeIngredient(name: "sugar", quantity: "1/2", unit: "cup")

        XCTAssertEqual(ingredient.displayText, "1/2 cup sugar")
    }

    func testDisplayText_RangeQuantity() {
        let ingredient = makeIngredient(name: "tomatoes", quantity: "3-4", unit: nil)

        XCTAssertEqual(ingredient.displayText, "3-4 tomatoes")
    }

    func testDisplayText_VerbalQuantity() {
        let ingredient = makeIngredient(name: "paprika", quantity: "a pinch", unit: nil)

        XCTAssertEqual(ingredient.displayText, "a pinch paprika")
    }

    // MARK: - shortDisplayText Computed Property Tests

    func testShortDisplayText_AllFields() {
        let ingredient = makeIngredient(name: "flour", quantity: "2", unit: "cups")

        XCTAssertEqual(ingredient.shortDisplayText, "2 cups")
    }

    func testShortDisplayText_QuantityOnly() {
        let ingredient = makeIngredient(name: "Salt", quantity: "1", unit: nil)

        XCTAssertEqual(ingredient.shortDisplayText, "1")
    }

    func testShortDisplayText_NameOnly() {
        let ingredient = makeIngredient(name: "Olive oil", quantity: nil, unit: nil)

        XCTAssertEqual(ingredient.shortDisplayText, "Olive oil")
    }

    func testShortDisplayText_EmptyQuantity() {
        let ingredient = makeIngredient(name: "butter", quantity: "", unit: "tbsp")

        XCTAssertEqual(ingredient.shortDisplayText, "butter")
    }

    func testShortDisplayText_EmptyUnit() {
        let ingredient = makeIngredient(name: "garlic", quantity: "3", unit: "")

        XCTAssertEqual(ingredient.shortDisplayText, "3")
    }

    func testShortDisplayText_BothEmpty() {
        let ingredient = makeIngredient(name: "vanilla", quantity: "", unit: "")

        XCTAssertEqual(ingredient.shortDisplayText, "vanilla")
    }

    // MARK: - isChecked Toggle Tests

    func testIsChecked_ToggleFalseToTrue() {
        let ingredient = makeIngredient(isChecked: false)
        ingredient.isChecked = true

        XCTAssertTrue(ingredient.isChecked)
    }

    func testIsChecked_ToggleTrueToFalse() {
        let ingredient = makeIngredient(isChecked: true)
        ingredient.isChecked = false

        XCTAssertFalse(ingredient.isChecked)
    }

    // MARK: - Equatable Tests

    func testEquality_SameId() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, name: "Flour", quantity: "2", unit: "cups")
        let ingredient2 = makeIngredient(id: id, name: "Sugar", quantity: "1", unit: "tbsp")

        XCTAssertEqual(ingredient1, ingredient2)
    }

    func testEquality_DifferentId() {
        let ingredient1 = makeIngredient(name: "Flour")
        let ingredient2 = makeIngredient(name: "Flour")

        XCTAssertNotEqual(ingredient1, ingredient2)
    }

    func testEquality_SameIdDifferentName() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, name: "A")
        let ingredient2 = makeIngredient(id: id, name: "B")

        XCTAssertEqual(ingredient1, ingredient2)
    }

    func testEquality_SameIdDifferentQuantity() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, quantity: "1")
        let ingredient2 = makeIngredient(id: id, quantity: "100")

        XCTAssertEqual(ingredient1, ingredient2)
    }

    func testEquality_SameIdDifferentIsChecked() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, isChecked: false)
        let ingredient2 = makeIngredient(id: id, isChecked: true)

        XCTAssertEqual(ingredient1, ingredient2)
    }

    func testEquality_SameIdDifferentDisplayOrder() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, displayOrder: 0)
        let ingredient2 = makeIngredient(id: id, displayOrder: 99)

        XCTAssertEqual(ingredient1, ingredient2)
    }

    // MARK: - Hashable Tests

    func testHashable_SameId() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, name: "A")
        let ingredient2 = makeIngredient(id: id, name: "B")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        ingredient1.hash(into: &hasher1)
        ingredient2.hash(into: &hasher2)

        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_DifferentId() {
        let ingredient1 = makeIngredient(name: "A")
        let ingredient2 = makeIngredient(name: "A")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        ingredient1.hash(into: &hasher1)
        ingredient2.hash(into: &hasher2)

        XCTAssertNotEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_UsedInSet() {
        let id = UUID()
        let ingredient1 = makeIngredient(id: id, name: "A")
        let ingredient2 = makeIngredient(id: id, name: "B")

        let set: Set<Ingredient> = [ingredient1, ingredient2]

        XCTAssertEqual(set.count, 1)
    }

    func testHashable_UsedInDictionary() {
        let id = UUID()
        let ingredient = makeIngredient(id: id, name: "A")

        let dict: [Ingredient: String] = [ingredient: "value"]

        XCTAssertEqual(dict[ingredient], "value")
    }

    // MARK: - Identity Tests

    func testId_IsUnique() {
        let ingredient1 = makeIngredient()
        let ingredient2 = makeIngredient()

        XCTAssertNotEqual(ingredient1.id, ingredient2.id)
    }

    func testId_IsStable() {
        let ingredient = makeIngredient()
        let originalId = ingredient.id

        ingredient.name = "Changed"
        ingredient.isChecked = true

        XCTAssertEqual(ingredient.id, originalId)
    }

    // MARK: - Relationship Tests

    func testRecipe_IsNilByDefault() {
        let ingredient = makeIngredient()

        XCTAssertNil(ingredient.recipe)
    }

    // MARK: - Edge Case Tests

    func testDisplayText_WhitespaceName() {
        let ingredient = makeIngredient(name: "   ")

        XCTAssertEqual(ingredient.displayText, "   ")
    }

    func testDisplayText_SpecialCharactersInName() {
        let ingredient = makeIngredient(name: "Crème fraîche", quantity: "1", unit: "cup")

        XCTAssertEqual(ingredient.displayText, "1 cup Crème fraîche")
    }

    func testDisplayText_EmojiInName() {
        let ingredient = makeIngredient(name: "🌶️ Chili peppers", quantity: "2")

        XCTAssertEqual(ingredient.displayText, "2 🌶️ Chili peppers")
    }

    func testDisplayText_VeryLongName() {
        let longName = String(repeating: "a", count: 1000)
        let ingredient = makeIngredient(name: longName, quantity: "1")

        XCTAssertTrue(ingredient.displayText.hasPrefix("1 "))
        XCTAssertTrue(ingredient.displayText.hasSuffix(longName))
    }

    func testShortDisplayText_VeryLongNameOnly() {
        let longName = String(repeating: "b", count: 1000)
        let ingredient = makeIngredient(name: longName, quantity: nil, unit: nil)

        XCTAssertEqual(ingredient.shortDisplayText, longName)
    }

    func testInit_ZeroDisplayOrder() {
        let ingredient = makeIngredient(displayOrder: 0)

        XCTAssertEqual(ingredient.displayOrder, 0)
    }

    func testInit_MaxIntDisplayOrder() {
        let ingredient = makeIngredient(displayOrder: Int.max)

        XCTAssertEqual(ingredient.displayOrder, Int.max)
    }

    func testInit_MinIntDisplayOrder() {
        let ingredient = makeIngredient(displayOrder: Int.min)

        XCTAssertEqual(ingredient.displayOrder, Int.min)
    }

    func testQuantity_ToTaste() {
        let ingredient = makeIngredient(name: "Salt", quantity: "to taste", unit: nil)

        XCTAssertEqual(ingredient.displayText, "to taste Salt")
        XCTAssertEqual(ingredient.shortDisplayText, "to taste")
    }
}
