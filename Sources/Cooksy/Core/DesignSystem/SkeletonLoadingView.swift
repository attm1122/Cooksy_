import SwiftUI

// MARK: - Skeleton Loading View

/// Skeleton loading shimmer effect for recipe cards and lists.
/// Uses a sliding gradient animation to suggest content is loading.
///
/// Respects Reduce Motion settings — shows static placeholders instead of shimmer.
///
/// ## Usage
/// ```swift
/// if viewModel.isLoading {
///     SkeletonLoadingView(cardCount: 3)
/// } else {
///     RecipeList(recipes: viewModel.recipes)
/// }
/// ```
struct SkeletonLoadingView: View {
    /// Number of skeleton cards to render in the stack.
    let cardCount: Int

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<cardCount, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading recipes")
        .accessibilityHint("Please wait while recipes are being loaded.")
    }
}

// MARK: - Skeleton Card

/// A single skeleton card that mimics the shape of a `RecipeRow`.
/// Shows a shimmer animation unless Reduce Motion is enabled.
struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.surfaceAlt)
                .frame(width: 80, height: 80)
                .shimmer(isAnimating: $isAnimating)

            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.surfaceAlt)
                    .frame(width: 180, height: 16)
                    .shimmer(isAnimating: $isAnimating)

                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.surfaceAlt)
                    .frame(width: 120, height: 12)
                    .shimmer(isAnimating: $isAnimating)

                // Meta placeholder
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceAlt)
                        .frame(width: 60, height: 12)
                        .shimmer(isAnimating: $isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceAlt)
                        .frame(width: 50, height: 12)
                        .shimmer(isAnimating: $isAnimating)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cooksLine, lineWidth: 1)
        )
        .onAppear {
            if !isReduceMotionEnabled {
                isAnimating = true
            }
        }
    }
}

// MARK: - Hero Skeleton

/// Skeleton placeholder for the home hero card.
/// Use this while the hero content is being loaded or processed.
struct HeroSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.surfaceAlt)
                .frame(width: 60, height: 60)
                .shimmer(isAnimating: $isAnimating)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.surfaceAlt)
                .frame(width: 240, height: 20)
                .shimmer(isAnimating: $isAnimating)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.surfaceAlt)
                .frame(width: 280, height: 14)
                .shimmer(isAnimating: $isAnimating)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 6)
        .onAppear {
            if !isReduceMotionEnabled {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading hero content")
        .accessibilityHidden(true)
    }
}

// MARK: - Shimmer Modifier

/// A view modifier that applies a shimmer (sliding gradient) effect.
/// Automatically respects Reduce Motion settings.
private struct ShimmerModifier: ViewModifier {
    @Binding var isAnimating: Bool

    func body(content: Content) -> some View {
        if isReduceMotionEnabled {
            // Static placeholder when Reduce Motion is enabled
            content
        } else {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.35),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(
                            x: isAnimating
                                ? geometry.size.width
                                : -geometry.size.width
                        )
                        .animation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    }
                    .clipShape(Rectangle())
                )
                .mask(content)
        }
    }
}

private extension View {
    /// Applies a shimmer effect to this view when `isAnimating` is true.
    /// Respects Reduce Motion settings automatically.
    func shimmer(isAnimating: Binding<Bool>) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

// MARK: - Preview

#Preview("Skeleton Loading") {
    ScrollView {
        VStack(spacing: 20) {
            HeroSkeleton()

            SkeletonLoadingView(cardCount: 3)
        }
        .padding(.top, 20)
    }
    .background(Color.cooksBackground)
}
