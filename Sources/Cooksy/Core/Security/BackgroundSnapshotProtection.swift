import SwiftUI
import UIKit

// MARK: - BackgroundSnapshotProtectionModifier

/// Hides sensitive app content when the app enters the background.
///
/// iOS captures a screenshot when the app enters background for the app switcher.
/// This overlay shows a privacy screen to prevent sensitive content from appearing
/// in the app switcher preview.
///
/// ## Usage
/// ```swift
/// ContentView()
///     .backgroundSnapshotProtection()
/// ```
struct BackgroundSnapshotProtectionModifier: ViewModifier {
    @State private var isBlurred = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isBlurred {
                        PrivacyOverlay()
                            .transition(.opacity)
                    }
                }
            )
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didEnterBackgroundNotification
            )) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    isBlurred = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )) { _ in
                withAnimation(.easeIn(duration: 0.2)) {
                    isBlurred = false
                }
            }
    }
}

// MARK: - PrivacyOverlay

struct PrivacyOverlay: View {
    var body: some View {
        ZStack {
            // Heavy blur effect
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brand)

                Text("Cooksy")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Tap to unlock")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Prevents sensitive content from appearing in the iOS app switcher.
    func backgroundSnapshotProtection() -> some View {
        modifier(BackgroundSnapshotProtectionModifier())
    }
}
