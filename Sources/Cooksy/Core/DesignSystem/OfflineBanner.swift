import SwiftUI

// MARK: - Offline Banner

/// A compact banner shown when the device is offline.
/// Slides in from the top with a subtle animation.
///
/// Place this above your main content, typically inside a `ZStack` with
/// `alignment: .top`, so it overlays the screen when the user loses connectivity.
///
/// ## Usage
/// ```swift
/// ZStack {
///     MyContent()
///
///     if !networkMonitor.isConnected {
///         OfflineBanner()
///             .transition(.move(edge: .top).combined(with: .opacity))
///     }
/// }
/// ```
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))
                .decorative()

            Text("No internet connection")
                .font(.cooksCallout)
                .fontWeight(.medium)

            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.cooksDanger)
        .clipShape(
            .rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 12,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No internet connection. Some features may be unavailable.")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Preview

#Preview {
    OfflineBanner()
        .padding(.horizontal)
        .background(Color.cooksBackground)
}
