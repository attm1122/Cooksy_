import XCTest
@testable import Cooksy

// MARK: - RecipeStep Model Tests
/// Comprehensive unit tests for the RecipeStep model covering all initializers,
/// stored properties, computed properties, Equatable/Hashable conformance, and edge cases.
final class RecipeStepTests: XCTestCase {

    // MARK: - Factory Helpers

    private func makeRecipeStep(
        id: UUID = UUID(),
        title: String = "Preheat",
        instruction: String = "Preheat your oven to 425°F.",
        durationMinutes: Int? = 15,
        displayOrder: Int = 0
    ) -> RecipeStep {
        RecipeStep(
            id: id,
            title: title,
            instruction: instruction,
            durationMinutes: durationMinutes,
            displayOrder: displayOrder
        )
    }

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let step = RecipeStep(title: "Mix", instruction: "Mix all ingredients.")

        XCTAssertEqual(step.title, "Mix")
        XCTAssertEqual(step.instruction, "Mix all ingredients.")
        XCTAssertNil(step.durationMinutes)
        XCTAssertEqual(step.displayOrder, 0)
        XCTAssertNotNil(step.id)
    }

    func testInit_WithAllValues() {
        let id = UUID()
        let step = makeRecipeStep(
            id: id,
            title: "Bake",
            instruction: "Bake for 30 minutes until golden brown.",
            durationMinutes: 30,
            displayOrder: 2
        )

        XCTAssertEqual(step.id, id)
        XCTAssertEqual(step.title, "Bake")
        XCTAssertEqual(step.instruction, "Bake for 30 minutes until golden brown.")
        XCTAssertEqual(step.durationMinutes, 30)
        XCTAssertEqual(step.displayOrder, 2)
    }

    func testInit_WithNilDuration() {
        let step = makeRecipeStep(title: "Serve", instruction: "Serve immediately.", durationMinutes: nil)

        XCTAssertNil(step.durationMinutes)
    }

    func testInit_WithEmptyStrings() {
        let step = makeRecipeStep(title: "", instruction: "", durationMinutes: nil)

        XCTAssertEqual(step.title, "")
        XCTAssertEqual(step.instruction, "")
    }

    func testInit_NegativeDisplayOrder() {
        let step = makeRecipeStep(displayOrder: -1)

        XCTAssertEqual(step.displayOrder, -1)
    }

    func testInit_UnicodeTitle() {
        let step = makeRecipeStep(title: "準備", instruction: "食材を切ります。")

        XCTAssertEqual(step.title, "準備")
        XCTAssertEqual(step.instruction, "食材を切ります。")
    }

    func testInit_LargeDisplayOrder() {
        let step = makeRecipeStep(displayOrder: 999)

        XCTAssertEqual(step.displayOrder, 999)
    }

    func testInit_ZeroDuration() {
        let step = makeRecipeStep(durationMinutes: 0)

        XCTAssertEqual(step.durationMinutes, 0)
    }

    // MARK: - Stored Property Tests

    func testTitle_IsStored() {
        let step = makeRecipeStep(title: "Chop vegetables")

        XCTAssertEqual(step.title, "Chop vegetables")
    }

    func testInstruction_IsStored() {
        let step = makeRecipeStep(instruction: "Chop the onions finely.")

        XCTAssertEqual(step.instruction, "Chop the onions finely.")
    }

    func testDurationMinutes_IsStored() {
        let step = makeRecipeStep(durationMinutes: 45)

        XCTAssertEqual(step.durationMinutes, 45)
    }

    func testDisplayOrder_IsStored() {
        let step = makeRecipeStep(displayOrder: 3)

        XCTAssertEqual(step.displayOrder, 3)
    }

    func testTitle_Mutation() {
        let step = makeRecipeStep(title: "Old Title")
        step.title = "New Title"

        XCTAssertEqual(step.title, "New Title")
    }

    func testInstruction_Mutation() {
        let step = makeRecipeStep(instruction: "Old instruction.")
        step.instruction = "New instruction."

        XCTAssertEqual(step.instruction, "New instruction.")
    }

    func testDurationMinutes_Mutation() {
        let step = makeRecipeStep(durationMinutes: 10)
        step.durationMinutes = 20

        XCTAssertEqual(step.durationMinutes, 20)
    }

    func testDurationMinutes_MutationToNil() {
        let step = makeRecipeStep(durationMinutes: 10)
        step.durationMinutes = nil

        XCTAssertNil(step.durationMinutes)
    }

    func testDisplayOrder_Mutation() {
        let step = makeRecipeStep(displayOrder: 0)
        step.displayOrder = 5

        XCTAssertEqual(step.displayOrder, 5)
    }

    // MARK: - formattedDuration Computed Property Tests

    func testFormattedDuration_Under60Minutes() {
        let step = makeRecipeStep(durationMinutes: 45)

        XCTAssertEqual(step.formattedDuration, "45 min")
    }

    func testFormattedDuration_Exactly60Minutes() {
        let step = makeRecipeStep(durationMinutes: 60)

        XCTAssertEqual(step.formattedDuration, "1 hr")
    }

    func testFormattedDuration_Exactly90Minutes() {
        let step = makeRecipeStep(durationMinutes: 90)

        XCTAssertEqual(step.formattedDuration, "1 hr 30 min")
    }

    func testFormattedDuration_MultipleHours() {
        let step = makeRecipeStep(durationMinutes: 150)

        XCTAssertEqual(step.formattedDuration, "2 hr 30 min")
    }

    func testFormattedDuration_OneHourExactly() {
        let step = makeRecipeStep(durationMinutes: 60)

        XCTAssertEqual(step.formattedDuration, "1 hr")
    }

    func testFormattedDuration_TwoHoursExactly() {
        let step = makeRecipeStep(durationMinutes: 120)

        XCTAssertEqual(step.formattedDuration, "2 hr")
    }

    func testFormattedDuration_Nil() {
        let step = makeRecipeStep(durationMinutes: nil)

        XCTAssertEqual(step.formattedDuration, "No time estimate")
    }

    func testFormattedDuration_ZeroMinutes() {
        let step = makeRecipeStep(durationMinutes: 0)

        XCTAssertEqual(step.formattedDuration, "0 min")
    }

    func testFormattedDuration_OneMinute() {
        let step = makeRecipeStep(durationMinutes: 1)

        XCTAssertEqual(step.formattedDuration, "1 min")
    }

    func testFormattedDuration_59Minutes() {
        let step = makeRecipeStep(durationMinutes: 59)

        XCTAssertEqual(step.formattedDuration, "59 min")
    }

    func testFormattedDuration_61Minutes() {
        let step = makeRecipeStep(durationMinutes: 61)

        XCTAssertEqual(step.formattedDuration, "1 hr 1 min")
    }

    func testFormattedDuration_LargeDuration() {
        let step = makeRecipeStep(durationMinutes: 1000)

        XCTAssertEqual(step.formattedDuration, "16 hr 40 min")
    }

    // MARK: - stepLabel Computed Property Tests

    func testStepLabel_FirstStep() {
        let step = makeRecipeStep(title: "Preheat", displayOrder: 0)

        XCTAssertEqual(step.stepLabel, "Step 1: Preheat")
    }

    func testStepLabel_SecondStep() {
        let step = makeRecipeStep(title: "Mix", displayOrder: 1)

        XCTAssertEqual(step.stepLabel, "Step 2: Mix")
    }

    func testStepLabel_TenthStep() {
        let step = makeRecipeStep(title: "Serve", displayOrder: 9)

        XCTAssertEqual(step.stepLabel, "Step 10: Serve")
    }

    func testStepLabel_LargeOrder() {
        let step = makeRecipeStep(title: "Enjoy", displayOrder: 99)

        XCTAssertEqual(step.stepLabel, "Step 100: Enjoy")
    }

    func testStepLabel_EmptyTitle() {
        let step = makeRecipeStep(title: "", displayOrder: 0)

        XCTAssertEqual(step.stepLabel, "Step 1: ")
    }

    func testStepLabel_UnicodeTitle() {
        let step = makeRecipeStep(title: "炒める", displayOrder: 2)

        XCTAssertEqual(step.stepLabel, "Step 3: 炒める")
    }

    func testStepLabel_ZeroDisplayOrder() {
        let step = makeRecipeStep(displayOrder: 0)

        XCTAssertEqual(step.stepLabel, "Step 1: Preheat")
    }

    func testStepLabel_NegativeDisplayOrder() {
        let step = makeRecipeStep(displayOrder: -1)

        XCTAssertEqual(step.stepLabel, "Step 0: Preheat")
    }

    // MARK: - Equatable Tests

    func testEquality_SameId() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, title: "A", instruction: "Do A.")
        let step2 = makeRecipeStep(id: id, title: "B", instruction: "Do B.")

        XCTAssertEqual(step1, step2)
    }

    func testEquality_DifferentId() {
        let step1 = makeRecipeStep(title: "Same Title")
        let step2 = makeRecipeStep(title: "Same Title")

        XCTAssertNotEqual(step1, step2)
    }

    func testEquality_SameIdDifferentTitle() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, title: "Title A")
        let step2 = makeRecipeStep(id: id, title: "Title B")

        XCTAssertEqual(step1, step2)
    }

    func testEquality_SameIdDifferentInstruction() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, instruction: "Instruction A.")
        let step2 = makeRecipeStep(id: id, instruction: "Instruction B.")

        XCTAssertEqual(step1, step2)
    }

    func testEquality_SameIdDifferentDuration() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, durationMinutes: 10)
        let step2 = makeRecipeStep(id: id, durationMinutes: 100)

        XCTAssertEqual(step1, step2)
    }

    func testEquality_SameIdDifferentDisplayOrder() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, displayOrder: 0)
        let step2 = makeRecipeStep(id: id, displayOrder: 99)

        XCTAssertEqual(step1, step2)
    }

    // MARK: - Hashable Tests

    func testHashable_SameId() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, title: "A")
        let step2 = makeRecipeStep(id: id, title: "B")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        step1.hash(into: &hasher1)
        step2.hash(into: &hasher2)

        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_DifferentId() {
        let step1 = makeRecipeStep(title: "A")
        let step2 = makeRecipeStep(title: "A")

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        step1.hash(into: &hasher1)
        step2.hash(into: &hasher2)

        XCTAssertNotEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testHashable_UsedInSet() {
        let id = UUID()
        let step1 = makeRecipeStep(id: id, title: "A")
        let step2 = makeRecipeStep(id: id, title: "B")

        let set: Set<RecipeStep> = [step1, step2]

        XCTAssertEqual(set.count, 1)
    }

    func testHashable_UsedInDictionary() {
        let id = UUID()
        let step = makeRecipeStep(id: id, title: "A")

        let dict: [RecipeStep: String] = [step: "value"]

        XCTAssertEqual(dict[step], "value")
    }

    // MARK: - Identity Tests

    func testId_IsUnique() {
        let step1 = makeRecipeStep()
        let step2 = makeRecipeStep()

        XCTAssertNotEqual(step1.id, step2.id)
    }

    func testId_IsStable() {
        let step = makeRecipeStep()
        let originalId = step.id

        step.title = "Changed"
        step.instruction = "Changed too."

        XCTAssertEqual(step.id, originalId)
    }

    // MARK: - Relationship Tests

    func testRecipe_IsNilByDefault() {
        let step = makeRecipeStep()

        XCTAssertNil(step.recipe)
    }

    // MARK: - Edge Case Tests

    func testFormattedDuration_NegativeMinutes() {
        let step = makeRecipeStep(durationMinutes: -5)

        // Negative values: less than 60, so returns "-5 min"
        XCTAssertEqual(step.formattedDuration, "-5 min")
    }

    func testInstruction_VeryLong() {
        let longInstruction = String(repeating: "Chop carefully. ", count: 100)
        let step = makeRecipeStep(instruction: longInstruction)

        XCTAssertEqual(step.instruction, longInstruction)
    }

    func testTitle_VeryLong() {
        let longTitle = String(repeating: "a", count: 500)
        let step = makeRecipeStep(title: longTitle)

        XCTAssertEqual(step.title, longTitle)
        XCTAssertTrue(step.stepLabel.contains(longTitle))
    }

    func testDisplayOrder_MaxInt() {
        let step = makeRecipeStep(displayOrder: Int.max)

        XCTAssertEqual(step.displayOrder, Int.max)
        XCTAssertEqual(step.stepLabel, "Step \(Int.max + 1): Preheat")
    }

    func testDisplayOrder_MinInt() {
        let step = makeRecipeStep(displayOrder: Int.min)

        XCTAssertEqual(step.displayOrder, Int.min)
    }

    func testStepLabel_WithSpecialCharacters() {
        let step = makeRecipeStep(title: "Mix & Match! (Carefully)", displayOrder: 0)

        XCTAssertEqual(step.stepLabel, "Step 1: Mix & Match! (Carefully)")
    }

    func testStepLabel_WithEmoji() {
        let step = makeRecipeStep(title: "🔥 Sear the steak", displayOrder: 0)

        XCTAssertEqual(step.stepLabel, "Step 1: 🔥 Sear the steak")
    }

    func testFormattedDuration_NilAfterMutation() {
        let step = makeRecipeStep(durationMinutes: 30)
        XCTAssertEqual(step.formattedDuration, "30 min")

        step.durationMinutes = nil
        XCTAssertEqual(step.formattedDuration, "No time estimate")
    }

    func testFormattedDuration_ChangesAfterMutation() {
        let step = makeRecipeStep(durationMinutes: 30)
        XCTAssertEqual(step.formattedDuration, "30 min")

        step.durationMinutes = 90
        XCTAssertEqual(step.formattedDuration, "1 hr 30 min")
    }

    func testInit_TypicalRecipeSteps() {
        let step1 = makeRecipeStep(
            title: "Preheat",
            instruction: "Preheat your oven to 425°F (220°C).",
            durationMinutes: 15,
            displayOrder: 0
        )
        let step2 = makeRecipeStep(
            title: "Mix Dry Ingredients",
            instruction: "Combine flour, salt, and baking powder in a large bowl.",
            durationMinutes: 5,
            displayOrder: 1
        )
        let step3 = makeRecipeStep(
            title: "Serve",
            instruction: "Plate and serve immediately while hot.",
            durationMinutes: nil,
            displayOrder: 2
        )

        XCTAssertEqual(step1.displayOrder, 0)
        XCTAssertEqual(step2.displayOrder, 1)
        XCTAssertEqual(step3.displayOrder, 2)
        XCTAssertEqual(step1.formattedDuration, "15 min")
        XCTAssertEqual(step2.formattedDuration, "5 min")
        XCTAssertEqual(step3.formattedDuration, "No time estimate")
    }
}
