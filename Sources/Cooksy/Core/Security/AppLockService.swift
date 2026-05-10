import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - AppLockService

/// Automatic app lock that protects sensitive content after inactivity.
///
/// Monitors app lifecycle and scene phase transitions. When the app enters
/// the background, a timer starts. If the app returns after the timeout,
/// a biometric authentication overlay blocks access until the user
/// authenticates with Face ID, Touch ID, or device passcode.
///
/// ## Usage
/// Wrap your app's root view with `.appLock()`:
/// ```swift
/// ContentView()
///     .appLock(timeout: 300) // 5 minutes
/// ```
@Observable
@MainActor
final class AppLockService {
    static let shared = AppLockService()

    /// Whether the app is currently locked.
    private(set) var isLocked = false

    /// Whether biometric auth is available on this device.
    private(set) var isBiometricAvailable = false

    /// The timestamp when the app entered background.
    private var backgroundTimestamp: Date?

    /// The inactivity timeout in seconds (default: 5 minutes).
    let timeout: TimeInterval

    /// The biometric auth service for unlock.
    private let biometricService = BiometricAuthService.shared

    init(timeout: TimeInterval = 300) {
        self.timeout = timeout
        self.isBiometricAvailable = biometricService.isAvailable

        // Listen for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    /// Manually locks the app (e.g., user taps a lock button).
    func lock() {
        isLocked = true
        backgroundTimestamp = nil // Force auth on next foreground
    }

    /// Attempts to unlock the app using biometric authentication.
    func unlock() async {
        let authenticated = await biometricService.authenticate(
            reason: "Unlock Cooksy to access your recipes."
        )
        if authenticated {
            isLocked = false
            backgroundTimestamp = nil
        }
    }

    /// Unlocks without auth (use only when authenticated by other means).
    func forceUnlock() {
        isLocked = false
        backgroundTimestamp = nil
    }

    // MARK: - Private

    @objc private func appDidEnterBackground() {
        // Only record timestamp if not already locked
        if !isLocked {
            backgroundTimestamp = Date()
        }
    }

    @objc private func appWillEnterForeground() {
        guard !isLocked else { return } // Already locked, stay locked

        if let timestamp = backgroundTimestamp {
            let elapsed = Date().timeIntervalSince(timestamp)
            if elapsed >= timeout {
                isLocked = true
            }
            backgroundTimestamp = nil
        }
    }
}

// MARK: - SwiftUI View Modifier

struct AppLockModifier: ViewModifier {
    @State private var service: AppLockService
    @State private var showUnlockOverlay = false

    init(timeout: TimeInterval) {
        self.service = AppLockService(timeout: timeout)
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if service.isLocked {
                        AppLockOverlay(service: service)
                            .transition(.opacity)
                    }
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                showUnlockOverlay = service.isLocked
            }
    }
}

// MARK: - AppLockOverlay

struct AppLockOverlay: View {
    let service: AppLockService
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.8))

                Text("Cooksy is Locked")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text("Authenticate to continue")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))

                Button {
                    isAuthenticating = true
                    Task {
                        await service.unlock()
                        isAuthenticating = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: biometricService.biometryType == .faceID ? "faceid" : "touchid")
                        Text("Unlock with \(biometricService.biometryName)")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isAuthenticating)

                if isAuthenticating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Auto-trigger unlock when overlay appears
            Task {
                await service.unlock()
            }
        }
    }

    private var biometricService: BiometricAuthService {
        BiometricAuthService.shared
    }
}

// MARK: - View Extension

extension View {
    /// Adds automatic app lock after a period of inactivity.
    /// - Parameter timeout: Seconds of background time before lock (default: 300 = 5 min)
    func appLock(timeout: TimeInterval = 300) -> some View {
        modifier(AppLockModifier(timeout: timeout))
    }
}
