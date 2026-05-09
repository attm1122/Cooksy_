import SwiftUI

// MARK: - CookingModeView

/// A full-screen immersive cooking mode view.
///
/// Provides a hands-free, distraction-free cooking experience with:
/// - Dark `Color.ink` background for visibility in a kitchen setting
/// - Large white recipe title (32pt)
/// - Progress bar showing overall completion
/// - Current step card with cream background and large, readable text
/// - Previous/Next navigation buttons
/// - Swipe gesture support for step navigation
///
/// Uses the Core `RecipeStep` model for step data.
struct CookingModeView: View {

    /// The view model managing the cooking session state.
    @State var viewModel: CookingModeViewModel

    /// Called when the user dismisses cooking mode.
    var onDismiss: () -> Void

    /// The recipe being cooked.
    private let recipe: Recipe

    /// Creates a cooking mode view for a recipe.
    init(recipe: Recipe) {
        self.recipe = recipe
        self._viewModel = State(wrappedValue: CookingModeViewModel(recipe: recipe))
        self.onDismiss = {}
    }

    /// Creates a cooking mode view with a custom dismiss action.
    init(viewModel: CookingModeViewModel, onDismiss: @escaping () -> Void) {
        self.recipe = viewModel.recipe
        self._viewModel = State(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.ink
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                headerView

                // Progress bar
                progressBar

                // Current step card
                if let step = viewModel.currentStep {
                    AccessibleCookingStepCard(
                        step: step,
                        stepIndex: viewModel.currentStepIndex,
                        totalSteps: viewModel.recipe.sortedSteps.count
                    )
                    .accessibleAnimation(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ), value: viewModel.currentStepIndex)
                }

                Spacer()

                // Navigation controls
                navigationControls
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .accessibilityIdentifier(AccessibilityID.cookingModeView)
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    if horizontalAmount < -50 {
                        if viewModel.hasNext {
                            viewModel.nextStep()
                            announceStepChange()
                        }
                    } else if horizontalAmount > 50 {
                        if viewModel.hasPrevious {
                            viewModel.previousStep()
                            announceStepChange()
                        }
                    }
                }
        )
        // Provide swipe alternatives as accessible actions
        .accessibilityAction(named: Text("Previous step")) {
            if viewModel.hasPrevious {
                viewModel.previousStep()
                announceStepChange()
            }
        }
        .accessibilityAction(named: Text("Next step")) {
            if viewModel.hasNext {
                viewModel.nextStep()
                announceStepChange()
            }
        }
    }

    /// Announces the current step to VoiceOver when navigation occurs.
    private func announceStepChange() {
        if let step = viewModel.currentStep {
            let progressLabel = AccessibilityFormatter.stepProgress(
                current: viewModel.currentStepIndex + 1,
                total: viewModel.recipe.sortedSteps.count
            )
            let percentLabel = AccessibilityFormatter.percentage(viewModel.progress)
            announceToVoiceOver("\(progressLabel), \(percentLabel). \(step.title). \(step.instruction)")
        }
    }

    // MARK: Subviews

    /// The header with dismiss button and recipe title.
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close cooking mode")
                .accessibilityHint("Returns to the recipe detail screen")
                .accessibilityIdentifier(AccessibilityID.closeCookingModeButton)

                Spacer()

                Text(viewModel.recipe.title)
                    .font(.cooksH2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .scalableText(minScale: 0.6)
                    .accessibilityLabel("Cooking: \(viewModel.recipe.title)")

                Spacer()

                Button {
                    viewModel.restart()
                    announceToVoiceOver("Cooking restarted from step 1")
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Restart cooking")
                .accessibilityHint("Starts the recipe over from the first step")
                .accessibilityIdentifier(AccessibilityID.restartCookingButton)
            }
        }
    }

    /// The horizontal progress bar showing overall cooking progress.
    private var progressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                        .decorative()

                    Capsule()
                        .fill(Color.brand)
                        .frame(
                            width: max(0, geometry.size.width * viewModel.progress),
                            height: 6
                        )
                        .accessibleAnimation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Cooking progress")
            .accessibilityValue("\(AccessibilityFormatter.stepProgress(current: viewModel.currentStepIndex + 1, total: viewModel.recipe.sortedSteps.count)), \(AccessibilityFormatter.percentage(viewModel.progress))")
            .accessibilityIdentifier(AccessibilityID.cookingProgressBar)

            HStack {
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.recipe.sortedSteps.count)")
                    .font(.cooksCaption)
                    .foregroundStyle(.white.opacity(0.6))
                    .scalableText()

                Spacer()

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.cooksCaption.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .scalableText()
            }
        }
    }

    /// Previous/Next navigation buttons at the bottom.
    private var navigationControls: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.previousStep()
                announceStepChange()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .decorative()
                    Text("Previous")
                        .scalableText()
                }
            }
            .primaryButton()
            .disabled(!viewModel.hasPrevious)
            .opacity(viewModel.hasPrevious ? 1 : 0.4)
            .accessibilityLabel("Previous step")
            .accessibilityHint("Go back to the previous cooking step")
            .accessibilityIdentifier(AccessibilityID.previousStepButton)

            Button {
                viewModel.nextStep()
                announceStepChange()
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.hasNext ? "Next" : "Finish")
                        .scalableText()
                    Image(systemName: viewModel.hasNext ? "chevron.right" : "checkmark")
                        .decorative()
                }
            }
            .primaryButton()
            .accessibilityLabel(viewModel.hasNext ? "Next step" : "Finish cooking")
            .accessibilityHint(viewModel.hasNext ? "Go to the next cooking step" : "Complete the recipe")
            .accessibilityIdentifier(AccessibilityID.nextStepButton)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Accessible Cooking Step Card

/// A large, readable card for displaying the current step in cooking mode.
/// Uses a cream-colored background for contrast and large typography
/// optimized for reading at a distance in a kitchen.
/// Fully accessible with combined children and VoiceOver support.
private struct AccessibleCookingStepCard: View {

    /// The step to display.
    let step: RecipeStep

    /// The zero-based index of this step.
    let stepIndex: Int

    /// The total number of steps.
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Step number badge
            Text("STEP \(stepIndex + 1)")
                .font(.cooksMicro)
                .foregroundStyle(Color.muted)
                .tracking(0.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.surfaceAlt)
                .cornerRadius(8)
                .accessibilityLabel("Step \(stepIndex + 1) of \(totalSteps)")

            // Step title
            Text(step.title)
                .font(.cooksH1)
                .foregroundStyle(Color.ink)
                .scalableText(minScale: 0.5)
                .accessibilityLabel(step.title)

            // Step instruction
            Text(step.instruction)
                .font(.cooksH3)
                .foregroundStyle(Color.softInk)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .scalableText(minScale: 0.5)
                .accessibilityLabel(step.instruction)

            // Duration badge (if available)
            if let duration = step.durationMinutes, duration > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .decorative()
                    Text(step.formattedDuration)
                        .font(.cooksBody)
                        .scalableText()
                }
                .foregroundStyle(Color.muted)
                .padding(.top, 8)
                .accessibilityLabel("Duration: \(AccessibilityFormatter.cookingTime(minutes: duration))")
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "FFFDF5")) // Warm cream background
        .cornerRadius(32)
        .shadow(
            color: .black.opacity(0.12),
            radius: 20,
            x: 0,
            y: 8
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Swipe left or right to navigate between steps, or use the Previous and Next buttons below")
        .accessibilityIdentifier(AccessibilityID.currentStepCard)
    }

    private var accessibilityLabel: String {
        var label = "Step \(stepIndex + 1) of \(totalSteps): \(step.title). \(step.instruction)"
        if let duration = step.durationMinutes, duration > 0 {
            label += ". Duration: \(AccessibilityFormatter.cookingTime(minutes: duration))"
        }
        return label
    }
}

// MARK: - Preview

#Preview {
    CookingModeView(recipe: Recipe(
        title: "Neapolitan Pizza",
        servings: 4,
        prepTimeMinutes: 30,
        cookTimeMinutes: 90,
        totalTimeMinutes: 120,
        status: .ready,
        confidence: .high,
        confidenceScore: 95,
        sourceUrl: "https://youtube.com/watch?v=example",
        sourcePlatform: .youtube,
        sourceCreator: "Vito Iacopelli",
        sourceTitle: "Pizza Recipe"
    ))
}
