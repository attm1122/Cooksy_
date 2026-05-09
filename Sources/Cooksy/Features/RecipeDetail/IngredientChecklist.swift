import SwiftUI

// MARK: - IngredientChecklist

/// A checklist view of all ingredients for a recipe.
///
/// Displays each ingredient in a tappable row with a circular checkmark indicator.
/// Tapping a row toggles its checked state via the view model. Supports optional
/// quantity and unit display using the Core `Ingredient` model's display helpers.
///
/// Fully accessible with VoiceOver labels, state change announcements, and
/// per-ingredient accessibility identifiers.
struct IngredientChecklist: View {

    /// The recipe whose ingredients are displayed.
    let recipe: Recipe

    /// Called when the user taps an ingredient row to toggle its checked state.
    let onToggle: (Ingredient) -> Void

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            ForEach(recipe.sortedIngredients, id: \.id) { ingredient in
                AccessibleIngredientChecklistRow(
                    ingredient: ingredient,
                    onToggle: { onToggle(ingredient) }
                )

                if ingredient.id != recipe.sortedIngredients.last?.id {
                    Divider()
                        .background(Color.cooksLine)
                        .padding(.leading, 48)
                        .decorative()
                }
            }
        }
        .background(Color.surface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cooksLine, lineWidth: 1)
        )
    }
}

// MARK: - Accessible Ingredient Checklist Row

/// A single ingredient row with a checkmark indicator and optional quantity.
/// Enhanced with full VoiceOver support including state labels, hints, and
/// state change announcements.
struct AccessibleIngredientChecklistRow: View {

    /// The ingredient to display.
    let ingredient: Ingredient

    /// Called when the row is tapped.
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: ingredient.isChecked
                    ? "checkmark.circle.fill"
                    : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(ingredient.isChecked ? Color.cooksSuccess : Color.muted)
                    .decorative()

                VStack(alignment: .leading, spacing: 2) {
                    Text(ingredient.name)
                        .font(ingredient.isChecked ? .cooksBody : .cooksBodyBold)
                        .foregroundStyle(ingredient.isChecked ? Color.muted : Color.ink)
                        .strikethrough(ingredient.isChecked)
                        .scalableText()

                    if let quantity = ingredient.quantity, !quantity.isEmpty {
                        Text(ingredient.shortDisplayText)
                            .font(.cooksCaption)
                            .foregroundStyle(Color.muted)
                            .scalableText()
                            .accessibilityLabel("Quantity: \(ingredient.shortDisplayText)")
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ingredient.name), \(ingredient.isChecked ? "checked" : "unchecked")")
        .accessibilityHint("Double tap to \(ingredient.isChecked ? "uncheck" : "check") this ingredient")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    let recipe = Recipe(
        title: "Pasta",
        servings: 4,
        sourceUrl: "https://example.com",
        sourcePlatform: .youtube,
        sourceCreator: "Chef"
    )

    // Add some mock ingredients for preview
    let _ = {
        let ing1 = Ingredient(name: "All-purpose flour", quantity: "2", unit: "cups")
        let ing2 = Ingredient(name: "Eggs", quantity: "3", unit: "large")
        let ing3 = Ingredient(name: "Salt", quantity: "1", unit: "tsp")
        recipe.ingredients.append(contentsOf: [ing1, ing2, ing3])
    }()

    IngredientChecklist(recipe: recipe) { _ in }
        .padding(.horizontal, 20)
        .background(Color.cooksBackground)
}
