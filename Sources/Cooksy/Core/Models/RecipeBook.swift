import Foundation
import SwiftData

// MARK: - RecipeBook
/// A user-created collection that groups related recipes together.
///
/// `RecipeBook` is a SwiftData `@Model` that allows users to organize their recipes
/// into custom collections — like "Weeknight Dinners", "Holiday Favorites", or "Meal Prep Ideas".
/// Recipes can belong to multiple books simultaneously.
///
/// ## SwiftData Relationships
/// - **Inverse relationship** to `Recipe` via `@Relationship(inverse: \Recipe.books)`.
/// - Uses `.nullify` delete rule: deleting a `RecipeBook` removes the association
///   but does **not** delete the recipes within it.
///
/// ## Usage
/// ```swift
/// let book = RecipeBook(name: "Weeknight Dinners")
/// book.recipes?.append(myPastaRecipe)
/// book.recipes?.append(myStirFryRecipe)
/// print(book.recipeCount) // 2
/// ```
@Model
public final class RecipeBook: Hashable {

    // MARK: Identity

    /// A stable unique identifier for the recipe book.
    ///
    /// This UUID is automatically generated on initialization and never changes.
    @Attribute(.unique) public var id: UUID

    // MARK: Core Properties

    /// The display name of the recipe book.
    ///
    /// This is user-editable and can be any descriptive name.
    ///
    /// Example: `"Weeknight Dinners"`, `"Holiday Baking"`, `"Meal Prep"`
    public var name: String

    /// The date and time when the recipe book was created.
    ///
    /// Used for sorting and displaying creation timestamps in the UI.
    public var createdAt: Date

    // MARK: Relationships

    /// The recipes contained in this book.
    ///
    /// This is an inverse relationship; SwiftData manages this property automatically
    /// when a recipe's `books` array is modified.
    ///
    /// - Note: This is optional because SwiftData may return `nil` for to-many relationships
    ///         that haven't been fully loaded yet. Use the `recipesArray` computed property
    ///         for a non-optional fallback.
    @Relationship(inverse: \Recipe.books) public var recipes: [Recipe]?

    // MARK: Initialization

    /// Creates a new `RecipeBook` instance.
    ///
    /// - Parameters:
    ///   - id: A unique identifier. Defaults to a new `UUID`.
    ///   - name: The display name for the recipe book.
    ///   - createdAt: The creation timestamp. Defaults to `Date()`.
    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

// MARK: - RecipeBook + Convenience
extension RecipeBook {

    /// The number of recipes in this book.
    ///
    /// Returns `0` if the `recipes` relationship hasn't been resolved yet.
    ///
    /// ```swift
    /// let book = RecipeBook(name: "Favorites")
    /// print(book.recipeCount) // 0
    /// ```
    @Transient public var recipeCount: Int {
        recipes?.count ?? 0
    }

    /// A non-optional array of recipes in this book.
    ///
    /// Use this when you need guaranteed access to the recipes array
    /// without unwrapping an optional.
    @Transient public var recipesArray: [Recipe] {
        recipes ?? []
    }

    /// A formatted string describing the recipe count.
    ///
    /// Returns `"1 recipe"` or `"5 recipes"` with proper pluralization.
    @Transient public var recipeCountDescription: String {
        let count = recipeCount
        return "\(count) \(count == 1 ? "recipe" : "recipes")"
    }
}

// MARK: - RecipeBook + Equatable
extension RecipeBook {
    /// Compares recipe books by their stable identity (`id`).
    public static func == (lhs: RecipeBook, rhs: RecipeBook) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes using the stable `id` property.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - RecipeBook + Sorting
extension RecipeBook {
    /// Sort descriptor for ordering recipe books by name alphabetically.
    public static var sortByName: SortDescriptor<RecipeBook> {
        SortDescriptor<RecipeBook>(\.name, order: .forward)
    }

    /// Sort descriptor for ordering recipe books by creation date (newest first).
    public static var sortByDate: SortDescriptor<RecipeBook> {
        SortDescriptor<RecipeBook>(\.createdAt, order: .reverse)
    }
}
