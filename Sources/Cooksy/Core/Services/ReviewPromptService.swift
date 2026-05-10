import Foundation
import StoreKit

// MARK: - Review Prompt Service

/// Manages App Store review prompts following Apple's best practices.
///
/// ## Prompt Strategy
/// - Prompts only after the user imports 3+ recipes (they've experienced real value).
/// - Maximum 3 prompts per calendar year, respecting Apple's de-facto quota.
/// - Enforces a minimum 60-day gap between prompts to avoid fatigue.
/// - Respects an explicit opt-out preference.
///
/// ## Call Sites
/// Invoke `recordSuccessfulImport()` after a recipe import completes successfully.
/// This is the optimal moment — the user just experienced the app's core value.
///
/// ## Example
/// ```swift
/// ReviewPromptService.shared.recordSuccessfulImport()
/// ```
@Observable
@MainActor
final class ReviewPromptService {

    // MARK: - Singleton

    static let shared = ReviewPromptService()

    // MARK: - UserDefaults Keys

    private let importsKey = "recipe_imports_count"
    private let lastPromptKey = "last_review_prompt_date"
    private let promptCountKey = "review_prompt_count_this_year"
    private let optOutKey = "review_prompt_opted_out"

    // MARK: - Thresholds

    private let minimumImportsBeforePrompt = 3
    private let maxPromptsPerYear = 3
    private let minimumDaysBetweenPrompts: TimeInterval = 60 * 24 * 3600 // 60 days

    // MARK: - Public API

    /// Call this after a successful recipe import.
    ///
    /// Increments the import counter and, if all conditions are met,
    /// requests an App Store review via `SKStoreReviewController`.
    func recordSuccessfulImport() {
        let count = UserDefaults.standard.integer(forKey: importsKey) + 1
        UserDefaults.standard.set(count, forKey: importsKey)

        if shouldPrompt() {
            promptForReview()
        }
    }

    /// Allows the user to permanently opt out of review prompts.
    ///
    /// Call this from a settings toggle or an explicit "Don't ask again" action.
    func optOut() {
        UserDefaults.standard.set(true, forKey: optOutKey)
    }

    /// Checks whether the user has opted out of review prompts.
    var hasOptedOut: Bool {
        UserDefaults.standard.bool(forKey: optOutKey)
    }

    /// Resets the current year's prompt count (useful for testing or after a major update).
    func resetYearlyCount() {
        UserDefaults.standard.set(0, forKey: promptCountKey)
        UserDefaults.standard.removeObject(forKey: lastPromptKey)
    }

    // MARK: - Decision Logic

    private func shouldPrompt() -> Bool {
        guard !UserDefaults.standard.bool(forKey: optOutKey) else { return false }
        guard UserDefaults.standard.integer(forKey: importsKey) >= minimumImportsBeforePrompt else { return false }
        guard promptCountThisYear() < maxPromptsPerYear else { return false }

        // Minimum 60-day cooldown between prompts
        if let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date {
            guard Date().timeIntervalSince(lastPrompt) > minimumDaysBetweenPrompts else { return false }
        }

        return true
    }

    private func promptCountThisYear() -> Int {
        let count = UserDefaults.standard.integer(forKey: promptCountKey)
        let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date

        // Reset count if we've crossed into a new calendar year
        if let last = lastPrompt {
            let calendar = Calendar.current
            if calendar.component(.year, from: last) != calendar.component(.year, from: Date()) {
                UserDefaults.standard.set(0, forKey: promptCountKey)
                return 0
            }
        }

        return count
    }

    // MARK: - Review Request

    private func promptForReview() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        SKStoreReviewController.requestReview(in: windowScene)

        UserDefaults.standard.set(Date(), forKey: lastPromptKey)
        let newCount = promptCountThisYear() + 1
        UserDefaults.standard.set(newCount, forKey: promptCountKey)
    }
}
