import SwiftUI

// MARK: - ConfidenceBanner

/// A color-coded banner displaying the AI extraction confidence for a recipe.
///
/// Shows the confidence level, numeric score (e.g., "92/100"), and an expandable
/// note explaining the confidence assessment. Uses `Colors.confidenceHigh`,
/// `confidenceMedium`, and `confidenceLow` for the background, adapting to the
/// recipe's `confidence` property from the Core `Recipe` model.
///
/// Fully accessible with VoiceOver labels, state announcements, and
/// Reduce Motion-compliant animations.
struct ConfidenceBanner: View {

    /// The recipe whose confidence information is displayed.
    let recipe: Recipe

    @State private var isExpanded: Bool = false

    // MARK: Computed

    /// The background color based on confidence level.
    private var backgroundColor: Color {
        switch recipe.confidence {
        case .high:   Color.confidenceHigh
        case .medium: Color.confidenceMedium
        case .low:    Color.confidenceLow
        }
    }

    /// The border color based on confidence level.
    private var borderColor: Color {
        switch recipe.confidence {
        case .high:   Color.confidenceHighBorder
        case .medium: Color.confidenceMediumBorder
        case .low:    Color.confidenceLowBorder
        }
    }

    /// The text color based on confidence level.
    private var textColor: Color {
        switch recipe.confidence {
        case .high:   Color.cooksSuccess
        case .medium: Color.softInk
        case .low:    Color.cooksDanger
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                HapticsService.light()
                if isExpanded {
                    announceToVoiceOver("Confidence details expanded. \(recipe.confidenceNote)")
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(textColor)
                        .decorative()

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(recipe.confidence.displayName)
                                .font(.cooksBodyBold)
                                .foregroundStyle(textColor)

                            Text("\(recipe.confidenceScore)/100")
                                .font(.cooksCaption)
                                .foregroundStyle(textColor.opacity(0.8))
                                .scalableText()
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(textColor.opacity(0.6))
                        .decorative()
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibleAnimation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityFormatter.confidence(recipe.confidence.displayName, score: recipe.confidenceScore))
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") confidence details")

            // Expandable detail section
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why this score?")
                        .font(.cooksCaption.weight(.semibold))
                        .foregroundStyle(textColor.opacity(0.8))
                        .accessibleHeading(.h4)

                    Text(recipe.confidenceNote)
                        .font(.cooksCallout)
                        .foregroundStyle(textColor.opacity(0.7))
                        .lineSpacing(3)
                        .scalableText()
                        .accessibilityLabel("Explanation: \(recipe.confidenceNote)")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

// MARK: - Preview

#Preview("High Confidence") {
    ConfidenceBanner(recipe: Recipe(
        title: "Pizza",
        servings: 4,
        status: .ready,
        confidence: .high,
        confidenceScore: 95,
        confidenceNote: "All ingredients and steps clearly verbalized in the video.",
        sourceUrl: "https://youtube.com/watch?v=example",
        sourcePlatform: .youtube,
        sourceCreator: "Chef",
        sourceTitle: "Pizza tutorial"
    ))
    .padding()
}

#Preview("Medium Confidence") {
    ConfidenceBanner(recipe: Recipe(
        title: "Pizza",
        servings: 4,
        status: .ready,
        confidence: .medium,
        confidenceScore: 72,
        confidenceNote: "Some ingredients were mentioned quickly and may be incomplete.",
        sourceUrl: "https://youtube.com/watch?v=example",
        sourcePlatform: .youtube,
        sourceCreator: "Chef",
        sourceTitle: "Pizza tutorial"
    ))
    .padding()
}

#Preview("Low Confidence") {
    ConfidenceBanner(recipe: Recipe(
        title: "Pizza",
        servings: 4,
        status: .ready,
        confidence: .low,
        confidenceScore: 45,
        confidenceNote: "Video is mostly music with minimal verbal instructions.",
        sourceUrl: "https://youtube.com/watch?v=example",
        sourcePlatform: .youtube,
        sourceCreator: "Chef",
        sourceTitle: "Pizza tutorial"
    ))
    .padding()
}
