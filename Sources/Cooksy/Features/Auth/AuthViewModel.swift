import SwiftUI
import AuthenticationServices

// MARK: - Auth ViewModel
/// Manages the OTP authentication flow: email → code → authenticated session.
///
/// ## Dependencies
/// - `SupabaseProtocol` — for real `signInWithOTP` and `verifyOTP` calls.
///
/// ## Session Storage
/// The auth token is stored in `UserDefaults` for rapid prototyping.
/// **For production, migrate to the Keychain using a library like KeychainAccess.**
///
/// ## Resend Countdown
/// A cancellable `Task` manages the 60-second resend cooldown. The task is
/// cancelled when the user navigates back to the email step or when the
/// view model is deinitialized.
@MainActor
@Observable
final class AuthViewModel {

    // MARK: - Types

    /// Represents the current step in the authentication flow.
    enum Step: Hashable {
        /// User enters their email address.
        case email
        /// User enters the 6-digit OTP code (associated value = email).
        case code(String)
    }

    // MARK: - Dependencies

    let supabase: any SupabaseProtocol
    private let onAuthenticated: () -> Void

    // MARK: - State

    /// User's email address.
    var email: String = ""

    /// 6-digit verification code entered by user.
    var code: String = ""

    /// Current step in the auth flow.
    private(set) var currentStep: Step = .email

    /// Loading state for async operations.
    private(set) var isLoading: Bool = false

    /// Error message to display to the user.
    private(set) var errorMessage: String?

    /// Countdown timer for resend code (in seconds).
    private(set) var resendCountdown: Int = 0

    // MARK: - Private Properties

    /// The active countdown task. Stored so it can be cancelled on deinit or navigation.
    private var countdownTask: Task<Void, Never>?

    /// Stored Apple ID credential for Sign in with Apple.
    private var appleIDCredential: ASAuthorizationAppleIDCredential?

    // MARK: - Initialization

    /// Creates a new auth view model.
    /// - Parameters:
    ///   - supabase: The Supabase service for auth operations.
    ///   - onAuthenticated: Closure called when authentication succeeds.
    init(
        supabase: any SupabaseProtocol,
        onAuthenticated: @escaping () -> Void
    ) {
        self.supabase = supabase
        self.onAuthenticated = onAuthenticated
    }

    deinit {
        countdownTask?.cancel()
    }

    // MARK: - Public Methods

    /// Validates email and sends an OTP via the Supabase Auth API.
    /// On success, transitions to the code entry step.
    func sendCode() async {
        guard validateEmail() else { return }

        setLoading(true)
        clearError()

        do {
            try await supabase.signInWithOTP(email: email)

            // Transition to code entry step
            currentStep = .code(email)
            code = ""
            startCountdown()
        } catch let err as CooksyError {
            showError(err.localizedDescription)
        } catch {
            showError("Failed to send code. Please try again.")
        }

        setLoading(false)
    }

    /// Verifies the 6-digit code against the Supabase Auth API.
    /// On success, persists session state and calls `onAuthenticated`.
    func verifyCode() async {
        guard validateCode() else { return }

        setLoading(true)
        clearError()

        do {
            let user = try await supabase.verifyOTP(email: email, token: code)

            // Store session token in UserDefaults (see note above about Keychain migration)
            UserDefaults.standard.set(user.email, forKey: "userEmail")
            UserDefaults.standard.set(true, forKey: "isAuthenticated")

            countdownTask?.cancel()
            onAuthenticated()
        } catch let err as CooksyError {
            showError(err.localizedDescription)
        } catch {
            showError("Invalid code. Please check and try again.")
        }

        setLoading(false)
    }

    /// Resends the verification code (only allowed when countdown reaches 0).
    func resendCode() async {
        guard resendCountdown == 0 else { return }

        setLoading(true)
        clearError()

        do {
            try await supabase.signInWithOTP(email: email)
            code = ""
            startCountdown()
        } catch let err as CooksyError {
            showError(err.localizedDescription)
        } catch {
            showError("Failed to resend code. Please try again.")
        }

        setLoading(false)
    }

    /// Returns to the email entry step, cancelling any active countdown.
    func goBackToEmail() {
        currentStep = .email
        code = ""
        clearError()
        countdownTask?.cancel()
        resendCountdown = 0
    }

    // MARK: - Countdown

    /// Starts a 60-second resend countdown timer.
    /// Cancels any existing countdown first to prevent overlapping tasks.
    private func startCountdown() {
        countdownTask?.cancel()
        resendCountdown = 60

        countdownTask = Task { @MainActor in
            while resendCountdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                resendCountdown -= 1
            }
        }
    }

    // MARK: - Validation

    /// Validates the email format using a regex check.
    private func validateEmail() -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        email = trimmed

        if trimmed.isEmpty {
            showError("Please enter your email address.")
            return false
        }

        if !Validators.isValidEmail(trimmed) {
            showError("Please enter a valid email address.")
            return false
        }

        return true
    }

    /// Validates the 6-digit code format.
    private func validateCode() -> Bool {
        if code.count != 6 {
            showError("Please enter the complete 6-digit code.")
            return false
        }

        let digitsOnly = code.allSatisfy { $0.isNumber }
        if !digitsOnly {
            showError("The code should only contain numbers.")
            return false
        }

        return true
    }

    // MARK: - Helpers

    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    private func showError(_ message: String) {
        errorMessage = message
    }

    private func clearError() {
        errorMessage = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthViewModel: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            showError("Invalid Apple credential. Please try again.")
            return
        }

        self.appleIDCredential = credential

        // Extract user info from Apple credential
        let userID = credential.user
        let email = credential.email
        let fullName = credential.fullName

        // Store the Apple user ID for future sign-ins
        UserDefaults.standard.set(userID, forKey: "appleUserID")
        if let email = email {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            UserDefaults.standard.set("\(givenName) \(familyName)", forKey: "userDisplayName")
            UserDefaults.standard.set(givenName, forKey: "userFirstName")
        }

        // In a full implementation, you would:
        // 1. Send the identity token to your Supabase backend
        // 2. Create/link the user account server-side
        // 3. Receive a session token and store it

        // For now, mark the user as authenticated
        UserDefaults.standard.set(true, forKey: "isAuthenticated")

        // Clear any OTP-related state
        self.email = email ?? UserDefaults.standard.string(forKey: "userEmail") ?? ""

        onAuthenticated()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                // User cancelled - don't show error
                break
            case .invalidResponse:
                showError("Invalid response from Apple. Please try again.")
            case .notHandled:
                showError("Request not handled. Please try again.")
            case .failed:
                showError("Sign in failed. Please try again.")
            @unknown default:
                showError("An unknown error occurred. Please try again.")
            }
        } else {
            showError("Sign in failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window for presenting the Apple Sign In sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Errors

extension AuthViewModel {

    enum AuthError: Error, LocalizedError {
        case networkFailure
        case invalidEmail
        case invalidCode
        case codeExpired
        case tooManyAttempts
        case appleSignInFailed
        case appleSignInCancelled

        var errorDescription: String? {
            switch self {
            case .networkFailure: return "Network connection failed."
            case .invalidEmail: return "The email address is invalid."
            case .invalidCode: return "The verification code is incorrect."
            case .codeExpired: return "The code has expired. Please request a new one."
            case .tooManyAttempts: return "Too many attempts. Please try again later."
            case .appleSignInFailed: return "Sign in with Apple failed."
            case .appleSignInCancelled: return "Sign in was cancelled."
            }
        }
    }
}
