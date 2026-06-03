import SwiftUI

// MARK: - Cooksy Typography System

extension Font {
    /// Hero text — onboarding headlines, large empty state titles.
    /// Uses Dynamic Type largeTitle with rounded design.
    static let cooksHero: Font = .system(.largeTitle, design: .rounded).weight(.bold)

    /// H1 — screen titles, major section headers.
    /// Uses Dynamic Type title2 with rounded design.
    static let cooksH1: Font = .system(.title2, design: .rounded).weight(.bold)

    /// H2 — card titles, recipe names, modal headers.
    /// Uses Dynamic Type title3 with rounded design.
    static let cooksH2: Font = .system(.title3, design: .rounded).weight(.bold)

    /// H3 — sub-headings, ingredient group titles, step titles.
    /// Uses Dynamic Type headline with rounded design.
    static let cooksH3: Font = .system(.headline, design: .rounded).weight(.semibold)

    /// Body — primary readable text, descriptions, instructions.
    /// Uses Dynamic Type body.
    static let cooksBody: Font = .system(.body, design: .default)

    /// Body bold — emphasized body text, button labels.
    /// Uses Dynamic Type body with semibold weight.
    static let cooksBodyBold: Font = .system(.body, design: .default).weight(.semibold)

    /// Callout — supporting info, captions on cards, metadata.
    /// Uses Dynamic Type callout.
    static let cooksCallout: Font = .system(.callout, design: .default)

    /// Caption — small labels, timestamps, fine print.
    /// Uses Dynamic Type caption.
    static let cooksCaption: Font = .system(.caption, design: .default)

    /// Micro — badges, tags, pill labels.
    /// Uses Dynamic Type caption2 with medium weight.
    static let cooksMicro: Font = .system(.caption2, design: .default).weight(.medium)
}

// MARK: - Scaled Text ViewModifier

/// Applies minimumScaleFactor to text so it adapts gracefully to larger Dynamic Type sizes.
struct ScaledText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .minimumScaleFactor(0.7)
            .lineLimit(nil)
    }
}

extension View {
    /// Applies a minimum scale factor of 0.7 so text remains readable at larger Dynamic Type sizes.
    func scaledText() -> some View {
        modifier(ScaledText())
    }
}

// MARK: - Accessibility Text Size Helpers

extension View {
    /// Conditionally applies a modifier based on the current Dynamic Type size.
    func adaptiveSize<
        T: View
    >(
        compact: @escaping (Self) -> T,
        regular: @escaping (Self) -> T,
        large: @escaping (Self) -> T
    ) -> some View {
        AdaptiveSizeView(
            content: self,
            compact: compact,
            regular: regular,
            large: large
        )
    }
}

/// View wrapper that applies different configurations based on Dynamic Type size category.
private struct AdaptiveSizeView<Content: View, Output: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let content: Content
    let compact: (Content) -> Output
    let regular: (Content) -> Output
    let large: (Content) -> Output

    var body: some View {
        if dynamicTypeSize <= .medium {
            compact(content)
        } else if dynamicTypeSize <= .xxLarge {
            regular(content)
        } else {
            large(content)
        }
    }
}
