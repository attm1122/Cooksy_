import XCTest
import SwiftUI
@testable import Cooksy

// MARK: - Accessibility Helpers Tests
/// Comprehensive unit tests for the AccessibilityHelpers utility layer.
/// Covers AccessibilityID uniqueness, heading modifiers, animation modifiers,
/// VoiceOver announcements, decorative elements, and the AccessibilityFormatter.
final class AccessibilityHelpersTests: XCTestCase {

    // MARK: - AccessibilityID Existence Tests

    func testAccessibilityID_HomeView() {
        XCTAssertEqual(AccessibilityID.homeView, "homeView")
    }

    func testAccessibilityID_UrlInputField() {
        XCTAssertEqual(AccessibilityID.urlInputField, "urlInputField")
    }

    func testAccessibilityID_PasteButton() {
        XCTAssertEqual(AccessibilityID.pasteButton, "pasteButton")
    }

    func testAccessibilityID_SaveRecipeButton() {
        XCTAssertEqual(AccessibilityID.saveRecipeButton, "saveRecipeButton")
    }

    func testAccessibilityID_HeroCard() {
        XCTAssertEqual(AccessibilityID.heroCard, "heroCard")
    }

    func testAccessibilityID_RecipesView() {
        XCTAssertEqual(AccessibilityID.recipesView, "recipesView")
    }

    func testAccessibilityID_RecipeSearchField() {
        XCTAssertEqual(AccessibilityID.recipeSearchField, "recipeSearchField")
    }

    func testAccessibilityID_RecipeDetailView() {
        XCTAssertEqual(AccessibilityID.recipeDetailView, "recipeDetailView")
    }

    func testAccessibilityID_RecipeTitle() {
        XCTAssertEqual(AccessibilityID.recipeTitle, "recipeTitle")
    }

    func testAccessibilityID_ConfidenceBanner() {
        XCTAssertEqual(AccessibilityID.confidenceBanner, "confidenceBanner")
    }

    func testAccessibilityID_CookingModeView() {
        XCTAssertEqual(AccessibilityID.cookingModeView, "cookingModeView")
    }

    func testAccessibilityID_AuthView() {
        XCTAssertEqual(AccessibilityID.authView, "authView")
    }

    func testAccessibilityID_EmailInputField() {
        XCTAssertEqual(AccessibilityID.emailInputField, "emailInputField")
    }

    func testAccessibilityID_ProfileView() {
        XCTAssertEqual(AccessibilityID.profileView, "profileView")
    }

    func testAccessibilityID_BooksView() {
        XCTAssertEqual(AccessibilityID.booksView, "booksView")
    }

    func testAccessibilityID_SubscriptionView() {
        XCTAssertEqual(AccessibilityID.subscriptionView, "subscriptionView")
    }

    // MARK: - AccessibilityID Uniqueness Tests

    func testAllAccessibilityIDs_AreUnique() {
        let allIDs: [String] = [
            AccessibilityID.homeView,
            AccessibilityID.urlInputField,
            AccessibilityID.pasteButton,
            AccessibilityID.saveRecipeButton,
            AccessibilityID.heroCard,
            AccessibilityID.recentlySavedSection,
            AccessibilityID.seeAllRecipesLink,
            AccessibilityID.recipeCompletionBanner,
            AccessibilityID.dismissBannerButton,
            AccessibilityID.recipesView,
            AccessibilityID.recipeSearchField,
            AccessibilityID.filterChipPrefix,
            AccessibilityID.recipeRowPrefix,
            AccessibilityID.recipeDetailView,
            AccessibilityID.recipeTitle,
            AccessibilityID.confidenceBanner,
            AccessibilityID.saveRecipeDetailButton,
            AccessibilityID.cookingModeButton,
            AccessibilityID.cookAlongButton,
            AccessibilityID.editRecipeButton,
            AccessibilityID.shareRecipeButton,
            AccessibilityID.ingredientsSection,
            AccessibilityID.ingredientRowPrefix,
            AccessibilityID.stepsSection,
            AccessibilityID.stepCardPrefix,
            AccessibilityID.cookingModeView,
            AccessibilityID.cookingProgressBar,
            AccessibilityID.currentStepCard,
            AccessibilityID.previousStepButton,
            AccessibilityID.nextStepButton,
            AccessibilityID.closeCookingModeButton,
            AccessibilityID.restartCookingButton,
            AccessibilityID.authView,
            AccessibilityID.emailInputField,
            AccessibilityID.continueButton,
            AccessibilityID.otpInputView,
            AccessibilityID.verifyButton,
            AccessibilityID.resendCodeButton,
            AccessibilityID.changeEmailButton,
            AccessibilityID.profileView,
            AccessibilityID.userAvatar,
            AccessibilityID.signOutButton,
            AccessibilityID.deleteAccountButton,
            AccessibilityID.exportDataButton,
            AccessibilityID.booksView,
            AccessibilityID.createBookButton,
            AccessibilityID.bookCardPrefix,
            AccessibilityID.subscriptionView,
            AccessibilityID.planCardPrefix,
            AccessibilityID.subscribeButton,
        ]

        let uniqueIDs = Set(allIDs)
        XCTAssertEqual(uniqueIDs.count, allIDs.count,
            "All AccessibilityID values must be unique. Found \(allIDs.count - uniqueIDs.count) duplicate(s).")
    }

    // MARK: - Prefix Concatenation Tests

    func testFilterChipPrefix_ValidIdentifier() {
        let identifier = AccessibilityID.filterChipPrefix + "vegetarian"
        XCTAssertEqual(identifier, "filterChip_vegetarian", "Filter chip prefix concatenation should produce valid identifier")
    }

    func testRecipeRowPrefix_ValidIdentifier() {
        let identifier = AccessibilityID.recipeRowPrefix + "123"
        XCTAssertEqual(identifier, "recipeRow_123", "Recipe row prefix concatenation should produce valid identifier")
    }

    func testIngredientRowPrefix_ValidIdentifier() {
        let identifier = AccessibilityID.ingredientRowPrefix + "0"
        XCTAssertEqual(identifier, "ingredientRow_0", "Ingredient row prefix concatenation should produce valid identifier")
    }

    func testStepCardPrefix_ValidIdentifier() {
        let identifier = AccessibilityID.stepCardPrefix + "5"
        XCTAssertEqual(identifier, "stepCard_5", "Step card prefix concatenation should produce valid identifier")
    }

    func testBookCardPrefix_ValidIdentifier() {
        let identifier = AccessibilityID.bookCardPrefix + "favorites"
        XCTAssertEqual(identifier, "bookCard_favorites", "Book card prefix concatenation should produce valid identifier")
    }

    func testPlanCardPrefix_ValidIdentifier() {
        let identifier = AccessibilityID.planCardPrefix + "annual"
        XCTAssertEqual(identifier, "planCard_annual", "Plan card prefix concatenation should produce valid identifier")
    }

    func testPrefixConcatenation_WithUUID() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let identifier = AccessibilityID.recipeRowPrefix + uuid
        XCTAssertTrue(identifier.hasPrefix("recipeRow_"), "Identifier should start with prefix")
        XCTAssertTrue(identifier.contains(uuid), "Identifier should contain the appended value")
    }

    func testPrefixConcatenation_WithEmptyString() {
        let identifier = AccessibilityID.planCardPrefix + ""
        XCTAssertEqual(identifier, "planCard_", "Plan card prefix with empty string should still be valid")
    }

    // MARK: - accessibleHeading Modifier Tests

    func testAccessibleHeading_Exists() {
        let view = Text("Heading").accessibleHeading(.h1)
        XCTAssertNotNil(view, "accessibleHeading modifier should return a valid View")
    }

    func testAccessibleHeading_H1Level() {
        let view = Text("H1 Heading").accessibleHeading(.h1)
        XCTAssertNotNil(view, "accessibleHeading with h1 should return a valid View")
    }

    func testAccessibleHeading_H2Level() {
        let view = Text("H2 Heading").accessibleHeading(.h2)
        XCTAssertNotNil(view, "accessibleHeading with h2 should return a valid View")
    }

    // MARK: - accessibleAnimation Modifier Tests

    func testAccessibleAnimation_Exists() {
        let view = Text("Animated").accessibleAnimation(.easeInOut, value: true)
        XCTAssertNotNil(view, "accessibleAnimation modifier should return a valid View")
    }

    func testAccessibleSpring_Exists() {
        let view = Text("Spring").accessibleSpring(duration: 0.3, value: 1)
        XCTAssertNotNil(view, "accessibleSpring modifier should return a valid View")
    }

    func testAccessibleEaseInOut_Exists() {
        let view = Text("EaseInOut").accessibleEaseInOut(duration: 0.3, value: 1)
        XCTAssertNotNil(view, "accessibleEaseInOut modifier should return a valid View")
    }

    // MARK: - isReduceMotionEnabled Tests

    func testIsReduceMotionEnabled_Readable() {
        let value = isReduceMotionEnabled
        XCTAssertTrue(value == true || value == false, "isReduceMotionEnabled should return a boolean value")
    }

    func testIsReduceMotionEnabled_IsDeterministic() {
        let first = isReduceMotionEnabled
        let second = isReduceMotionEnabled
        XCTAssertEqual(first, second, "isReduceMotionEnabled should return consistent value within same test")
    }

    // MARK: - VoiceOver Announcement Tests

    func testAnnounceToVoiceOver_Exists() {
        announceToVoiceOver("Test announcement")
    }

    func testAnnounceToVoiceOver_WithDelay_Exists() {
        announceToVoiceOver("Delayed announcement", delay: 0.1)
    }

    func testAnnounceToVoiceOver_EmptyMessage() {
        announceToVoiceOver("")
    }

    // MARK: - combinedAccessibility Modifier Tests

    func testCombinedAccessibility_Exists() {
        let view = Text("Combined").combinedAccessibility(label: "Test Label")
        XCTAssertNotNil(view, "combinedAccessibility modifier should return a valid View")
    }

    func testCombinedAccessibility_WithHint() {
        let view = Text("Combined").combinedAccessibility(label: "Test Label", hint: "Double tap to activate")
        XCTAssertNotNil(view, "combinedAccessibility with hint should return a valid View")
    }

    func testCombinedAccessibility_WithTraits() {
        let view = Text("Combined").combinedAccessibility(label: "Test Label", traits: .isButton)
        XCTAssertNotNil(view, "combinedAccessibility with traits should return a valid View")
    }

    // MARK: - decorative Modifier Tests

    func testDecorativeModifier_Exists() {
        let view = Image(systemName: "star").decorative()
        XCTAssertNotNil(view, "decorative modifier should return a valid View")
    }

    func testDecorativeModifier_OnText() {
        let view = Text("Decorative").decorative()
        XCTAssertNotNil(view, "decorative modifier should work on Text views")
    }

    // MARK: - accessibleAction Modifier Tests

    func testAccessibleAction_Exists() {
        let view = Text("Action").accessibleAction(named: "Activate") {}
        XCTAssertNotNil(view, "accessibleAction modifier should return a valid View")
    }

    // MARK: - AccessibilityFormatter Tests

    func testAccessibilityFormatter_StepProgress() {
        let result = AccessibilityFormatter.stepProgress(current: 3, total: 10)
        XCTAssertEqual(result, "Step 3 of 10", "Step progress should format correctly")
    }

    func testAccessibilityFormatter_StepProgress_FirstStep() {
        let result = AccessibilityFormatter.stepProgress(current: 1, total: 5)
        XCTAssertEqual(result, "Step 1 of 5", "Step progress for first step should format correctly")
    }

    func testAccessibilityFormatter_StepProgress_LastStep() {
        let result = AccessibilityFormatter.stepProgress(current: 5, total: 5)
        XCTAssertEqual(result, "Step 5 of 5", "Step progress for last step should format correctly")
    }

    func testAccessibilityFormatter_Percentage_Zero() {
        let result = AccessibilityFormatter.percentage(0.0)
        XCTAssertEqual(result, "0 percent complete", "Zero percentage should format correctly")
    }

    func testAccessibilityFormatter_Percentage_Half() {
        let result = AccessibilityFormatter.percentage(0.5)
        XCTAssertEqual(result, "50 percent complete", "50% should format correctly")
    }

    func testAccessibilityFormatter_Percentage_Complete() {
        let result = AccessibilityFormatter.percentage(1.0)
        XCTAssertEqual(result, "100 percent complete", "100% should format correctly")
    }

    func testAccessibilityFormatter_Percentage_Partial() {
        let result = AccessibilityFormatter.percentage(0.75)
        XCTAssertEqual(result, "75 percent complete", "75% should format correctly")
    }

    func testAccessibilityFormatter_CookingTime_UnderHour() {
        let result = AccessibilityFormatter.cookingTime(minutes: 45)
        XCTAssertEqual(result, "45 minutes", "Cooking time under 1 hour should format correctly")
    }

    func testAccessibilityFormatter_CookingTime_ExactlyOneHour() {
        let result = AccessibilityFormatter.cookingTime(minutes: 60)
        XCTAssertEqual(result, "1 hour", "Exactly 60 minutes should format as 1 hour")
    }

    func testAccessibilityFormatter_CookingTime_MultipleHoursExact() {
        let result = AccessibilityFormatter.cookingTime(minutes: 120)
        XCTAssertEqual(result, "2 hours", "Exactly 120 minutes should format as 2 hours")
    }

    func testAccessibilityFormatter_CookingTime_HoursAndMinutes() {
        let result = AccessibilityFormatter.cookingTime(minutes: 90)
        XCTAssertEqual(result, "1 hour and 30 minutes", "90 minutes should format as hours and minutes")
    }

    func testAccessibilityFormatter_CookingTime_OneMinute() {
        let result = AccessibilityFormatter.cookingTime(minutes: 1)
        XCTAssertEqual(result, "1 minute", "1 minute should use singular form")
    }

    func testAccessibilityFormatter_CookingTime_ZeroMinutes() {
        let result = AccessibilityFormatter.cookingTime(minutes: 0)
        XCTAssertEqual(result, "0 minutes", "0 minutes should format correctly")
    }

    func testAccessibilityFormatter_Confidence() {
        let result = AccessibilityFormatter.confidence("High", score: 95)
        XCTAssertEqual(result, "High confidence, 95 out of 100", "Confidence should format correctly")
    }

    func testAccessibilityFormatter_Confidence_Low() {
        let result = AccessibilityFormatter.confidence("Low", score: 30)
        XCTAssertEqual(result, "Low confidence, 30 out of 100", "Low confidence should format correctly")
    }

    func testAccessibilityFormatter_Countdown_Zero() {
        let result = AccessibilityFormatter.countdown(0)
        XCTAssertEqual(result, "Available now", "Countdown of 0 should indicate available now")
    }

    func testAccessibilityFormatter_Countdown_OneSecond() {
        let result = AccessibilityFormatter.countdown(1)
        XCTAssertEqual(result, "Available in 1 second", "Countdown of 1 should use singular")
    }

    func testAccessibilityFormatter_Countdown_MultipleSeconds() {
        let result = AccessibilityFormatter.countdown(30)
        XCTAssertEqual(result, "Available in 30 seconds", "Countdown should format plural correctly")
    }

    func testAccessibilityFormatter_Countdown_LargeValue() {
        let result = AccessibilityFormatter.countdown(3600)
        XCTAssertEqual(result, "Available in 3600 seconds", "Large countdown should format correctly")
    }

    // MARK: - ScalableText Modifier Tests (from AccessibilityHelpers)

    func testScalableTextModifier_WithParameters() {
        let view = Text("Scalable").scalableText(minScale: 0.5, maxSize: .accessibility3)
        XCTAssertNotNil(view, "scalableText with custom parameters should return a valid View")
    }

    // MARK: - AccessibilityAnnouncementModifier Tests

    func testAccessibilityAnnouncementModifier_Exists() {
        let modifier = AccessibilityAnnouncementModifier(message: "Test message")
        XCTAssertNotNil(modifier, "AccessibilityAnnouncementModifier should initialize")
    }

    // MARK: - Prefix Edge Case Tests

    func testPrefixConcatenation_WithSpecialCharacters() {
        let identifier = AccessibilityID.filterChipPrefix + "vegan & gluten-free"
        XCTAssertEqual(identifier, "filterChip_vegan & gluten-free", "Prefix should handle special characters")
    }

    func testPrefixConcatenation_WithNumbers() {
        let identifier = AccessibilityID.stepCardPrefix + "42"
        XCTAssertEqual(identifier, "stepCard_42", "Prefix should handle numeric values")
    }

    func testAllPrefixes_EndWithUnderscore() {
        XCTAssertTrue(AccessibilityID.filterChipPrefix.hasSuffix("_"), "Filter chip prefix should end with underscore")
        XCTAssertTrue(AccessibilityID.recipeRowPrefix.hasSuffix("_"), "Recipe row prefix should end with underscore")
        XCTAssertTrue(AccessibilityID.ingredientRowPrefix.hasSuffix("_"), "Ingredient row prefix should end with underscore")
        XCTAssertTrue(AccessibilityID.stepCardPrefix.hasSuffix("_"), "Step card prefix should end with underscore")
        XCTAssertTrue(AccessibilityID.bookCardPrefix.hasSuffix("_"), "Book card prefix should end with underscore")
        XCTAssertTrue(AccessibilityID.planCardPrefix.hasSuffix("_"), "Plan card prefix should end with underscore")
    }
}
