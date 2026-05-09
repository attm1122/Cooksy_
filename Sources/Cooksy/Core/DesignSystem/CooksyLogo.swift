import SwiftUI

// MARK: - Cooksy Logo View

/// A Canvas-rendered hourglass logo used for app branding.
/// Scales to any size while maintaining crisp edges.
///
/// By default, this logo is decorative. Use `.accessibilityLabel()` on the parent
/// or the accessible variants (`CooksyWordmark`, `CooksyInlineLogo`) for contexts
/// where the logo should be announced by VoiceOver.
struct CooksyLogo: View {
    var color: Color = .brand
    var size: CGFloat = 60

    /// The hourglass path data — a single SVG path rendered via SwiftUI Canvas.
    private let hourglassPath = Path { path in
        // Top bulb
        path.move(to: CGPoint(x: 50, y: 10))
        path.addCurve(
            to: CGPoint(x: 50, y: 50),
            control1: CGPoint(x: 80, y: 10),
            control2: CGPoint(x: 80, y: 40)
        )
        path.addCurve(
            to: CGPoint(x: 50, y: 50),
            control1: CGPoint(x: 20, y: 40),
            control2: CGPoint(x: 20, y: 10)
        )
        path.closeSubpath()

        // Bottom bulb
        path.move(to: CGPoint(x: 50, y: 50))
        path.addCurve(
            to: CGPoint(x: 50, y: 90),
            control1: CGPoint(x: 20, y: 50),
            control2: CGPoint(x: 20, y: 90)
        )
        path.addCurve(
            to: CGPoint(x: 50, y: 90),
            control1: CGPoint(x: 80, y: 90),
            control2: CGPoint(x: 80, y: 50)
        )
        path.closeSubpath()

        // Center pinch line
        path.move(to: CGPoint(x: 44, y: 50))
        path.addLine(to: CGPoint(x: 56, y: 50))
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scaleX = canvasSize.width / 100
            let scaleY = canvasSize.height / 100
            let scale = min(scaleX, scaleY)
            let offsetX = (canvasSize.width - 100 * scale) / 2
            let offsetY = (canvasSize.height - 100 * scale) / 2

            var transform = CGAffineTransform(translationX: offsetX, y: offsetY)
            transform = transform.scaledBy(x: scale, y: scale)

            let transformedPath = hourglassPath.applying(transform)
            context.fill(transformedPath, with: .color(color))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true) // Decorative by default - parent provides label
    }
}

// MARK: - Logo Variants

/// The full Cooksy wordmark with logo icon + text.
/// Fully accessible with VoiceOver label.
struct CooksyWordmark: View {
    var iconColor: Color = .brand
    var textColor: Color = .ink
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: size * 0.25) {
            CooksyLogo(color: iconColor, size: size)
            Text("Cooksy")
                .font(.system(size: size * 0.9, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .scalableText(minScale: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cooksy")
    }
}

/// Small inline logo for nav bars and compact headers.
/// Fully accessible with VoiceOver label.
struct CooksyInlineLogo: View {
    var color: Color = .brand

    var body: some View {
        HStack(spacing: 6) {
            CooksyLogo(color: color, size: 24)
            Text("Cooksy")
                .font(.cooksH3)
                .foregroundStyle(.ink)
                .scalableText()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cooksy")
    }
}
