import Foundation
import SwiftData

// MARK: - Ingredient
/// An individual ingredient extracted from a recipe video.
///
/// `Ingredient` is a SwiftData `@Model` that stores a single ingredient's name, quantity, unit,
/// and user interaction state (checked/unchecked). Ingredients are ordered within a recipe using
/// `displayOrder` to maintain the sequence in which they appear in the source video.
///
/// ## SwiftData Relationships
/// - **Inverse relationship** to `Recipe` via `@Relationship(inverse: \Recipe.ingredients)`.
/// - Deleting a parent `Recipe` cascades and deletes all associated `Ingredient` instances.
///
/// ## Usage
/// ```swift
/// let flour = Ingredient(
///     name: "All-purpose flour",
///     quantity: "2",
///     unit: "cups",
///     displayOrder: 0
/// )
/// ```
@Model
public final class Ingredient {

    // MARK: Identity

    /// A stable unique identifier for the ingredient.
    ///
    /// This UUID is automatically generated on initialization and never changes.
    @Attribute(.unique) public var id: UUID

    // MARK: Core Properties

    /// The name of the ingredient.
    ///
    /// Example: `"All-purpose flour"`, `"Olive oil"`, `"Salt"`
    public var name: String

    /// The quantity of the ingredient needed.
    ///
    /// This is stored as a string to support fractional and imprecise measurements
    /// commonly found in cooking videos (e.g., `"1/2"`, `"a pinch"`, `"to taste"`).
    ///
    /// Example: `"2"`, `"1/4"`, `"3-4"`
    public var quantity: String?

    /// The unit of measurement for the ingredient.
    ///
    /// Example: `"cups"`, `"tablespoons"`, `"grams"`, `"pounds"`
    public var unit: String?

    // MARK: State

    /// Whether the user has checked off this ingredient while shopping or prepping.
    ///
    /// Defaults to `false`. This state is persisted so users can track their progress
    /// across app launches.
    public var isChecked: Bool

    // MARK: Ordering

    /// The display order of this ingredient within its parent recipe.
    ///
    /// Lower values appear first. This maintains the original sequence from the source video.
    public var displayOrder: Int

    // MARK: Relationships

    /// The parent recipe this ingredient belongs to.
    ///
    /// This is an inverse relationship; SwiftData manages this property automatically
    /// when the ingredient is added to a recipe's `ingredients` array.
    ///
    /// - Note: This is optional because the ingredient may temporarily exist without
    ///         being assigned to a recipe (e.g., during the import process).
    @Relationship(inverse: \Recipe.ingredients) public var recipe: Recipe?

    // MARK: Initialization

    /// Creates a new `Ingredient` instance.
    ///
    /// - Parameters:
    ///   - id: A unique identifier. Defaults to a new `UUID`.
    ///   - name: The name of the ingredient (e.g., "All-purpose flour").
    ///   - quantity: The quantity as a string (e.g., "2"). Defaults to `nil`.
    ///   - unit: The unit of measurement (e.g., "cups"). Defaults to `nil`.
    ///   - isChecked: Whether the ingredient has been checked off. Defaults to `false`.
    ///   - displayOrder: The zero-based display order within the recipe. Defaults to `0`.
    public init(
        id: UUID = UUID(),
        name: String,
        quantity: String? = nil,
        unit: String? = nil,
        isChecked: Bool = false,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isChecked = isChecked
        self.displayOrder = displayOrder
    }
}

// MARK: - Ingredient + Display
extension Ingredient {

    /// A formatted display string combining quantity, unit, and name.
    ///
    /// Returns strings like:
    /// - `"2 cups all-purpose flour"` (when all fields are present)
    /// - `"Salt"` (when only name is present)
    /// - `"1/2 cup sugar"` (with fractional quantity)
    public var displayText: String {
        var components: [String] = []
        if let quantity = quantity, !quantity.isEmpty {
            components.append(quantity)
        }
        if let unit = unit, !unit.isEmpty {
            components.append(unit)
        }
        components.append(name)
        return components.joined(separator: " ")
    }

    /// A concise string for compact UI contexts.
    ///
    /// Returns strings like `"2 cups"` or `"Salt"` (name only if no quantity/unit).
    public var shortDisplayText: String {
        if let quantity = quantity, !quantity.isEmpty {
            if let unit = unit, !unit.isEmpty {
                return "\(quantity) \(unit)"
            }
            return quantity
        }
        return name
    }
}

// MARK: - Ingredient + Equatable
extension Ingredient {
    /// Compares ingredients by their stable identity (`id`).
    public static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes using the stable `id` property.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
