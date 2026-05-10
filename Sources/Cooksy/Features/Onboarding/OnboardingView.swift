import SwiftUI

// MARK: - Onboarding Page Model

/// Represents a single onboarding screen's content.
private struct OnboardingPage {
    let id: Int
    let icon: String
    let headline: String
    let subtitle: String
    let buttonTitle: String
}

// MARK: - Onboarding View

/// A 3-screen onboarding experience for first-time Cooksy users.
///
/// Guides new users through the app's core value propositions:
/// 1. Saving recipes from any link
/// 2. Cooking along with synced video
/// 3. Organizing recipes into collections
///
/// ## Features
/// - Paged layout with custom dot indicator
/// - Spring animations (disabled when Reduce Motion is on)
/// - Haptic feedback on all interactive elements
/// - Full VoiceOver support with combined accessibility elements
/// - Dynamic Type scaling throughout
/// - Skip option available on every screen
///
/// ## Usage
/// ```swift
/// OnboardingView {
///     // Called when onboarding completes (Next on last page, or Skip)
/// }
/// ```
struct OnboardingView: View {

    // MARK: - Constants

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "link.badge.plus",
            headline: "Save Recipes from Anywhere",
            subtitle: "Paste a link from YouTube, TikTok, or Instagram. We'll extract the ingredients, steps, and timings.",
            buttonTitle: "Next"
        ),
        OnboardingPage(
            id: 1,
            icon: "play.rectangle.on.rectangle.fill",
            headline: "Cook Along with Video",
            subtitle: "Your recipe steps sync automatically with the video. Tap any step to jump to that moment.",
            buttonTitle: "Next"
        ),
        OnboardingPage(
            id: 2,
            icon: "folder.fill.badge.person.crop",
            headline: "Organize Your Kitchen",
            subtitle: "Group recipes into collections. Find what to cook in seconds.",
            buttonTitle: "Get Started"
        )
    ]

    private let onboardingKey = "hasSeenOnboarding"

    // MARK: - State

    @State private var currentPage = 0

    // MARK: - Callbacks

    /// Called when the user completes or skips onboarding.
    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.cooksBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Skip Button
                skipButton

                // MARK: Paged Content
                TabView(selection: $currentPage) {
                    ForEach(pages, id: \.id) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .accessibleAnimation(
                    .spring(response: 0.4, dampingFraction: 0.8),
                    value: currentPage
                )

                // MARK: Bottom Controls
                VStack(spacing: 20) {
                    // Page indicator dots
                    PageIndicator(
                        pageCount: pages.count,
                        currentPage: currentPage
                    )
                    .decorative()

                    // Action button (Next or Get Started)
                    actionButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .onChange(of: currentPage) { _, newPage in
            announcePageChange(pageIndex: newPage)
        }
    }

    // MARK: - Subviews

    /// Skip button anchored to the top-right of the screen.
    private var skipButton: some View {
        HStack {
            Spacer()
            Button {
                HapticsService.light()
                completeOnboarding()
            } label: {
                Text("Skip")
                    .font(.cooksBodyBold)
                    .foregroundStyle(.muted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .accessibilityLabel("Skip onboarding")
            .accessibilityHint("Skip the tutorial and go straight to the app")
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    /// The primary action button — "Next" on pages 1-2, "Get Started" on page 3.
    private var actionButton: some View {
        Button {
            handleActionButtonTap()
        } label: {
            Text(pages[currentPage].buttonTitle)
                .font(.cooksBodyBold)
                .foregroundStyle(.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brand)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .accessibilityLabel(
            currentPage == pages.count - 1
                ? "Get started with Cooksy"
                : "Next: \(pages[safe: currentPage + 1]?.headline ?? "")"
        )
        .accessibilityHint(
            currentPage == pages.count - 1
                ? "Complete onboarding and start using the app"
                : "Go to the next onboarding screen"
        )
    }

    // MARK: - Actions

    /// Handles taps on the primary action button.
    private func handleActionButtonTap() {
        if currentPage == pages.count - 1 {
            // Last page — "Get Started"
            HapticsService.heavy()
            completeOnboarding()
        } else {
            // Pages 1-2 — "Next"
            HapticsService.medium()
            withAccessibleAnimation {
                currentPage += 1
            }
        }
    }

    /// Marks onboarding as complete and notifies the parent.
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        onComplete()
    }

    /// Announces page changes to VoiceOver users.
    private func announcePageChange(pageIndex: Int) {
        guard pageIndex >= 0, pageIndex < pages.count else { return }
        let page = pages[pageIndex]
        let announcement = "\(page.headline). \(page.subtitle) Page \(pageIndex + 1) of \(pages.count)."
        announceToVoiceOver(announcement, delay: 0.3)
    }

    /// Wraps a state change in an animation that respects Reduce Motion.
    private func withAccessibleAnimation(_ action: @escaping () -> Void) {
        if isReduceMotionEnabled {
            action()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8), action)
        }
    }
}

// MARK: - Onboarding Page View

/// The content for a single onboarding screen.
/// Displays an icon, headline, and subtitle in a scrollable layout.
private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()

                // Illustration icon
                Image(systemName: page.icon)
                    .font(.system(size: 120))
                    .foregroundStyle(Color.brand)
                    .accessibilityHidden(true)
                    .padding(.bottom, 12)

                // Headline
                Text(page.headline)
                    .font(.cooksH1)
                    .foregroundStyle(.ink)
                    .multilineTextAlignment(.center)
                    .scalableText()
                    .accessibilityAddTraits(.isHeader)

                // Subtitle
                Text(page.subtitle)
                    .font(.cooksBody)
                    .foregroundStyle(.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .scalableText()

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        // Combine headline + subtitle into a single accessible element
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.headline). \(page.subtitle)")
    }
}

// MARK: - Page Indicator

/// Custom page indicator showing a row of dots with the current page highlighted.
private struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.brand : Color.muted.opacity(0.3))
                    .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                    .accessibleAnimation(
                        .spring(response: 0.35, dampingFraction: 0.7),
                        value: currentPage
                    )
            }
        }
        .frame(height: 20)
        .accessibilityLabel("Page \(currentPage + 1) of \(pageCount)")
        .accessibilityLiveRegion(.polite)
    }
}

// MARK: - Safe Array Access

private extension Array {
    /// Safe subscript that returns nil instead of crashing on out-of-bounds access.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView {
        #if DEBUG
        print("Onboarding complete")
        #endif
    }
}

#Preview("Onboarding - Page 2") {
    // Preview starting on page 2 to verify layout
    OnboardingView(onComplete: {})
    .onAppear {
        // Note: Cannot modify @State directly in preview, this is for visual reference
    }
}
