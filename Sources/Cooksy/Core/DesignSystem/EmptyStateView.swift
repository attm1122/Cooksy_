import SwiftUI

// MARK: - Empty State View

/// Reusable empty state component for lists with no content.
/// Displays an icon, title, description, and optional action button inside
/// a dashed-border card.
struct EmptyStateView: View {
    var icon: String = "bookmark.slash"
    var title: String
    var description: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.muted)
                .decorative()

            Text(title)
                .font(.cooksH2)
                .foregroundStyle(Color.ink)
                .accessibleHeading(.h2)
                .scalableText()

            Text(description)
                .font(.cooksCallout)
                .foregroundStyle(Color.muted)
                .multilineTextAlignment(.center)
                .scalableText()

            if let action = action, let label = actionLabel {
                Button(label, action: action)
                    .primaryButton()
                    .padding(.top, 8)
                    .accessibilityLabel(label)
                    .accessibilityHint("Takes action to resolve the empty state")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.cooksBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

// MARK: - Loading State View

/// Shown while content is being fetched.
struct LoadingStateView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.brand)
                .accessibilityLabel("Loading in progress")

            Text(message)
                .font(.cooksCallout)
                .foregroundStyle(Color.muted)
                .scalableText()
                .accessibilityLabel(message)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.surfaceAlt)
        .cornerRadius(22)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message), please wait")
    }
}

// MARK: - Error State View

/// Shown when content fails to load.
struct ErrorStateView: View {
    var message: String = "Something went wrong"
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(Color.cooksDanger)
                .decorative()

            Text(message)
                .font(.cooksCallout)
                .foregroundStyle(Color.softInk)
                .multilineTextAlignment(.center)
                .scalableText()
                .accessibilityLabel("Error: \(message)")

            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .secondaryButton()
                    .padding(.top, 4)
                    .accessibilityLabel("Try again")
                    .accessibilityHint("Attempts to reload the content")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.confidenceLow)
                .stroke(Color.confidenceLowBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message). \(retryAction != nil ? "Double tap Try Again to reload." : "")")
    }
}
