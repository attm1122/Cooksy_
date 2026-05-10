import SwiftUI

// MARK: - Reduce Motion Check

/// Checks if Reduce Motion is enabled in accessibility settings.
var isReduceMotionEnabled: Bool {
    UIAccessibility.isReduceMotionEnabled
}

// MARK: - VoiceOver Announcement

/// Announces a message to VoiceOver users.
/// Use this for important state changes that should be read aloud.
func announceToVoiceOver(_ message: String) {
    UIAccessibility.post(notification: .announcement, argument: message)
}

/// Announces a message to VoiceOver with a slight delay to ensure it isn't dropped.
func announceToVoiceOver(_ message: String, delay: TimeInterval) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: - Accessible Animation Modifier

/// A view modifier that conditionally applies animation based on the Reduce Motion accessibility setting.
struct AccessibleAnimation<Value: Equatable>: ViewModifier {
    let animation: Animation?
    let value: Value

    func body(content: Content) -> some View {
        if isReduceMotionEnabled {
            content
        } else if let animation = animation {
            content.animation(animation, value: value)
        } else {
            content
        }
    }
}

extension View {
    /// Applies animation only when Reduce Motion is NOT enabled.
    /// Use this instead of `.animation()` for all accessibility-compliant views.
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(AccessibleAnimation(animation: animation, value: value))
    }

    /// Applies a spring animation only when Reduce Motion is NOT enabled.
    func accessibleSpring<V: Equatable>(duration: TimeInterval = 0.3, value: V) -> some View {
        modifier(AccessibleAnimation(animation: .spring(duration: duration), value: value))
    }

    /// Applies an ease-in-out animation only when Reduce Motion is NOT enabled.
    func accessibleEaseInOut<V: Equatable>(duration: TimeInterval = 0.3, value: V) -> some View {
        modifier(AccessibleAnimation(animation: .easeInOut(duration: duration), value: value))
    }
}

// MARK: - Accessibility Heading Levels

extension View {
    /// Applies an accessibility heading level to the view.
    /// Use for semantic document structure that VoiceOver can navigate by headings.
    func accessibleHeading(_ level: AccessibilityHeadingLevel) -> some View {
        self.accessibilityAddTraits(.isHeader)
            .accessibilityHeading(level)
    }
}

// MARK: - Combined Accessibility Element

extension View {
    /// Combines child elements into a single accessible element with a custom label.
    /// Use for card-like components where individual subviews should be read as one unit.
    func combinedAccessibility(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Decorative Element

extension View {
    /// Hides this view from the accessibility tree. Use only for purely decorative elements
    /// that convey no meaningful information (ornaments, background patterns, spacing dividers).
    func decorative() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Accessibility Action with Label

extension View {
    /// Adds an accessibility action with a descriptive label for custom gesture alternatives.
    func accessibleAction(named name: String, _ action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: Text(name), action)
    }
}

// MARK: - Accessibility State Change Announcement

/// Announces a state change to VoiceOver when the observed value changes.
struct AccessibilityAnnouncementModifier: ViewModifier {
    let message: String
    @State private var previousValue: Bool = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                announceToVoiceOver(message)
            }
    }
}

// MARK: - Accessibility Value Formatter

/// Formats common values into VoiceOver-friendly strings.
enum AccessibilityFormatter {
    /// Formats a cooking step count for VoiceOver.
    static func stepProgress(current: Int, total: Int) -> String {
        "Step \(current) of \(total)"
    }

    /// Formats a percentage for VoiceOver.
    static func percentage(_ value: Double) -> String {
        "\(Int(value * 100)) percent complete"
    }

    /// Formats a cooking time for VoiceOver.
    static func cookingTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") and \(mins) minute\(mins == 1 ? "" : "s")"
            }
        }
    }

    /// Formats a recipe confidence score for VoiceOver.
    static func confidence(_ level: String, score: Int) -> String {
        "\(level) confidence, \(score) out of 100"
    }

    /// Formats a countdown timer for VoiceOver.
    static func countdown(_ seconds: Int) -> String {
        if seconds == 0 {
            return "Available now"
        }
        return "Available in \(seconds) second\(seconds == 1 ? "" : "s")"
    }
}

// MARK: - Dynamic Type Support Helpers

/// A view modifier that ensures text scales properly with Dynamic Type.
struct ScalableText: ViewModifier {
    let minScale: CGFloat
    let maxSize: DynamicTypeSize

    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(minScale)
            .dynamicTypeSize(...maxSize)
    }
}

extension View {
    /// Makes the view's text scalable with Dynamic Type, with a minimum scale factor.
    func scalableText(minScale: CGFloat = 0.6, maxSize: DynamicTypeSize = .accessibility5) -> some View {
        modifier(ScalableText(minScale: minScale, maxSize: maxSize))
    }
}

// MARK: - Accessibility Identifiers

/// Accessibility identifiers for UI testing and assistive technologies.
/// These provide stable identifiers that don't change with localization.
enum AccessibilityID {
    // Home
    static let homeView = "homeView"
    static let urlInputField = "urlInputField"
    static let pasteButton = "pasteButton"
    static let saveRecipeButton = "saveRecipeButton"
    static let heroCard = "heroCard"
    static let recentlySavedSection = "recentlySavedSection"
    static let seeAllRecipesLink = "seeAllRecipesLink"
    static let recipeCompletionBanner = "recipeCompletionBanner"
    static let dismissBannerButton = "dismissBannerButton"

    // Recipes
    static let recipesView = "recipesView"
    static let recipeSearchField = "recipeSearchField"
    static let filterChipPrefix = "filterChip_"
    static let recipeRowPrefix = "recipeRow_"

    // Recipe Detail
    static let recipeDetailView = "recipeDetailView"
    static let recipeTitle = "recipeTitle"
    static let confidenceBanner = "confidenceBanner"
    static let saveRecipeDetailButton = "saveRecipeDetailButton"
    static let cookingModeButton = "cookingModeButton"
    static let cookAlongButton = "cookAlongButton"
    static let editRecipeButton = "editRecipeButton"
    static let shareRecipeButton = "shareRecipeButton"
    static let ingredientsSection = "ingredientsSection"
    static let ingredientRowPrefix = "ingredientRow_"
    static let stepsSection = "stepsSection"
    static let stepCardPrefix = "stepCard_"

    // Cooking Mode
    static let cookingModeView = "cookingModeView"
    static let cookingProgressBar = "cookingProgressBar"
    static let currentStepCard = "currentStepCard"
    static let previousStepButton = "previousStepButton"
    static let nextStepButton = "nextStepButton"
    static let closeCookingModeButton = "closeCookingModeButton"
    static let restartCookingButton = "restartCookingButton"

    // Auth
    static let authView = "authView"
    static let emailInputField = "emailInputField"
    static let continueButton = "continueButton"
    static let otpInputView = "otpInputView"
    static let verifyButton = "verifyButton"
    static let resendCodeButton = "resendCodeButton"
    static let changeEmailButton = "changeEmailButton"

    // Profile
    static let profileView = "profileView"
    static let userAvatar = "userAvatar"
    static let signOutButton = "signOutButton"
    static let deleteAccountButton = "deleteAccountButton"
    static let exportDataButton = "exportDataButton"

    // Books
    static let booksView = "booksView"
    static let createBookButton = "createBookButton"
    static let bookCardPrefix = "bookCard_"

    // Subscription
    static let subscriptionView = "subscriptionView"
    static let planCardPrefix = "planCard_"
    static let subscribeButton = "subscribeButton"
}
