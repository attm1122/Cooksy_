import SwiftUI
import SwiftData

// MARK: - RecipeRow
/// Row for displaying a recipe in a list. Uses Core Recipe model and design system.
struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 14) {
            // Placeholder thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceAlt)
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.muted.opacity(0.4))
                        .decorative()
                )
                .accessibilityHidden(true)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.cooksBodyBold)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .scalableText()

                if !recipe.heroNote.isEmpty {
                    Text(recipe.heroNote)
                        .font(.cooksCaption)
                        .foregroundStyle(Color.muted)
                        .lineLimit(2)
                        .scalableText()
                }

                HStack(spacing: 8) {
                    PlatformBadge(platform: recipe.source.platform)

                    Text(recipe.formattedTotalTime)
                        .font(.cooksMicro)
                        .foregroundStyle(Color.muted)
                        .scalableText()
                        .accessibilityLabel("Total time \(AccessibilityFormatter.cookingTime(minutes: recipe.totalTimeMinutes))")
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surface)
        .cornerRadius(18)
        .shadow(
            color: .black.opacity(0.06),
            radius: 12,
            x: 0,
            y: 4
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(recipeAccessibilityLabel)
        .accessibilityHint("Double tap to view recipe details")
        .accessibilityAddTraits(.isButton)
    }

    /// Generates a comprehensive VoiceOver label for the recipe row.
    private var recipeAccessibilityLabel: String {
        var label = "\(recipe.title)"
        if !recipe.heroNote.isEmpty {
            label += ". \(recipe.heroNote)"
        }
        label += ". From \(recipe.source.platform.displayName)"
        label += ". Total time \(AccessibilityFormatter.cookingTime(minutes: recipe.totalTimeMinutes))"
        return label
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        RecipeRow(recipe: Recipe(
            title: "Creamy Garlic Pasta",
            heroNote: "The secret is reserving pasta water for the sauce.",
            servings: 4,
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            totalTimeMinutes: 30,
            sourceUrl: "https://youtube.com/watch?v=example",
            sourcePlatform: .youtube,
            sourceCreator: "Chef Maria",
            sourceTitle: "Creamy Garlic Pasta in 30 Minutes"
        ))

        RecipeRow(recipe: Recipe(
            title: "Vegan Chocolate Cake",
            heroNote: "No eggs, no dairy — just rich chocolate flavor.",
            servings: 8,
            prepTimeMinutes: 15,
            cookTimeMinutes: 35,
            totalTimeMinutes: 50,
            sourceUrl: "https://tiktok.com/@baker/video",
            sourcePlatform: .tiktok,
            sourceCreator: "VeganBakes",
            sourceTitle: "Best Vegan Chocolate Cake"
        ))
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 20)
    .background(Color.cooksBackground)
}
