import SwiftUI
import UIKit

// MARK: - Screen Protection

/// Prevents screen capture and recording of sensitive app content.
///
/// Applies a blur overlay when the screen is being captured or recorded.
/// Use on screens containing sensitive recipe data, auth tokens, or personal information.
///
/// ## Usage
/// Apply the `.screenProtection()` view modifier to any view that contains sensitive data:
/// ```
/// MySensitiveView()
///     .screenProtection()
/// ```
///
/// ## How It Works
/// Uses `UIScreen.isCaptured` to detect when the screen is being recorded or captured.
/// When capture is detected, a black overlay with an informational message is displayed
/// to prevent sensitive content from being exposed.
///
/// ## Apple Documentation
/// - ``UIScreen/isCaptured``
/// - ``UIScreen/capturedDidChangeNotification``
struct ScreenProtectionModifier: ViewModifier {

    // MARK: - State

    /// Whether the screen is currently being captured/recorded.
    @State private var isBeingCaptured = false

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isBeingCaptured {
                        Color.black
                            .ignoresSafeArea()
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                    Text("Content hidden")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text("Screen recording is active")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            )
                    }
                }
            )
            .onAppear {
                checkCaptureState()
                // Observe capture state changes
                NotificationCenter.default.addObserver(
                    forName: UIScreen.capturedDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    checkCaptureState()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(
                    self,
                    name: UIScreen.capturedDidChangeNotification,
                    object: nil
                )
            }
    }

    // MARK: - Capture State Check

    /// Updates the capture state by checking `UIScreen.main.isCaptured`.
    private func checkCaptureState() {
        isBeingCaptured = UIScreen.main.isCaptured
    }
}

// MARK: - View Extension

extension View {

    /// Adds screen capture protection to this view.
    ///
    /// When the device screen is being recorded or captured, this modifier displays
    /// a black overlay that hides all sensitive content with an informational message.
    ///
    /// Apply this to views that display sensitive data such as:
    /// - Authentication screens
    /// - Recipe detail views with personal notes
    /// - Settings with account information
    /// - Any screen displaying auth tokens or API responses
    ///
    /// ## Example
    /// ```swift
    /// ContentView()
    ///     .screenProtection()
    /// ```
    ///
    /// - Returns: A view protected against screen capture and recording.
    func screenProtection() -> some View {
        modifier(ScreenProtectionModifier())
    }
}
