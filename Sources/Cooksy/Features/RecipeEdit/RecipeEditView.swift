import SwiftUI
import SwiftData

// MARK: - RecipeEditView

/// A form view for editing a recipe's details.
///
/// Provides editable sections for the recipe title, servings, prep/cook times,
/// ingredients list, and steps list. Uses the Core `Recipe`, `Ingredient`,
/// and `RecipeStep` models throughout.
///
/// Fully accessible with VoiceOver labels for all form fields, stepper announcements,
/// and proper form navigation.
struct RecipeEditView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel: RecipeEditViewModel

    /// Called when the user finishes editing (save or cancel).
    var onFinish: () -> Void

    // MARK: - Initialization

    /// Creates a new recipe edit view.
    /// - Parameters:
    ///   - recipe: The recipe to edit.
    ///   - onFinish: Called when editing is complete.
    init(recipe: Recipe, onFinish: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: RecipeEditViewModel(recipe: recipe))
        self.onFinish = onFinish
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                titleSection

                // Servings section
                servingsSection

                // Timing section
                timingSection

                // Ingredients section
                ingredientsSection

                // Steps section
                stepsSection
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityLabel("Edit recipe form")
            .task {
                // Inject the ModelContext from the environment into the ViewModel.
                viewModel.setModelContext(modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        announceToVoiceOver("Edit cancelled")
                        onFinish()
                    }
                    .foregroundStyle(Color.muted)
                    .accessibilityLabel("Cancel editing")
                    .accessibilityHint("Discards changes and closes the editor")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        announceToVoiceOver("Recipe saved successfully")
                        onFinish()
                    }
                    .font(.cooksBodyBold)
                    .foregroundStyle(Color.ink)
                    .disabled(!viewModel.hasChanges)
                    .accessibilityLabel("Save recipe changes")
                    .accessibilityHint(viewModel.hasChanges ? "Saves all changes to the recipe" : "No changes to save")
                }
            }
        }
    }

    // MARK: Sections

    /// The recipe title text field section.
    private var titleSection: some View {
        Section {
            TextField("Recipe title", text: $viewModel.recipe.title)
                .font(.cooksH3)
                .accessibilityLabel("Recipe title")
                .accessibilityHint("Enter the name of the recipe")
        } header: {
            Text("Title")
                .font(.cooksCaption)
                .foregroundStyle(Color.muted)
                .accessibilityLabel("Recipe title section")
        }
    }

    /// The servings stepper section.
    private var servingsSection: some View {
        Section {
            Stepper(
                Formatters.formatServings(viewModel.recipe.servings),
                value: $viewModel.recipe.servings,
                in: 1...99
            )
            .font(.cooksBody)
            .onChange(of: viewModel.recipe.servings) { _, newValue in
                viewModel.hasChanges = true
                announceToVoiceOver("Servings changed to \(newValue)")
            }
            .accessibilityLabel("Number of servings")
            .accessibilityValue("\(viewModel.recipe.servings) servings")
            .accessibilityHint("Use the stepper to adjust the number of servings from 1 to 99")
        } header: {
            Text("Servings")
                .font(.cooksCaption)
                .foregroundStyle(Color.muted)
                .accessibilityLabel("Servings section")
        }
    }

    /// The prep time and cook time picker section.
    private var timingSection: some View {
        Section {
            HStack {
                Text("Prep time")
                    .font(.cooksBody)
                    .accessibilityLabel("Preparation time")
                Spacer()
                Picker("Prep time", selection: $viewModel.recipe.prepTimeMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text(Formatters.formatTime(minutes))
                            .tag(minutes)
                            .accessibilityLabel(AccessibilityFormatter.cookingTime(minutes: minutes))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.recipe.prepTimeMinutes) { _, newValue in
                    viewModel.hasChanges = true
                    announceToVoiceOver("Prep time set to \(AccessibilityFormatter.cookingTime(minutes: newValue))")
                }
                .accessibilityLabel("Preparation time picker")
                .accessibilityValue(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.prepTimeMinutes))
            }

            HStack {
                Text("Cook time")
                    .font(.cooksBody)
                    .accessibilityLabel("Cooking time")
                Spacer()
                Picker("Cook time", selection: $viewModel.recipe.cookTimeMinutes) {
                    ForEach(timeOptions, id: \.self) { minutes in
                        Text(Formatters.formatTime(minutes))
                            .tag(minutes)
                            .accessibilityLabel(AccessibilityFormatter.cookingTime(minutes: minutes))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.recipe.cookTimeMinutes) { _, newValue in
                    viewModel.hasChanges = true
                    announceToVoiceOver("Cook time set to \(AccessibilityFormatter.cookingTime(minutes: newValue))")
                }
                .accessibilityLabel("Cooking time picker")
                .accessibilityValue(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.cookTimeMinutes))
            }

            HStack {
                Text("Total time")
                    .font(.cooksBody)
                    .accessibilityLabel("Total cooking time")
                Spacer()
                Text(Formatters.formatTime(viewModel.recipe.totalTimeMinutes))
                    .font(.cooksBody)
                    .foregroundStyle(Color.muted)
                    .accessibilityLabel(AccessibilityFormatter.cookingTime(minutes: viewModel.recipe.totalTimeMinutes))
            }
        } header: {
            Text("Timing")
                .font(.cooksCaption)
                .foregroundStyle(Color.muted)
                .accessibilityLabel("Timing section")
        }
    }

    /// The editable ingredients list section.
    private var ingredientsSection: some View {
        Section {
            ForEach($viewModel.ingredients, id: \.id) { $ingredient in
                AccessibleIngredientEditRow(ingredient: $ingredient) {
                    viewModel.hasChanges = true
                }
            }
            .onDelete { indexSet in
                viewModel.removeIngredient(at: indexSet)
                announceToVoiceOver("Ingredient deleted")
            }
            .onMove { from, to in
                viewModel.moveIngredient(from: from, to: to)
                announceToVoiceOver("Ingredient moved")
            }

            Button {
                viewModel.addIngredient()
                announceToVoiceOver("New ingredient added")
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .decorative()
                    Text("Add Ingredient")
                }
            }
            .font(.cooksBodyBold)
            .foregroundStyle(Color.ink)
            .accessibilityLabel("Add a new ingredient")
            .accessibilityHint("Adds a blank ingredient row to the list")
        } header: {
            HStack {
                Text("Ingredients")
                    .font(.cooksCaption)
                    .foregroundStyle(Color.muted)
                    .accessibilityLabel("Ingredients section, \(viewModel.ingredients.count) items")
                Spacer()
                EditButton()
                    .font(.cooksCaption)
                    .accessibilityLabel("Edit ingredients list")
            }
        }
    }

    /// The editable steps list section.
    private var stepsSection: some View {
        Section {
            ForEach($viewModel.steps, id: \.id) { $step in
                AccessibleStepEditRow(step: $step) {
                    viewModel.hasChanges = true
                }
            }
            .onDelete { indexSet in
                viewModel.removeStep(at: indexSet)
                announceToVoiceOver("Step deleted")
            }
            .onMove { from, to in
                viewModel.moveStep(from: from, to: to)
                announceToVoiceOver("Step moved")
            }

            Button {
                viewModel.addStep()
                announceToVoiceOver("New step added")
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .decorative()
                    Text("Add Step")
                }
            }
            .font(.cooksBodyBold)
            .foregroundStyle(Color.ink)
            .accessibilityLabel("Add a new step")
            .accessibilityHint("Adds a blank step to the recipe")
        } header: {
            HStack {
                Text("Steps")
                    .font(.cooksCaption)
                    .foregroundStyle(Color.muted)
                    .accessibilityLabel("Steps section, \(viewModel.steps.count) items")
                Spacer()
                EditButton()
                    .font(.cooksCaption)
                    .accessibilityLabel("Edit steps list")
            }
        }
    }

    // MARK: Time Options

    /// Predefined time options for the prep/cook time pickers.
    private var timeOptions: [Int] {
        Array(stride(from: 0, through: 180, by: 5))
    }
}

// MARK: - Accessible IngredientEditRow

/// An accessibility-enhanced editable row for a single ingredient in the edit form.
/// Provides VoiceOver labels for each field and announces changes.
struct AccessibleIngredientEditRow: View {

    @Binding var ingredient: Ingredient
    var onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Ingredient name", text: $ingredient.name)
                .font(.cooksBodyBold)
                .onChange(of: ingredient.name) { _, _ in onChange() }
                .accessibilityLabel("Ingredient name")
                .accessibilityHint("Enter the name of this ingredient")

            HStack(spacing: 12) {
                TextField("Qty", text: Binding(
                    get: { ingredient.quantity ?? "" },
                    set: { ingredient.quantity = $0.isEmpty ? nil : $0 }
                ))
                .font(.cooksBody)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .onChange(of: ingredient.quantity ?? "") { _, _ in onChange() }
                .accessibilityLabel("Quantity")
                .accessibilityHint("Enter the quantity amount")

                TextField("Unit", text: Binding(
                    get: { ingredient.unit ?? "" },
                    set: { ingredient.unit = $0.isEmpty ? nil : $0 }
                ))
                .font(.cooksBody)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .onChange(of: ingredient.unit ?? "") { _, _ in onChange() }
                .accessibilityLabel("Unit of measurement")
                .accessibilityHint("Enter the unit, such as cups, tablespoons, or grams")

                Spacer()
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ingredient: \(ingredient.name)\(ingredient.quantity.map { ", \($0)" } ?? "")\(ingredient.unit.map { " \($0)" } ?? "")")
    }
}

// MARK: - Accessible StepEditRow

/// An accessibility-enhanced editable row for a single step in the edit form.
/// Provides VoiceOver labels for each field and announces the step number.
struct AccessibleStepEditRow: View {

    @Binding var step: RecipeStep
    var onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(step.displayOrder + 1)")
                    .font(.cooksCaption)
                    .foregroundStyle(Color.muted)
                    .scalableText()
                    .accessibilityLabel("Step \(step.displayOrder + 1)")

                Spacer()

                if let duration = step.durationMinutes, duration > 0 {
                    Text(Formatters.formatTime(duration))
                        .font(.cooksCaption)
                        .foregroundStyle(Color.muted)
                        .scalableText()
                        .accessibilityLabel("Duration \(AccessibilityFormatter.cookingTime(minutes: duration))")
                }
            }

            TextField("Step title", text: $step.title)
                .font(.cooksBodyBold)
                .onChange(of: step.title) { _, _ in onChange() }
                .accessibilityLabel("Step \(step.displayOrder + 1) title")
                .accessibilityHint("Enter a short title for this step")

            TextEditor(text: $step.instruction)
                .font(.cooksBody)
                .frame(minHeight: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cooksBorder, lineWidth: 1)
                )
                .onChange(of: step.instruction) { _, _ in onChange() }
                .accessibilityLabel("Step \(step.displayOrder + 1) instructions")
                .accessibilityHint("Enter detailed instructions for this step")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    RecipeEditView(
        viewModel: RecipeEditViewModel(recipe: Recipe(
            title: "Test Recipe",
            servings: 4,
            sourceUrl: "https://example.com",
            sourcePlatform: .youtube,
            sourceCreator: "Chef"
        )),
        onFinish: {}
    )
}
