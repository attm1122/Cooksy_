import SwiftUI

// MARK: - Cooksy Color System

// MARK: - Color Aliases (Semantic Shortcuts)

extension Color {
    /// Alias for the main app background — warm off-white.
    /// Same as `cooksBackground`.
    static let cream = cooksBackground

    /// Alias for the alternative surface — warm beige.
    /// Same as `surfaceAlt`.
    static let creamDark = surfaceAlt

    /// Alias for the primary brand yellow.
    /// Same as `brand`.
    static let warmYellow = brand

    /// Alias for primary text — near-black.
    /// Same as `ink`.
    static let textPrimary = ink

    /// Alias for tertiary / placeholder text — warm gray.
    /// Same as `muted`.
    static let textMuted = muted

    /// Alias for primary text — near-black.
    /// Same as `ink`.
    static let textSecondary = softInk

    /// Primary brand yellow — used for CTAs, primary buttons, accents.
    static let brand = Color(hex: "F5C400")

    /// Soft brand tint — used for highlights, badges, subtle backgrounds.
    static let brandSoft = Color(hex: "FFF6CC")

    /// Main app background — warm off-white for a kitchen-friendly feel.
    /// Automatically adapts to dark mode.
    static let cooksBackground = adaptive(
        light: Color(hex: "FFFDF7"),
        dark: Color(hex: "1A1814")
    )

    /// Card and sheet surfaces — pure white for contrast on the warm background.
    /// Automatically adapts to dark mode.
    static let surface = adaptive(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "2A2620")
    )

    /// Alternative surface — warm beige for secondary cards, empty states.
    /// Automatically adapts to dark mode.
    static let surfaceAlt = adaptive(
        light: Color(hex: "F7F2E6"),
        dark: Color(hex: "3A3628")
    )

    /// Primary text color — near-black for headings and body text.
    /// Automatically adapts to dark mode.
    static let ink = adaptive(
        light: Color(hex: "111111"),
        dark: Color(hex: "F5F0E8")
    )

    /// Secondary text — slightly lighter for subtitles and supporting text.
    /// Automatically adapts to dark mode.
    static let softInk = adaptive(
        light: Color(hex: "262626"),
        dark: Color(hex: "D8D3C9")
    )

    /// Tertiary / placeholder text — warm gray.
    /// Automatically adapts to dark mode.
    static let muted = adaptive(
        light: Color(hex: "706B61"),
        dark: Color(hex: "A8A090")
    )

    /// Border color for cards, inputs, and dividers.
    /// Automatically adapts to dark mode.
    static let cooksBorder = adaptive(
        light: Color(hex: "E9E2D1"),
        dark: Color(hex: "4A4538")
    )

    /// Hairline dividers and separators.
    /// Automatically adapts to dark mode.
    static let cooksLine = adaptive(
        light: Color(hex: "EEE7D6"),
        dark: Color(hex: "3A3628")
    )

    /// Success state — used for high confidence, saved confirmations.
    static let cooksSuccess = Color(hex: "1D8F5F")

    /// Danger state — errors, destructive actions.
    static let cooksDanger = Color(hex: "B94831")

    // MARK: - Confidence Colors

    static let confidenceHigh = adaptive(
        light: Color(hex: "EEF9F2"),
        dark: Color(hex: "1A3D2A")
    )
    static let confidenceHighBorder = adaptive(
        light: Color(hex: "D0EDD9"),
        dark: Color(hex: "2A5C3E")
    )
    static let confidenceMedium = adaptive(
        light: Color(hex: "FFF8E1"),
        dark: Color(hex: "3D3514")
    )
    static let confidenceMediumBorder = adaptive(
        light: Color(hex: "F0D96B"),
        dark: Color(hex: "6B5E20")
    )
    static let confidenceLow = adaptive(
        light: Color(hex: "FFF1EE"),
        dark: Color(hex: "3D1A14")
    )
    static let confidenceLowBorder = adaptive(
        light: Color(hex: "F1D0C8"),
        dark: Color(hex: "6B2E22")
    )

    // MARK: - Platform Colors

    static let youtubeRed = Color(hex: "FF0000")
    static let tikTokBlack = adaptive(light: Color(hex: "000000"), dark: Color(hex: "1A1A1A"))
    static let instagramPink = Color(hex: "E4405F")

    // MARK: - Adaptive Color Helper

    /// Creates a color that automatically adapts between light and dark mode.
    /// On iOS 17+, this uses the system adaptive color API.
    /// On earlier versions, it falls back to a custom implementation.
    private static func adaptive(light: Color, dark: Color) -> Color {
        Color(
            UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(dark)
                } else {
                    return UIColor(light)
                }
            }
        )
    }

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - cgColor Helper

private extension Color {
    var cgColor: CGColor? {
        UIColor(self).cgColor
    }
}

// MARK: - AdaptiveColor ViewModifier

/// A view modifier that applies different colors based on the current color scheme.
/// Used for views that need more granular dark mode control than the static Color adaptives.
private struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var light: Color
    var dark: Color

    func body(content: Content) -> some View {
        content.foregroundStyle(colorScheme == .dark ? dark : light)
    }
}

extension View {
    /// Applies an adaptive foreground color that changes between light and dark mode.
    func adaptiveForegroundColor(light: Color, dark: Color) -> some View {
        modifier(AdaptiveColorModifier(light: light, dark: dark))
    }
}

// MARK: - Dark Mode Preview Helpers

extension View {
    /// Previews this view in both light and dark mode simultaneously.
    func previewBothColorSchemes() -> some View {
        Group {
            self
                .previewDisplayName("Light")
            self
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
