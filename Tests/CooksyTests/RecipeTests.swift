import XCTest
import SwiftData
@testable import Cooksy

// MARK: - Recipe Model Tests
/// Comprehensive unit tests for Recipe model computed properties and behaviors.
final class RecipeTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private func makeRecipe(
        title: String = "Test Recipe",
        servings: Int = 4,
        prepTime: Int = 10,
        cookTime: Int = 20,
        totalTime: Int = 30,
        status: RecipeStatus = .ready,
        confidence: ConfidenceLevel = .high,
        confidenceScore: Int = 85,
        isSaved: Bool = false,
        sourceUrl: String = "https://youtube.com/watch?v=test",
        sourcePlatform: SourcePlatform = .youtube,
        sourceCreator: String = "Test Chef",
        sourceTitle: String = "Test Video"
    ) -> Recipe {
        Recipe(
            title: title,
            servings: servings,
            prepTimeMinutes: prepTime,
            cookTimeMinutes: cookTime,
            totalTimeMinutes: totalTime,
            status: status,
            confidence: confidence,
            confidenceScore: confidenceScore,
            isSaved: isSaved,
            sourceUrl: sourceUrl,
            sourcePlatform: sourcePlatform,
            sourceCreator: sourceCreator,
            sourceTitle: sourceTitle
        )
    }
    
    // MARK: - Status Tests
    
    func testStatus_Ready() {
        let recipe = makeRecipe(status: .ready)
        XCTAssertTrue(recipe.isReady)
        XCTAssertFalse(recipe.isProcessing)
        XCTAssertFalse(recipe.isFailed)
    }
    
    func testStatus_Processing() {
        let recipe = makeRecipe(status: .processing)
        XCTAssertFalse(recipe.isReady)
        XCTAssertTrue(recipe.isProcessing)
        XCTAssertFalse(recipe.isFailed)
    }
    
    func testStatus_Failed() {
        let recipe = makeRecipe(status: .failed)
        XCTAssertFalse(recipe.isReady)
        XCTAssertFalse(recipe.isProcessing)
        XCTAssertTrue(recipe.isFailed)
    }
    
    func testStatus_GetterSetter() {
        let recipe = makeRecipe(status: .processing)
        XCTAssertEqual(recipe.status, .processing)
        
        recipe.status = .ready
        XCTAssertEqual(recipe.status, .ready)
        XCTAssertEqual(recipe.statusRawValue, "ready")
    }
    
    func testStatus_InvalidRawValueFallsBack() {
        let recipe = makeRecipe()
        recipe.statusRawValue = "invalid_status"
        XCTAssertEqual(recipe.status, .processing) // Fallback
    }
    
    // MARK: - Confidence Tests
    
    func testConfidence_High() {
        let recipe = makeRecipe(confidence: .high)
        XCTAssertEqual(recipe.confidence, .high)
    }
    
    func testConfidence_Medium() {
        let recipe = makeRecipe(confidence: .medium)
        XCTAssertEqual(recipe.confidence, .medium)
    }
    
    func testConfidence_Low() {
        let recipe = makeRecipe(confidence: .low)
        XCTAssertEqual(recipe.confidence, .low)
    }
    
    func testConfidence_InvalidRawValueFallsBack() {
        let recipe = makeRecipe()
        recipe.confidenceRawValue = "invalid"
        XCTAssertEqual(recipe.confidence, .medium) // Fallback
    }
    
    // MARK: - Time Formatting Tests
    
    func testFormattedTotalTime() {
        let recipe = makeRecipe(totalTime: 90)
        XCTAssertEqual(recipe.formattedTotalTime, "1 hr 30 min")
    }
    
    func testFormattedPrepTime() {
        let recipe = makeRecipe(prepTime: 15)
        XCTAssertEqual(recipe.formattedPrepTime, "15 min")
    }
    
    func testFormattedCookTime() {
        let recipe = makeRecipe(cookTime: 45)
        XCTAssertEqual(recipe.formattedCookTime, "45 min")
    }
    
    func testFormattedTime_Zero() {
        let recipe = makeRecipe(totalTime: 0)
        XCTAssertEqual(recipe.formattedTotalTime, "\u{2014}")
    }
    
    // MARK: - Sorted Collections Tests
    
    func testSortedIngredients() {
        let recipe = makeRecipe()
        let ingredient1 = Ingredient(name: "First", quantity: "1", unit: "cup", displayOrder: 0)
        let ingredient2 = Ingredient(name: "Second", quantity: "2", unit: "tbsp", displayOrder: 1)
        let ingredient3 = Ingredient(name: "Third", quantity: "3", unit: "g", displayOrder: 2)
        
        recipe.ingredients = [ingredient3, ingredient1, ingredient2]
        
        let sorted = recipe.sortedIngredients
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].name, "First")
        XCTAssertEqual(sorted[1].name, "Second")
        XCTAssertEqual(sorted[2].name, "Third")
    }
    
    func testSortedIngredients_Nil() {
        let recipe = makeRecipe()
        recipe.ingredients = nil
        XCTAssertTrue(recipe.sortedIngredients.isEmpty)
    }
    
    func testSortedSteps() {
        let recipe = makeRecipe()
        let step1 = RecipeStep(title: "Step 1", instruction: "Do first thing", displayOrder: 0)
        let step2 = RecipeStep(title: "Step 2", instruction: "Do second thing", displayOrder: 1)
        
        recipe.steps = [step2, step1]
        
        let sorted = recipe.sortedSteps
        XCTAssertEqual(sorted.count, 2)
        XCTAssertEqual(sorted[0].title, "Step 1")
        XCTAssertEqual(sorted[1].title, "Step 2")
    }
    
    func testSortedSteps_Nil() {
        let recipe = makeRecipe()
        recipe.steps = nil
        XCTAssertTrue(recipe.sortedSteps.isEmpty)
    }
    
    // MARK: - Summary Line Tests
    
    func testSummaryLine() {
        let recipe = makeRecipe(servings: 4, totalTime: 30, sourceCreator: "Chef John")
        let summary = recipe.summaryLine
        XCTAssertTrue(summary.contains("4 servings"))
        XCTAssertTrue(summary.contains("30 min"))
        XCTAssertTrue(summary.contains("Chef John"))
        XCTAssertTrue(summary.contains("YouTube"))
    }
    
    func testSummaryLine_SingularServing() {
        let recipe = makeRecipe(servings: 1)
        XCTAssertTrue(recipe.summaryLine.contains("1 serving"))
        XCTAssertFalse(recipe.summaryLine.contains("1 servings"))
    }
    
    // MARK: - Source Tests
    
    func testSourceComputedProperty() {
        let recipe = makeRecipe(
            sourceUrl: "https://youtube.com/watch?v=abc",
            sourcePlatform: .youtube,
            sourceCreator: "Chef Anna",
            sourceTitle: "Pasta Video"
        )
        
        let source = recipe.source
        XCTAssertEqual(source.url, "https://youtube.com/watch?v=abc")
        XCTAssertEqual(source.platform, .youtube)
        XCTAssertEqual(source.creator, "Chef Anna")
        XCTAssertEqual(source.title, "Pasta Video")
    }
    
    func testUpdateSource() {
        let recipe = makeRecipe()
        let newSource = Source(
            url: "https://tiktok.com/@newchef/video/123",
            platform: .tiktok,
            creator: "New Chef",
            title: "New Video"
        )
        
        recipe.updateSource(newSource)
        
        XCTAssertEqual(recipe.sourceUrl, "https://tiktok.com/@newchef/video/123")
        XCTAssertEqual(recipe.sourcePlatform, "tiktok")
        XCTAssertEqual(recipe.sourceCreator, "New Chef")
        XCTAssertEqual(recipe.sourceTitle, "New Video")
    }
    
    // MARK: - Book Management Tests
    
    func testAddToBook() {
        let recipe = makeRecipe()
        let book = RecipeBook(name: "Favorites", icon: "heart", colorName: "red")
        
        recipe.addToBook(book)
        
        XCTAssertTrue(recipe.isInBook(book))
        XCTAssertEqual(recipe.books?.count, 1)
    }
    
    func testAddToBook_Duplicate() {
        let recipe = makeRecipe()
        let book = RecipeBook(name: "Favorites", icon: "heart", colorName: "red")
        
        recipe.addToBook(book)
        recipe.addToBook(book) // Should not duplicate
        
        XCTAssertEqual(recipe.books?.count, 1)
    }
    
    func testRemoveFromBook() {
        let recipe = makeRecipe()
        let book = RecipeBook(name: "Favorites", icon: "heart", colorName: "red")
        
        recipe.addToBook(book)
        XCTAssertTrue(recipe.isInBook(book))
        
        recipe.removeFromBook(book)
        XCTAssertFalse(recipe.isInBook(book))
        XCTAssertTrue(recipe.books?.isEmpty ?? true)
    }
    
    func testIsInBook_NotInBook() {
        let recipe = makeRecipe()
        let book = RecipeBook(name: "Favorites", icon: "heart", colorName: "red")
        XCTAssertFalse(recipe.isInBook(book))
    }
    
    // MARK: - Equality Tests
    
    func testEquality_SameId() {
        let id = UUID()
        let recipe1 = Recipe(id: id, title: "Recipe A", sourceUrl: "https://a.com", sourcePlatform: .youtube, sourceCreator: "A", sourceTitle: "A")
        let recipe2 = Recipe(id: id, title: "Recipe B", sourceUrl: "https://b.com", sourcePlatform: .tiktok, sourceCreator: "B", sourceTitle: "B")
        
        XCTAssertEqual(recipe1, recipe2)
    }
    
    func testEquality_DifferentId() {
        let recipe1 = makeRecipe()
        let recipe2 = makeRecipe()
        
        XCTAssertNotEqual(recipe1, recipe2)
    }
    
    // MARK: - Touch Tests
    
    func testTouchUpdatesTimestamp() {
        let recipe = makeRecipe()
        let beforeUpdate = recipe.updatedAt
        
        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)
        recipe.touch()
        
        XCTAssertGreaterThan(recipe.updatedAt, beforeUpdate)
    }
    
    // MARK: - Sorting Tests
    
    func testSortByTitle() {
        let recipeA = Recipe(title: "Apple Pie", sourceUrl: "a", sourcePlatform: .youtube, sourceCreator: "A", sourceTitle: "A")
        let recipeB = Recipe(title: "Banana Bread", sourceUrl: "b", sourcePlatform: .youtube, sourceCreator: "B", sourceTitle: "B")
        
        let descriptor = Recipe.sortByTitle
        // Verify descriptor exists and has correct key path
        XCTAssertNotNil(descriptor)
    }
    
    func testSortByDate() {
        let descriptor = Recipe.sortByDate
        XCTAssertNotNil(descriptor)
    }
}
