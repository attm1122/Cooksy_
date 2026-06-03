import Foundation
import SwiftData

// MARK: - RecipeStep
/// An individual cooking step extracted from a recipe video.
///
/// `RecipeStep` is a SwiftData `@Model` that represents a single step in a recipe's
/// preparation or cooking process. Each step has a title, detailed instruction text,
/// and an optional duration estimate. Steps are ordered within a recipe using `displayOrder`
/// to maintain the sequence in which they appear in the source video.
///
/// ## SwiftData Relationships
/// - **Inverse relationship** to `Recipe` via `@Relationship(inverse: \Recipe.steps)`.
/// - Deleting a parent `Recipe` cascades and deletes all associated `RecipeStep` instances.
///
/// ## Usage
/// ```swift
/// let step = RecipeStep(
///     title: "Preheat",
///     instruction: "Preheat your oven to 425°F (220°C). Position a rack in the center.",
///     durationMinutes: 15,
///     displayOrder: 0
/// )
/// ```
@Model
public final class RecipeStep: Hashable {

    // MARK: Identity

    /// A stable unique identifier for the recipe step.
    ///
    /// This UUID is automatically generated on initialization and never changes.
    @Attribute(.unique) public var id: UUID

    // MARK: Core Properties

    /// A short, descriptive title for this step.
    ///
    /// The title provides a quick overview of what this step involves.
    /// Usually one to three words.
    ///
    /// Example: `"Preheat"`, `"Mix Dry Ingredients"`, `"Sear the Steak"`
    public var title: String

    /// The detailed instruction text for this step.
    ///
    /// Contains the full description of what to do, including techniques,
    /// temperatures, visual cues, and tips.
    ///
    /// Example:
    /// ```
    /// "Preheat your oven to 425°F (220°C). Position a rack in the center
    /// of the oven. If you have a pizza stone, place it on the rack now
    /// so it heats up with the oven."
    /// ```
    public var instruction: String

    // MARK: Timing

    /// The estimated time this step takes, in minutes.
    ///
    /// This is optional because some steps (like "Serve immediately") don't have
    /// a meaningful duration. When present, it helps build a total time estimate
    /// for the recipe and can power cooking timers.
    ///
    /// - Note: A value of `nil` means no duration estimate is available.
    public var durationMinutes: Int?

    // MARK: Ordering

    /// The display order of this step within its parent recipe.
    ///
    /// Lower values appear first (0-indexed). This maintains the original sequence
    /// from the source video. Steps should be displayed in ascending order.
    public var displayOrder: Int

    // MARK: Relationships

    /// The parent recipe this step belongs to.
    ///
    /// This is an inverse relationship; SwiftData manages this property automatically
    /// when the step is added to a recipe's `steps` array.
    ///
    /// - Note: This is optional because the step may temporarily exist without
    ///         being assigned to a recipe (e.g., during the import process).
    @Relationship(inverse: \Recipe.steps) public var recipe: Recipe?

    // MARK: Initialization

    /// Creates a new `RecipeStep` instance.
    ///
    /// - Parameters:
    ///   - id: A unique identifier. Defaults to a new `UUID`.
    ///   - title: A short, descriptive title for the step (e.g., "Preheat oven").
    ///   - instruction: The full instruction text describing what to do.
    ///   - durationMinutes: The estimated time for this step in minutes. Defaults to `nil`.
    ///   - displayOrder: The zero-based display order within the recipe. Defaults to `0`.
    public init(
        id: UUID = UUID(),
        title: String,
        instruction: String,
        durationMinutes: Int? = nil,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.instruction = instruction
        self.durationMinutes = durationMinutes
        self.displayOrder = displayOrder
    }
}

// MARK: - RecipeStep + Display
extension RecipeStep {

    /// A formatted duration string for display.
    ///
    /// Returns strings like:
    /// - `"15 min"` (for values under 60)
    /// - `"1 hr 30 min"` (for values of 60 or more)
    /// - `"No time estimate"` (when `durationMinutes` is `nil`)
    public var formattedDuration: String {
        guard let minutes = durationMinutes else {
            return "No time estimate"
        }
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hrs = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hrs) hr"
        }
        return "\(hrs) hr \(mins) min"
    }

    /// A concise display string combining the step number and title.
    ///
    /// Example: `"Step 3: Sear the Steak"`
    public var stepLabel: String {
        "Step \(displayOrder + 1): \(title)"
    }
}

// MARK: - RecipeStep + Equatable
extension RecipeStep {
    /// Compares recipe steps by their stable identity (`id`).
    public static func == (lhs: RecipeStep, rhs: RecipeStep) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes using the stable `id` property.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
