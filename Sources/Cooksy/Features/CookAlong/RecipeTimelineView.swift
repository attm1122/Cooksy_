import SwiftUI

/// Shows recipe steps in a scrollable list with the active step
/// highlighted based on video playback position.
///
/// Tap a step to seek the video to that step's start time.
/// The active step gets a yellow left border, cream background,
/// and a "Replay This Step" button.
struct RecipeTimelineView: View {

    let recipe: Recipe
    let syncMap: RecipeSyncMap
    @Bindable var viewModel: CookAlongViewModel

    // Scroll to active step
    @Namespace private var scrollNamespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(recipe.sortedSteps.enumerated()), id: \.element.id) { index, step in
                        StepRow(
                            step: step,
                            index: index,
                            timestamp: syncMap.timestamp(forStepIndex: index),
                            isActive: index == viewModel.activeStepIndex,
                            timeRange: viewModel.formattedTimeRange(for: index),
                            onTap: { viewModel.tapStep(at: index) },
                            onReplay: { viewModel.replayCurrentStep() }
                        )
                        .id(index)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.activeStepIndex) { _, newIndex in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .background(Color.cooksBackground)
    }
}

// MARK: - Step Row

struct StepRow: View {
    let step: RecipeStep
    let index: Int
    let timestamp: RecipeTimestamp?
    let isActive: Bool
    let timeRange: String
    let onTap: () -> Void
    let onReplay: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Active indicator bar
                Rectangle()
                    .fill(isActive ? Color.brand : Color.clear)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 8) {
                    // Step header
                    HStack {
                        Text("STEP \(index + 1)")
                            .font(.system(size: 11, weight: .semibold, design: .default))
                            .foregroundStyle(isActive ? Color.brand : Color.muted)
                            .tracking(1)

                        Spacer()

                        if let ts = timestamp {
                            Text(timeRange)
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundStyle(Color.muted)

                            // Confidence badge
                            ConfidenceDot(confidence: ts.confidence)
                        }
                    }

                    // Step title
                    Text(step.title)
                        .font(.system(size: isActive ? 20 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)

                    // Step instruction
                    Text(step.instruction)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundStyle(Color.softInk)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)

                    // Duration badge
                    if let duration = step.durationMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text("\(duration) min")
                                .font(.system(size: 13, weight: .medium, design: .default))
                        }
                        .foregroundStyle(Color.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.cooksLine.opacity(0.5))
                        .clipShape(Capsule())
                    }

                    // Replay button (only on active step)
                    if isActive {
                        Button(action: onReplay) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Replay This Step")
                                    .font(.system(size: 14, weight: .semibold, design: .default))
                            }
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.brand)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }

                    // Trigger phrase (what the creator said)
                    if isActive, let phrase = timestamp?.triggerPhrase {
                        HStack(spacing: 6) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.muted)
                            Text("\"\(phrase)\"")
                                .italic()
                                .font(.system(size: 13, design: .default))
                                .foregroundStyle(Color.muted)
                                .lineLimit(2)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                Spacer()
            }
            .background(isActive ? Color.brand.opacity(0.08) : Color.cooksBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(index + 1): \(step.title)")
        .accessibilityHint(isActive ? "Currently playing. Double tap to replay." : "Double tap to jump to this step.")
        .accessibilityAddTraits(isActive ? [.isHeader] : [])
    }
}

// MARK: - Confidence Dot

struct ConfidenceDot: View {
    let confidence: Double

    var color: Color {
        switch confidence {
        case 0.9...1.0: return Color(red: 0.11, green: 0.56, blue: 0.37) // green
        case 0.7..<0.9: return Color(red: 0.94, green: 0.85, blue: 0.42) // yellow
        default: return Color(red: 0.72, green: 0.28, blue: 0.19) // red
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .accessibilityLabel("Confidence \(Int(confidence * 100)) percent")
    }
}
