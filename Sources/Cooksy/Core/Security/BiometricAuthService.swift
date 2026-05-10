import Foundation
import LocalAuthentication
import SwiftUI

// MARK: - BiometricAuthService
/// Biometric authentication service using Face ID / Touch ID.
///
/// Wraps LocalAuthentication framework with proper error handling,
/// accessibility support, and graceful fallbacks to device passcode.
@Observable
@MainActor
final class BiometricAuthService {
    static let shared = BiometricAuthService()

    private let context = LAContext()

    /// Whether the device supports biometric authentication.
    private(set) var isAvailable: Bool = false

    /// The type of biometric authentication available.
    private(set) var biometryType: LABiometryType = .none

    /// Whether biometric auth is currently being evaluated.
    private(set) var isEvaluating: Bool = false

    /// Last error that occurred during authentication.
    private(set) var lastError: String?

    private init() {
        checkAvailability()
    }

    // MARK: - Availability

    /// Checks if biometric authentication is available on this device.
    func checkAvailability() {
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometryType = context.biometryType

        if let error = error {
            print("[BiometricAuth] Availability check error: \(error.localizedDescription)")
        }
    }

    /// Human-readable name for the available biometry type.
    var biometryName: String {
        switch biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "biometric authentication"
        }
    }

    // MARK: - Authentication

    /// Authenticates the user using biometrics.
    ///
    /// - Parameter reason: A localized message explaining why authentication is needed.
    /// - Returns: `true` if authentication succeeded, `false` otherwise.
    @discardableResult
    func authenticate(reason: String) async -> Bool {
        guard isAvailable else {
            lastError = "Biometric authentication is not available on this device."
            return false
        }

        isEvaluating = true
        lastError = nil
        defer { isEvaluating = false }

        // Create a fresh context for each authentication
        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"
        ctx.localizedFallbackTitle = "Use Passcode"

        do {
            let success = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            lastError = handleLAError(error)
            return false
        } catch {
            lastError = "Authentication failed. Please try again."
            return false
        }
    }

    /// Authenticates with device passcode as fallback.
    ///
    /// Use this when biometric auth fails or is unavailable but you still
    /// need strong authentication.
    /// - Parameter reason: A localized message explaining why authentication is needed.
    /// - Returns: `true` if passcode authentication succeeded.
    @discardableResult
    func authenticateWithPasscode(reason: String) async -> Bool {
        isEvaluating = true
        lastError = nil
        defer { isEvaluating = false }

        let ctx = LAContext()
        ctx.localizedCancelTitle = "Cancel"

        do {
            return try await ctx.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch let error as LAError {
            lastError = handleLAError(error)
            return false
        } catch {
            lastError = "Authentication failed. Please try again."
            return false
        }
    }

    // MARK: - Error Handling

    private func handleLAError(_ error: LAError) -> String {
        switch error.code {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "No biometric credentials are enrolled. Please set up \(biometryName) in Settings."
        case .biometryLockout:
            return "\(biometryName) is locked out due to too many failed attempts. Please use your device passcode."
        case .userCancel:
            return "Authentication was cancelled."
        case .userFallback:
            return "Passcode entry was requested."
        case .invalidContext:
            return "Authentication context is invalid."
        case .notInteractive:
            return "Authentication requires user interaction."
        case .passcodeNotSet:
            return "No device passcode is set. Please set a passcode in Settings."
        default:
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
}
