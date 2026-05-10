import SwiftUI
import SwiftData

// MARK: - RecipeDetailView
/// Full recipe detail with ingredients, steps, actions, and confidence info.
///
/// Uses `RecipeDetailViewModel` to manage state and persist changes to SwiftData.
struct RecipeDetailView: View {

    // MARK: - Dependencies

    @Environment(\.supabase) private var supabase
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    /// The recipe being displayed. Used to create the ViewModel.
    let recipe: Recipe

    @State private var viewModel: RecipeDetailViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel = viewModel {
                contentView(viewModel: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard viewModel == nil else { return }
            self.viewModel = RecipeDetailViewModel(
                recipe: recipe,
                supabase: supabase,
                modelContext: modelContext
            )
        }
    }

    // MARK: - Content

    private func contentView(viewModel: RecipeDetailViewModel) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                // Header
                headerSection(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // Main card: source, timing, confidence
                mainCard(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                // Action buttons
                actionsSection(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Ingredients
                ingredientsCard(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                // Steps
                stepsCard(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.cooksBackground)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Recipe")
        .accessibilityIdentifier(AccessibilityID.recipeDetailView)
        .sheet(isPresented: $viewModel.showEditSheet) {
            RecipeEditView(recipe: viewModel.recipe, onFinish: {})
        }
        .fullScreenCover(isPresented: $viewModel.showCookingMode) {
            CookingModeView(recipe: viewModel.recipe)
        }
        .sheet(isPresented: $viewModel.showCookAlong) {
            CookAlongView(viewModel: CookAlongViewModel(recipe: viewModel.recipe))
        }
    }

    // MARK: - Header Section

    private func headerSection(viewModel: RecipeDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recipe Detail")
                .font(.cooksCaption)
                .fontWeight(.bold)
                .tracking(0.5)
                .foregroundStyle(Color.muted)
                .accessibilityLabel("Recipe Detail section")
                .decorative()

            Text(viewModel.recipe.title)
                .font(.cooksH1)
                .foregroundStyle(Color.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibleHeading(.h1)
                .accessibilityIdentifier(AccessibilityID.recipeTitle)

            if !viewModel.recipe.heroNote.isEmpty {
                Text(viewModel.recipe.heroNote)
                    .font(.cooksCallout)
                    .foregroundStyle(Color.muted)
                    .padding(.top, 4)
                    .accessibilityLabel("Note: \(viewModel.recipe.heroNote)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recipe: \(viewModel.recipe.title). \(viewModel.recipe.heroNote.isEmpty ? "" : viewModel.recipe.heroNote)")
    }

    // MARK: - Main Card

    private func mainCard(viewModel: RecipeDetailViewModel) -> some View {
        CooksyCard {
            VStack(alignment: .leading, spacing: 16) {
                // Source info
                HStack(spacing: 8) {
                    Text("By \(viewModel.recipe.sourceCreator)")
                        .font(.cooksCallout)
                        .foregroundStyle(Color.softInk)

                    Spacer()

                    PlatformBadge(platform: viewModel.recipe.source.platform)
                        .accessibilityLabel("From \(viewModel.recipe.source.platform.displayName)")
                }

                // Timing meta row
                HStack(spacing: 16) {
                    MetaItem(icon: "person.2", label: "\(viewModel.recipe.servings) srv")
                        .accessibilityLabel("\(viewModel.recipe.servings) servings")
                    if viewModel.recipe.prepTimeMinutes > 0 {
                        MetaItem(icon: "clock", label: viewModel.recipe.formattedPrepTime)
                            .accessibilityLabel("Prep time: \(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.prepTimeMinutes))")
                    }
                    if viewModel.recipe.cookTimeMinutes > 0 {
                        MetaItem(icon: "flame.fill", label: viewModel.recipe.formattedCookTime)
                            .accessibilityLabel("Cook time: \(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.cookTimeMinutes))")
                    }
                    MetaItem(icon: "hourglass", label: viewModel.recipe.formattedTotalTime, highlighted: true)
                        .accessibilityLabel("Total time: \(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.totalTimeMinutes))")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(viewModel.recipe.servings) servings, \(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.totalTimeMinutes)) total")

                // Confidence banner
                if viewModel.recipe.isReady {
                    ConfidenceBanner(recipe: viewModel.recipe)
                        .accessibilityIdentifier(AccessibilityID.confidenceBanner)
                }
            }
        }
    }

    // MARK: - Actions Section
    /// Two-tier visual hierarchy grid:
    /// - Primary row: Cook Along (hero) + Save
    /// - Secondary row: Cooking Mode + Edit (compact, de-emphasized)
    private func actionsSection(viewModel: RecipeDetailViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            // Primary: Cook Along (hero feature)
            Button {
                viewModel.startCookAlong()
                announceToVoiceOver("Starting cook along")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .decorative()
                    Text("Cook Along")
                }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityLabel("Start cook along with video")
            .accessibilityIdentifier(AccessibilityID.cookAlongButton)

            // Primary: Save
            Button {
                viewModel.toggleSave()
                announceToVoiceOver(viewModel.recipe.isSaved ? "Recipe saved" : "Recipe unsaved")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.recipe.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                        .decorative()
                    Text(viewModel.recipe.isSaved ? "Saved" : "Save")
                }
            }
            .buttonStyle(SecondaryActionButtonStyle())
            .accessibilityLabel(viewModel.recipe.isSaved ? "Unsave recipe" : "Save recipe")
            .accessibilityIdentifier(AccessibilityID.saveRecipeDetailButton)

            // Secondary: Cooking Mode
            Button {
                viewModel.startCooking()
                announceToVoiceOver("Starting cooking mode")
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .medium))
                        .decorative()
                    Text("Cooking Mode")
                }
            }
            .buttonStyle(TertiaryActionButtonStyle())
            .accessibilityLabel("Start cooking mode")
            .accessibilityIdentifier(AccessibilityID.cookingModeButton)

            // Secondary: Edit
            Button {
                HapticsService.light()
                viewModel.editRecipe()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .medium))
                        .decorative()
                    Text("Edit")
                }
            }
            .buttonStyle(TertiaryActionButtonStyle())
            .accessibilityLabel("Edit recipe")
            .accessibilityIdentifier(AccessibilityID.editRecipeButton)
        }
    }

    // MARK: - Ingredients Card

    private func ingredientsCard(viewModel: RecipeDetailViewModel) -> some View {
        CooksyCard(isLarge: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "basket.fill")
                        .font(.cooksH3)
                        .foregroundStyle(Color.brand)
                        .decorative()

                    Text("Ingredients")
                        .font(.cooksH2)
                        .foregroundStyle(Color.ink)
                        .accessibleHeading(.h2)

                    Spacer()

                    Text("\(viewModel.recipe.sortedIngredients.count) items")
                        .font(.cooksCaption)
                        .foregroundStyle(Color.muted)
                        .accessibilityLabel("\(viewModel.recipe.sortedIngredients.count) ingredients")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Ingredients section, \(viewModel.recipe.sortedIngredients.count) items")

                if viewModel.recipe.sortedIngredients.isEmpty {
                    Text("No ingredients extracted yet.")
                        .font(.cooksCallout)
                        .foregroundStyle(Color.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .accessibilityLabel("No ingredients extracted yet")
                } else {
                    AccessibleIngredientChecklist(viewModel: viewModel)
                        .background(Color.surfaceAlt)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.ingredientsSection)
    }

    // MARK: - Steps Card

    private func stepsCard(viewModel: RecipeDetailViewModel) -> some View {
        CooksyCard(isLarge: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.number")
                        .font(.cooksH3)
                        .foregroundStyle(Color.brand)
                        .decorative()

                    Text("Steps")
                        .font(.cooksH2)
                        .foregroundStyle(Color.ink)
                        .accessibleHeading(.h2)

                    Spacer()

                    Text("\(viewModel.recipe.sortedSteps.count) steps")
                        .font(.cooksCaption)
                        .foregroundStyle(Color.muted)
                        .accessibilityLabel("\(viewModel.recipe.sortedSteps.count) steps")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Steps section, \(viewModel.recipe.sortedSteps.count) total steps")

                if viewModel.recipe.sortedSteps.isEmpty {
                    Text("No steps extracted yet.")
                        .font(.cooksCallout)
                        .foregroundStyle(Color.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .accessibilityLabel("No steps extracted yet")
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recipe.sortedSteps.enumerated()), id: \.element.id) { index, step in
                            AccessibleStepCard(
                                step: step,
                                isFirst: index == 0,
                                isLast: index == viewModel.recipe.sortedSteps.count - 1
                            )
                            .accessibilityIdentifier("\(AccessibilityID.stepCardPrefix)\(index)")
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier(AccessibilityID.stepsSection)
    }
}

// MARK: - Action Button Styles

/// Primary action — brand-filled pill (hero actions: Cook Along).
private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .default))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.brand)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? (isReduceMotionEnabled ? 1.0 : 0.97) : 1.0)
            .accessibleAnimation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary action — outlined pill (important but not hero: Save).
private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .default))
            .foregroundStyle(Color.softInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cooksLine, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .accessibleAnimation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Tertiary action — compact ghost pill (secondary actions: Cooking Mode, Edit).
private struct TertiaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium, design: .default))
            .foregroundStyle(Color.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cooksLine.opacity(0.6), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .accessibleAnimation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Meta Item

private struct MetaItem: View {
    let icon: String
    let label: String
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .decorative()
            Text(label)
                .font(.cooksMicro)
        }
        .foregroundStyle(highlighted ? Color.brand : Color.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(highlighted ? Color.brandSoft : Color.surfaceAlt)
        )
    }
}

// MARK: - Accessible Step Card

private struct AccessibleStepCard: View {
    let step: RecipeStep
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        StepCard(step: step, isFirst: isFirst, isLast: isLast)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Step \(step.displayOrder + 1) of the recipe")
    }

    private var accessibilityLabel: String {
        var label = "Step \(step.displayOrder + 1): \(step.title). \(step.instruction)"
        if let duration = step.durationMinutes, duration > 0 {
            label += ". Duration: \(AccessibilityFormatter.cookingTime(minutes: duration))"
        }
        return label
    }
}

// MARK: - Accessible Ingredient Checklist

private struct AccessibleIngredientChecklist: View {
    let viewModel: RecipeDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.recipe.sortedIngredients, id: \.id) { ingredient in
                AccessibleIngredientRow(
                    ingredient: ingredient,
                    onToggle: { viewModel.toggleIngredient(ingredient) }
                )
                .accessibilityIdentifier("\(AccessibilityID.ingredientRowPrefix)\(ingredient.id)")

                if ingredient.id != viewModel.recipe.sortedIngredients.last?.id {
                    Divider()
                        .background(Color.cooksLine)
                        .padding(.leading, 48)
                        .decorative()
                }
            }
        }
    }
}

// MARK: - Accessible Ingredient Row

private struct AccessibleIngredientRow: View {
    let ingredient: Ingredient
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

                    if let quantity = ingredient.quantity, !quantity.isEmpty {
                        Text(ingredient.shortDisplayText)
                            .font(.cooksCaption)
                            .foregroundStyle(Color.muted)
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
        .accessibilityHint("Double tap to toggle \(ingredient.isChecked ? "uncheck" : "check") this ingredient")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(
            title: "Authentic Neapolitan Pizza",
            heroNote: "The secret is a 72-hour cold ferment on the dough.",
            servings: 4,
            prepTimeMinutes: 30,
            cookTimeMinutes: 90,
            totalTimeMinutes: 120,
            status: .ready,
            confidence: .high,
            confidenceScore: 95,
            confidenceNote: "All ingredients and steps clearly verbalized in the video.",
            sourceUrl: "https://youtube.com/watch?v=example",
            sourcePlatform: .youtube,
            sourceCreator: "Vito Iacopelli",
            sourceTitle: "How To Make Neapolitan Pizza At Home"
        ))
    }
}
