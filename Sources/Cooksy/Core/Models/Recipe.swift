import Foundation
import SwiftData

// MARK: - Recipe
/// The central model representing a recipe extracted from a social media cooking video.
///
/// `Recipe` is the primary SwiftData `@Model` in Cooksy. It stores all metadata about a recipe
/// including its title, timing information, extraction confidence, source video details, and
/// relationships to its ingredients, steps, and the recipe books it belongs to.
///
/// ## Lifecycle
/// Recipes begin in the `.processing` status when imported from a video URL. The app's
/// AI service analyzes the video, extracts ingredients and steps, and updates the recipe
/// to `.ready` on success or `.failed` on error.
///
/// ## SwiftData Relationships
/// - **`ingredients`** → `[Ingredient]?` (cascade delete): Deleting a recipe removes all ingredients.
/// - **`steps`** → `[RecipeStep]?` (cascade delete): Deleting a recipe removes all steps.
/// - **`books`** → `[RecipeBook]?` (nullify delete): Deleting a recipe removes it from books.
///
/// ## Usage
/// ```swift
/// let recipe = Recipe(
///     title: "Authentic Neapolitan Pizza",
///     heroNote: "The secret is a 72-hour cold ferment on the dough.",
///     servings: 4,
///     prepTimeMinutes: 30,
///     cookTimeMinutes: 90,
///     totalTimeMinutes: 4380,
///     status: .ready,
///     confidence: .high,
///     confidenceScore: 95,
///     confidenceNote: "All ingredients and steps clearly verbalized in the video.",
///     sourceUrl: "https://youtube.com/watch?v=example",
///     sourcePlatform: .youtube,
///     sourceCreator: "Vito Iacopelli",
///     sourceTitle: "How To Make Neapolitan Pizza At Home"
/// )
/// ```
@Model
public final class Recipe {

    // MARK: Identity

    /// A stable unique identifier for the recipe.
    ///
    /// This UUID is automatically generated on initialization and never changes.
    @Attribute(.unique) public var id: UUID

    // MARK: Core Content

    /// The title of the recipe.
    ///
    /// This is extracted from the video by the AI or can be manually edited by the user.
    ///
    /// Example: `"Authentic Neapolitan Pizza"`
    public var title: String

    /// A standout tip, trick, or key insight about the recipe.
    ///
    /// The "hero note" captures the most valuable piece of information from the video —
    /// the secret technique, the pro tip, or the make-or-break detail that elevates the dish.
    ///
    /// Example: `"The secret is a 72-hour cold ferment on the dough."`
    public var heroNote: String

    // MARK: Servings

    /// The number of servings this recipe yields.
    ///
    /// Defaults to `1`. Can be adjusted by the user to scale ingredient quantities.
    public var servings: Int

    // MARK: Timing

    /// The estimated preparation time in minutes.
    ///
    /// This includes chopping, measuring, mixing, and any other prep work
    /// before the actual cooking begins.
    public var prepTimeMinutes: Int

    /// The estimated cooking time in minutes.
    ///
    /// This includes baking, sautéing, simmering, and any active or passive
    /// cooking time.
    public var cookTimeMinutes: Int

    /// The total estimated time in minutes (prep + cook).
    ///
    /// This should generally equal `prepTimeMinutes + cookTimeMinutes`, but may
    /// include additional time (e.g., resting, cooling) in some cases.
    public var totalTimeMinutes: Int

    // MARK: Processing Status

    /// The current processing status of the recipe.
    ///
    /// Stored as a raw string to ensure SwiftData compatibility. The `status`
    /// computed property provides typed access.
    ///
    /// - `.processing`: AI is still analyzing the video.
    /// - `.ready`: Recipe has been successfully extracted.
    /// - `.failed`: Extraction failed; manual review needed.
    public var statusRawValue: String

    /// The confidence level of the AI extraction.
    ///
    /// Stored as a raw string to ensure SwiftData compatibility. The `confidence`
    /// computed property provides typed access.
    ///
    /// - `.high`: All details were clearly verbalized.
    /// - `.medium`: Some details may need verification.
    /// - `.low`: Significant ambiguity in the extraction.
    public var confidenceRawValue: String

    /// A numeric confidence score from 0 to 100.
    ///
    /// This provides a granular measure of extraction quality beyond the
    /// three-tier `confidence` level. Higher is better.
    ///
    /// - 90-100: Excellent — all details clearly extracted.
    /// - 70-89: Good — minor details may need review.
    /// - 50-69: Fair — some details inferred or ambiguous.
    /// - 0-49: Poor — significant manual review recommended.
    public var confidenceScore: Int

    /// A human-readable explanation of the confidence assessment.
    ///
    /// This note explains *why* the confidence level was assigned — what was clear,
    /// what was ambiguous, and what the user should double-check.
    ///
    /// Example: `"All ingredients and steps were clearly verbalized. The cook times
    /// were shown on screen, which were extracted accurately."`
    public var confidenceNote: String

    // MARK: User State

    /// Whether the user has saved/bookmarked this recipe.
    ///
    /// Saved recipes can be accessed quickly from a dedicated "Saved" tab or section.
    /// Defaults to `false`.
    public var isSaved: Bool

    // MARK: Timestamps

    /// The date and time when the recipe was first imported.
    ///
    /// This is set once during initialization and never changes.
    public var createdAt: Date

    /// The date and time when the recipe was last modified.
    ///
    /// Updated automatically whenever the recipe or any of its related
    /// ingredients or steps are edited.
    public var updatedAt: Date

    // MARK: Import Metadata

    /// The identifier of the background import job that created this recipe.
    ///
    /// This links the recipe to the server-side processing job for status tracking.
    /// `nil` for recipes created manually within the app.
    public var importJobId: String?

    /// A human-readable message describing the current processing state.
    ///
    /// Used to show progress updates to the user while a recipe is being processed.
    /// Example: `"Analyzing video transcript..."`, `"Extracting ingredients..."`
    ///
    /// `nil` once processing is complete.
    public var processingMessage: String?

    // MARK: Source (Stored Inline)

    /// The URL of the original video this recipe was extracted from.
    ///
    /// Example: `"https://youtube.com/watch?v=dQw4w9WgXcQ"`
    public var sourceUrl: String

    /// The platform hosting the original video, stored as a raw string.
    ///
    /// Use the `source` computed property for typed access.
    public var sourcePlatform: String

    /// The name of the content creator or channel.
    ///
    /// Example: `"Joshua Weissman"`
    public var sourceCreator: String

    /// The title of the original video.
    ///
    /// Example: `"The Best Homemade Pizza You'll Ever Make"`
    public var sourceTitle: String

    // MARK: Relationships

    /// The ingredients needed for this recipe.
    ///
    /// Ordered by `displayOrder` for presentation. Use `sortedIngredients` for
    /// a properly sorted, non-optional array.
    ///
    /// - Delete rule: `.cascade` — deleting the recipe removes all ingredients.
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    public var ingredients: [Ingredient]?

    /// The cooking steps for this recipe.
    ///
    /// Ordered by `displayOrder` for presentation. Use `sortedSteps` for
    /// a properly sorted, non-optional array.
    ///
    /// - Delete rule: `.cascade` — deleting the recipe removes all steps.
    @Relationship(deleteRule: .cascade, inverse: \RecipeStep.recipe)
    public var steps: [RecipeStep]?

    /// The recipe books this recipe is included in.
    ///
    /// A recipe can belong to multiple books (many-to-many relationship).
    ///
    /// - Delete rule: `.nullify` — deleting the recipe removes it from books
    ///   but does not delete the books themselves.
    @Relationship(deleteRule: .nullify, inverse: \RecipeBook.recipes)
    public var books: [RecipeBook]?

    // MARK: Initialization

    /// Creates a new `Recipe` instance.
    ///
    /// This is the comprehensive initializer that sets up a recipe with all its properties.
    /// For recipes created via video import, the AI service will populate all fields.
    /// For manually created recipes, provide the known values and use sensible defaults.
    ///
    /// - Parameters:
    ///   - id: A unique identifier. Defaults to a new `UUID`.
    ///   - title: The recipe title.
    ///   - heroNote: A standout tip or key insight. Defaults to an empty string.
    ///   - servings: The number of servings. Defaults to `1`.
    ///   - prepTimeMinutes: Estimated prep time in minutes. Defaults to `0`.
    ///   - cookTimeMinutes: Estimated cook time in minutes. Defaults to `0`.
    ///   - totalTimeMinutes: Total estimated time in minutes. Defaults to `0`.
    ///   - status: The processing status. Defaults to `.processing`.
    ///   - confidence: The AI extraction confidence. Defaults to `.medium`.
    ///   - confidenceScore: Numeric confidence from 0-100. Defaults to `50`.
    ///   - confidenceNote: Human-readable confidence explanation. Defaults to an empty string.
    ///   - isSaved: Whether the recipe is bookmarked. Defaults to `false`.
    ///   - createdAt: Creation timestamp. Defaults to `Date()`.
    ///   - updatedAt: Last modification timestamp. Defaults to `Date()`.
    ///   - importJobId: The server-side import job identifier. Defaults to `nil`.
    ///   - processingMessage: Current processing status message. Defaults to `nil`.
    ///   - sourceUrl: The URL of the original video.
    ///   - sourcePlatform: The platform hosting the video.
    ///   - sourceCreator: The content creator's name.
    ///   - sourceTitle: The original video title.
    ///   - ingredients: The recipe's ingredients. Defaults to `nil`.
    ///   - steps: The recipe's cooking steps. Defaults to `nil`.
    ///   - books: The recipe books this recipe belongs to. Defaults to `nil`.
    public init(
        id: UUID = UUID(),
        title: String,
        heroNote: String = "",
        servings: Int = 1,
        prepTimeMinutes: Int = 0,
        cookTimeMinutes: Int = 0,
        totalTimeMinutes: Int = 0,
        status: RecipeStatus = .processing,
        confidence: ConfidenceLevel = .medium,
        confidenceScore: Int = 50,
        confidenceNote: String = "",
        isSaved: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        importJobId: String? = nil,
        processingMessage: String? = nil,
        sourceUrl: String,
        sourcePlatform: SourcePlatform,
        sourceCreator: String,
        sourceTitle: String,
        ingredients: [Ingredient]? = nil,
        steps: [RecipeStep]? = nil,
        books: [RecipeBook]? = nil
    ) {
        self.id = id
        self.title = title
        self.heroNote = heroNote
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.totalTimeMinutes = totalTimeMinutes
        self.statusRawValue = status.rawValue
        self.confidenceRawValue = confidence.rawValue
        self.confidenceScore = confidenceScore
        self.confidenceNote = confidenceNote
        self.isSaved = isSaved
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.importJobId = importJobId
        self.processingMessage = processingMessage
        self.sourceUrl = sourceUrl
        self.sourcePlatform = sourcePlatform.rawValue
        self.sourceCreator = sourceCreator
        self.sourceTitle = sourceTitle
        self.ingredients = ingredients
        self.steps = steps
        self.books = books
    }
}

// MARK: - Recipe + Source
extension Recipe {

    /// A typed `Source` value reconstructed from the inline stored properties.
    ///
    /// This computed property bridges the inline storage (`sourceUrl`, `sourcePlatform`, etc.)
    /// with the `Source` value type, providing a clean API for accessing source information.
    ///
    /// - Note: If `sourcePlatform` contains an invalid raw value, it falls back to `.youtube`.
    @Transient public var source: Source {
        Source(
            url: sourceUrl,
            platform: SourcePlatform(rawValue: sourcePlatform) ?? .youtube,
            creator: sourceCreator,
            title: sourceTitle
        )
    }

    /// Updates the inline source properties from a `Source` value.
    ///
    /// Use this method when you need to programmatically change the source information,
    /// such as during an import process or when correcting source metadata.
    ///
    /// - Parameter newSource: The `Source` value to apply.
    public func updateSource(_ newSource: Source) {
        self.sourceUrl = newSource.url
        self.sourcePlatform = newSource.platform.rawValue
        self.sourceCreator = newSource.creator
        self.sourceTitle = newSource.title
    }
}

// MARK: - Recipe + Status
extension Recipe {

    /// The typed `RecipeStatus` value.
    @Transient public var status: RecipeStatus {
        get { RecipeStatus(rawValue: statusRawValue) ?? .processing }
        set { statusRawValue = newValue.rawValue }
    }

    /// The typed `ConfidenceLevel` value.
    @Transient public var confidence: ConfidenceLevel {
        get { ConfidenceLevel(rawValue: confidenceRawValue) ?? .medium }
        set { confidenceRawValue = newValue.rawValue }
    }

    /// Whether the recipe has been successfully extracted and is ready to use.
    @Transient public var isReady: Bool {
        status == .ready
    }

    /// Whether the recipe is currently being processed by the AI service.
    @Transient public var isProcessing: Bool {
        status == .processing
    }

    /// Whether the recipe extraction failed and needs attention.
    @Transient public var isFailed: Bool {
        status == .failed
    }
}

// MARK: - Recipe + Display
extension Recipe {

    /// A formatted string representing the total time.
    ///
    /// Formats as:
    /// - `"30 min"` for times under 60 minutes
    /// - `"1 hr 30 min"` for times of 60 minutes or more
    /// - `"—"` for zero or negative times
    @Transient public var formattedTotalTime: String {
        Formatters.formatTime(totalTimeMinutes)
    }

    /// A formatted string representing the prep time.
    @Transient public var formattedPrepTime: String {
        Formatters.formatTime(prepTimeMinutes)
    }

    /// A formatted string representing the cook time.
    @Transient public var formattedCookTime: String {
        Formatters.formatTime(cookTimeMinutes)
    }

    /// The ingredients sorted by their display order.
    ///
    /// Returns an empty array if the relationship hasn't been resolved.
    @Transient public var sortedIngredients: [Ingredient] {
        (ingredients ?? []).sorted { $0.displayOrder < $1.displayOrder }
    }

    /// The steps sorted by their display order.
    ///
    /// Returns an empty array if the relationship hasn't been resolved.
    @Transient public var sortedSteps: [RecipeStep] {
        (steps ?? []).sorted { $0.displayOrder < $1.displayOrder }
    }

    /// A short, one-line summary of the recipe for list views.
    ///
    /// Example: `"4 servings · 1 hr 30 min · By Chef John on YouTube"`
    @Transient public var summaryLine: String {
        var parts: [String] = []
        parts.append("\(servings) \(servings == 1 ? "serving" : "servings")")
        if totalTimeMinutes > 0 {
            parts.append(formattedTotalTime)
        }
        parts.append("By \(sourceCreator) on \(source.displayName)")
        return parts.joined(separator: " · ")
    }
}

// MARK: - Recipe + Book Management
extension Recipe {

    /// Adds this recipe to a recipe book.
    ///
    /// - Parameter book: The `RecipeBook` to add this recipe to.
    public func addToBook(_ book: RecipeBook) {
        if books == nil {
            books = []
        }
        if !(books?.contains(where: { $0.id == book.id }) ?? false) {
            books?.append(book)
        }
    }

    /// Removes this recipe from a recipe book.
    ///
    /// - Parameter book: The `RecipeBook` to remove this recipe from.
    public func removeFromBook(_ book: RecipeBook) {
        books?.removeAll(where: { $0.id == book.id })
    }

    /// Checks whether this recipe is in a given recipe book.
    ///
    /// - Parameter book: The `RecipeBook` to check.
    /// - Returns: `true` if the recipe is in the book, `false` otherwise.
    public func isInBook(_ book: RecipeBook) -> Bool {
        books?.contains(where: { $0.id == book.id }) ?? false
    }
}

// MARK: - Recipe + Equatable
extension Recipe {
    /// Compares recipes by their stable identity (`id`).
    public static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes using the stable `id` property.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Recipe + Sorting
extension Recipe {
    /// Sort descriptor for ordering recipes by title alphabetically.
    public static var sortByTitle: SortDescriptor<Recipe> {
        SortDescriptor(\.title, order: .forward)
    }

    /// Sort descriptor for ordering recipes by creation date (newest first).
    public static var sortByDate: SortDescriptor<Recipe> {
        SortDescriptor(\.createdAt, order: .reverse)
    }

    /// Sort descriptor for ordering recipes by last update (most recent first).
    public static var sortByUpdated: SortDescriptor<Recipe> {
        SortDescriptor(\.updatedAt, order: .reverse)
    }
}

// MARK: - Recipe + Update Helpers
extension Recipe {
    /// Marks the recipe as having been updated by touching `updatedAt`.
    ///
    /// Call this method after making changes to the recipe or its relationships
    /// to ensure the timestamp reflects the latest modification.
    public func touch() {
        self.updatedAt = Date()
    }
}


