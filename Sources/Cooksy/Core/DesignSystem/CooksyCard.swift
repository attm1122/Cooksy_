import SwiftUI

// MARK: - Standard Card

/// Floating card with subtle shadow — used for recipe cards, feature highlights.
/// Provides a consistent surface for content with accessibility grouping support.
struct CooksyCard<Content: View>: View {
    var isLarge = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(isLarge ? 24 : 20)
            .background(Color.surface)
            .cornerRadius(isLarge ? 22 : 18)
            .shadow(
                color: .black.opacity(0.06),
                radius: isLarge ? 18 : 12,
                x: 0,
                y: isLarge ? 6 : 4
            )
    }
}

// MARK: - Soft Card

/// Flat card with an alternative warm background — used for secondary content,
/// empty states, and supporting info panels.
struct SoftCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .background(Color.surfaceAlt)
            .cornerRadius(18)
    }
}

// MARK: - Compact Card Row

/// A horizontal card row for list views — minimal padding, hairline border.
/// Combines children for VoiceOver when used as a tappable row.
struct CardRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cooksLine, lineWidth: 1)
            )
    }
}

// MARK: - Accessible Action Card

/// A card that wraps content and exposes it as a single accessible element
/// with a custom label, hint, and action traits.
struct AccessibleActionCard<Content: View>: View {
    var isLarge = false
    var label: String
    var hint: String? = nil
    var action: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        Button(action: action ?? {}) {
            CooksyCard(isLarge: isLarge) {
                content
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityHint(hint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}
