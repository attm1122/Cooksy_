import SwiftUI

// MARK: - Platform Badge

/// A small pill badge showing the source platform (YouTube, TikTok, Instagram).
/// Includes the platform icon, name, and appropriate brand-tinted colors.
struct PlatformBadge: View {
    var platform: SourcePlatform
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: platform.iconName)
                .font(.system(size: size - 2, weight: .medium))
                .decorative()

            Text(platform.displayName)
                .font(.system(size: size - 2, weight: .semibold))
        }
        .foregroundStyle(platformForeground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(platformBackground)
        .cornerRadius(999)
        .accessibilityLabel("From \(platform.displayName)")
        .accessibilityHidden(true) // Parent provides the label in context
    }

    // MARK: - Colors

    private var platformForeground: Color {
        switch platform {
        case .youtube:   return .youtubeRed
        case .tiktok:    return .white
        case .instagram: return .instagramPink
        }
    }

    private var platformBackground: Color {
        switch platform {
        case .youtube:   return .youtubeRed.opacity(0.1)
        case .tiktok:    return .tikTokBlack.opacity(0.08)
        case .instagram: return .instagramPink.opacity(0.1)
        }
    }
}

// MARK: - Confidence Badge

/// A pill badge showing recipe extraction confidence (High / Medium / Low).
struct ConfidenceBadge: View {
    var confidence: ConfidenceLevel
    var showScore: Bool = false
    var score: Int? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidence.iconName)
                .font(.system(size: 12, weight: .medium))
                .decorative()
            Text(labelText)
                .font(.cooksMicro)
        }
        .foregroundStyle(confidence.textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(confidence.backgroundColor)
        .overlay(
            Capsule()
                .stroke(confidence.borderColor, lineWidth: 1)
        )
        .clipShape(Capsule())
        .accessibilityLabel(labelAccessibility)
    }

    private var labelText: String {
        if showScore, let score = score {
            return "\(confidence.displayName) · \(score)"
        }
        return confidence.displayName
    }

    private var labelAccessibility: String {
        if let score = score {
            return AccessibilityFormatter.confidence(confidence.displayName, score: score)
        }
        return "\(confidence.displayName) confidence"
    }
}

// MARK: - Supporting Types

extension ConfidenceLevel {
    var backgroundColor: Color {
        switch self {
        case .high:   return .confidenceHigh
        case .medium: return .confidenceMedium
        case .low:    return .confidenceLow
        }
    }

    var borderColor: Color {
        switch self {
        case .high:   return .confidenceHighBorder
        case .medium: return .confidenceMediumBorder
        case .low:    return .confidenceLowBorder
        }
    }

    var textColor: Color {
        switch self {
        case .high:   return .cooksSuccess
        case .medium: return Color(hex: "9E7D0B")
        case .low:    return .cooksDanger
        }
    }
}
