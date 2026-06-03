import SwiftUI

// MARK: - StepCard

/// A card view displaying a single recipe step with a vertical connecting line.
///
/// Shows the step number, title (18pt semibold), instruction text (16pt regular),
/// and an optional duration badge. Includes a vertical line on the leading edge
/// that visually connects consecutive steps into a timeline.
///
/// Fully accessible with combined children for VoiceOver, decorative timeline
/// connector, and meaningful step descriptions.
struct StepCard: View {

    /// The step to display. Uses the Core `RecipeStep` model.
    let step: RecipeStep

    /// Whether this is the first step in the sequence (controls line rendering).
    let isFirst: Bool

    /// Whether this is the last step in the sequence (controls line rendering).
    let isLast: Bool

    // MARK: Body

    var body: some View {
        HStack(spacing: 16) {
            // Timeline connector - decorative only
            timelineConnector
                .decorative()

            // Step content
            VStack(alignment: .leading, spacing: 8) {
                stepNumberLabel
                titleView
                instructionView

                if let duration = step.durationMinutes, duration > 0 {
                    durationBadge(duration)
                }
            }
            .padding(20)
            .background(Color.surface)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.cooksLine, lineWidth: 1)
            )
        }
    }

    // MARK: Subviews

    /// The vertical timeline line with a dot indicator. Decorative - hidden from VoiceOver.
    private var timelineConnector: some View {
        ZStack {
            // Vertical connecting line
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.cooksBorder)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                        .frame(maxHeight: .infinity)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color.cooksBorder)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()
                        .frame(maxHeight: .infinity)
                }
            }

            // Step number dot
            ZStack {
                Circle()
                    .fill(Color.brandSoft)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.brand, lineWidth: 1.5)
                    )

                Text("\(step.displayOrder + 1)")
                    .font(.cooksCaption.weight(.semibold))
                    .foregroundStyle(Color.softInk)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 36)
    }

    /// The "STEP N" label above the title.
    private var stepNumberLabel: some View {
        Text("STEP \(step.displayOrder + 1)")
            .font(.cooksMicro)
            .foregroundStyle(Color.muted)
            .tracking(0.5)
            .accessibilityLabel("Step \(step.displayOrder + 1)")
    }

    /// The step title.
    private var titleView: some View {
        Text(step.title)
            .font(.cooksH3)
            .foregroundStyle(Color.ink)
            .scalableText()
            .accessibilityLabel(step.title)
    }

    /// The step instruction text.
    private var instructionView: some View {
        Text(step.instruction)
            .font(.cooksBody)
            .foregroundStyle(Color.softInk)
            .lineSpacing(4)
            .scalableText()
            .accessibilityLabel(step.instruction)
    }

    /// A duration badge showing the estimated time for this step.
    /// - Parameter minutes: The duration in minutes.
    private func durationBadge(_ minutes: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.cooksCaption)
                .decorative()
            Text(Formatters.formatTime(minutes))
                .font(.cooksCaption.weight(.medium))
                .scalableText()
        }
        .foregroundStyle(Color.muted)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.surfaceAlt)
        .cornerRadius(8)
        .accessibilityLabel("Duration: \(AccessibilityFormatter.cookingTime(minutes: minutes))")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        StepCard(
            step: RecipeStep(
                title: "Make the dough",
                instruction: "Combine flour, water, salt, and yeast. Knead for 10 minutes until smooth and elastic.",
                durationMinutes: 15,
                displayOrder: 0
            ),
            isFirst: true,
            isLast: false
        )

        StepCard(
            step: RecipeStep(
                title: "Let it rise",
                instruction: "Cover and let rise in a warm place for 1 hour until doubled in size.",
                durationMinutes: 60,
                displayOrder: 1
            ),
            isFirst: false,
            isLast: false
        )

        StepCard(
            step: RecipeStep(
                title: "Shape and bake",
                instruction: "Shape into a round, add toppings, and bake at 500°F for 8 minutes.",
                durationMinutes: 8,
                displayOrder: 2
            ),
            isFirst: false,
            isLast: true
        )
    }
    .padding(.horizontal, 16)
    .background(Color.cooksBackground)
}
