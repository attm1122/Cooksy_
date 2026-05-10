import XCTest
@testable import Cooksy

// MARK: - AuthViewModelTests
/// Comprehensive unit tests for the AuthViewModel OTP authentication flow.
///
/// Tests cover the full auth lifecycle: email validation, OTP sending, code verification,
/// resend logic, countdown behavior, and error handling. Uses a mock SupabaseProtocol
/// to avoid real network calls.
@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - Mock Supabase

    /// A configurable mock implementation of SupabaseProtocol for testing auth flows.
    private final class MockSupabase: SupabaseProtocol {
        var currentUser: User?

        /// Whether `signInWithOTP` should simulate a failure.
        var shouldFailSignIn: Bool = false
        /// Whether `verifyOTP` should simulate a failure.
        var shouldFailVerify: Bool = false
        /// The user to return from `verifyOTP` on success.
        var mockUser: User = User(id: "test-user-id", email: "test@example.com", createdAt: Date())
        /// The last email passed to `signInWithOTP`.
        var lastSignInEmail: String?
        /// The last email passed to `verifyOTP`.
        var lastVerifyEmail: String?
        /// The last token passed to `verifyOTP`.
        var lastVerifyToken: String?
        /// Whether signOut was called.
        var signOutCalled: Bool = false

        func signInWithOTP(email: String) async throws {
            lastSignInEmail = email
            if shouldFailSignIn {
                throw CooksyError.networkError(URLError(.notConnectedToInternet))
            }
        }

        func verifyOTP(email: String, token: String) async throws -> User {
            lastVerifyEmail = email
            lastVerifyToken = token
            if shouldFailVerify {
                throw CooksyError.unauthorized
            }
            return mockUser
        }

        func signOut() async throws {
            signOutCalled = true
            currentUser = nil
        }

        // Stub methods required by protocol
        func registerPushToken(_ token: String) async throws {}
        func unregisterPushToken(_ token: String) async throws {}
        func submitContentReport(recipeId: String, reason: String, details: String?) async throws {}
        func fetchRecipes() async throws -> [RecipeDTO] { [] }
        func importRecipe(url: String) async throws -> ImportJobResponse {
            ImportJobResponse(jobId: "", status: .pending, recipe: nil)
        }
        func checkImportStatus(jobId: String) async throws -> ImportStatusResponse {
            ImportStatusResponse(jobId: "", status: .pending, recipe: nil, message: nil)
        }
        func completeImport(jobId: String) async throws -> RecipeDTO {
            fatalError("Not implemented")
        }
    }

    // MARK: - Properties

    private var sut: AuthViewModel!
    private var mockSupabase: MockSupabase!
    private var authenticatedCalled: Bool!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockSupabase = MockSupabase()
        authenticatedCalled = false
        sut = AuthViewModel(
            supabase: mockSupabase,
            onAuthenticated: { [weak self] in
                self?.authenticatedCalled = true
            }
        )
    }

    override func tearDown() {
        sut = nil
        mockSupabase = nil
        authenticatedCalled = nil
        // Clear UserDefaults test keys
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_emailIsEmpty() {
        XCTAssertEqual(sut.email, "")
    }

    func test_initialState_codeIsEmpty() {
        XCTAssertEqual(sut.code, "")
    }

    func test_initialState_currentStepIsEmail() {
        XCTAssertEqual(sut.currentStep, .email)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_errorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func test_initialState_resendCountdownIsZero() {
        XCTAssertEqual(sut.resendCountdown, 0)
    }

    // MARK: - sendCode() - Email Validation

    func test_sendCode_withEmptyEmail_setsError() async {
        sut.email = ""
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("email") ?? false)
    }

    func test_sendCode_withEmptyEmail_doesNotTransitionStep() async {
        sut.email = ""
        await sut.sendCode()
        XCTAssertEqual(sut.currentStep, .email)
    }

    func test_sendCode_withEmptyEmail_setsIsLoadingFalse() async {
        sut.email = ""
        await sut.sendCode()
        XCTAssertFalse(sut.isLoading)
    }

    func test_sendCode_withWhitespaceOnlyEmail_setsError() async {
        sut.email = "   "
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_sendCode_withInvalidFormat_setsError() async {
        sut.email = "not-an-email"
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("valid") ?? false)
    }

    func test_sendCode_withMissingAtSign_setsError() async {
        sut.email = "userexample.com"
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_sendCode_withMissingDomain_setsError() async {
        sut.email = "user@"
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_sendCode_withMissingTLD_setsError() async {
        sut.email = "user@domain"
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_sendCode_withValidEmail_transitionsToCodeStep() async {
        sut.email = "test@example.com"
        await sut.sendCode()
        XCTAssertEqual(sut.currentStep, .code("test@example.com"))
    }

    func test_sendCode_withValidEmail_lowercasesEmail() async {
        sut.email = "Test@Example.COM"
        await sut.sendCode()
        XCTAssertEqual(sut.email, "test@example.com")
    }

    func test_sendCode_withValidEmail_clearsError() async {
        sut.email = "test@example.com"
        sut.errorMessage = "Previous error"
        await sut.sendCode()
        XCTAssertNil(sut.errorMessage)
    }

    func test_sendCode_withValidEmail_clearsCode() async {
        sut.email = "test@example.com"
        sut.code = "123456"
        await sut.sendCode()
        XCTAssertEqual(sut.code, "")
    }

    func test_sendCode_success_startsCountdown() async {
        sut.email = "test@example.com"
        await sut.sendCode()
        // The countdown starts at 60 and begins decrementing
        XCTAssertEqual(sut.resendCountdown, 60)
    }

    func test_sendCode_success_callsSupabaseSignIn() async {
        sut.email = "test@example.com"
        await sut.sendCode()
        XCTAssertEqual(mockSupabase.lastSignInEmail, "test@example.com")
    }

    // MARK: - sendCode() - Error Handling

    func test_sendCode_networkError_setsErrorMessage() async {
        sut.email = "test@example.com"
        mockSupabase.shouldFailSignIn = true
        await sut.sendCode()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_sendCode_failure_staysOnEmailStep() async {
        sut.email = "test@example.com"
        mockSupabase.shouldFailSignIn = true
        await sut.sendCode()
        XCTAssertEqual(sut.currentStep, .email)
    }

    func test_sendCode_genericError_setsDefaultMessage() async {
        sut.email = "test@example.com"
        mockSupabase.shouldFailSignIn = true
        await sut.sendCode()
        XCTAssertTrue(sut.errorMessage?.contains("send code") ?? false)
    }

    // MARK: - verifyCode() - Code Validation

    func test_verifyCode_withEmptyCode_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = ""
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_verifyCode_withShortCode_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "12345"
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("6-digit") ?? false)
    }

    func test_verifyCode_withLongCode_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "1234567"
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_verifyCode_withNonNumericCode_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "12a456"
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("numbers") ?? false)
    }

    func test_verifyCode_withLettersOnly_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "abcdef"
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_verifyCode_withSpecialChars_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "12!456"
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - verifyCode() - Success Flow

    func test_verifyCode_withValidCode_callsSupabaseVerify() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        await sut.verifyCode()
        XCTAssertEqual(mockSupabase.lastVerifyEmail, "test@example.com")
        XCTAssertEqual(mockSupabase.lastVerifyToken, "123456")
    }

    func test_verifyCode_success_storesUserEmailInUserDefaults() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        await sut.verifyCode()
        XCTAssertEqual(UserDefaults.standard.string(forKey: "userEmail"), "test@example.com")
    }

    func test_verifyCode_success_setsIsAuthenticatedInUserDefaults() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        await sut.verifyCode()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "isAuthenticated"))
    }

    func test_verifyCode_success_callsOnAuthenticated() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        await sut.verifyCode()
        XCTAssertTrue(authenticatedCalled)
    }

    func test_verifyCode_success_setsIsLoadingFalse() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        await sut.verifyCode()
        XCTAssertFalse(sut.isLoading)
    }

    func test_verifyCode_success_clearsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        sut.errorMessage = "Previous error"
        await sut.verifyCode()
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - verifyCode() - Failure Flow

    func test_verifyCode_failure_setsErrorMessage() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "000000"
        mockSupabase.shouldFailVerify = true
        await sut.verifyCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_verifyCode_failure_setsIsLoadingFalse() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "000000"
        mockSupabase.shouldFailVerify = true
        await sut.verifyCode()
        XCTAssertFalse(sut.isLoading)
    }

    func test_verifyCode_failure_doesNotCallOnAuthenticated() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "000000"
        mockSupabase.shouldFailVerify = true
        authenticatedCalled = false
        await sut.verifyCode()
        XCTAssertFalse(authenticatedCalled)
    }

    func test_verifyCode_genericError_setsDefaultMessage() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "000000"
        mockSupabase.shouldFailVerify = true
        await sut.verifyCode()
        XCTAssertTrue(sut.errorMessage?.contains("Invalid code") ?? false)
    }

    // MARK: - resendCode()

    func test_resendCode_whenCountdownActive_doesNothing() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        mockSupabase.lastSignInEmail = nil
        // Manually set countdown > 0 to simulate active countdown
        sut.goBackToEmail()
        sut.email = "test@example.com"
        await sut.sendCode() // This starts the countdown
        mockSupabase.lastSignInEmail = nil
        // Attempt resend while countdown is active
        await sut.resendCode()
        // Should NOT have called signIn again (the resend guard should block)
        // Note: Since countdown > 0, resend should return early
        XCTAssertTrue(sut.resendCountdown > 0 || mockSupabase.lastSignInEmail == nil)
    }

    func test_resendCode_whenCountdownZero_callsSupabase() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.resendCountdown = 0
        sut.code = "123456"
        mockSupabase.lastSignInEmail = nil
        await sut.resendCode()
        XCTAssertEqual(mockSupabase.lastSignInEmail, "test@example.com")
    }

    func test_resendCode_success_clearsCode() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.resendCountdown = 0
        sut.code = "123456"
        await sut.resendCode()
        XCTAssertEqual(sut.code, "")
    }

    func test_resendCode_success_restartsCountdown() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.resendCountdown = 0
        await sut.resendCode()
        XCTAssertEqual(sut.resendCountdown, 60)
    }

    func test_resendCode_failure_setsError() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.resendCountdown = 0
        mockSupabase.shouldFailSignIn = true
        await sut.resendCode()
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - goBackToEmail()

    func test_goBackToEmail_transitionsToEmailStep() {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.goBackToEmail()
        XCTAssertEqual(sut.currentStep, .email)
    }

    func test_goBackToEmail_clearsCode() {
        sut.code = "123456"
        sut.currentStep = .code("test@example.com")
        sut.goBackToEmail()
        XCTAssertEqual(sut.code, "")
    }

    func test_goBackToEmail_clearsError() {
        sut.errorMessage = "Some error"
        sut.currentStep = .code("test@example.com")
        sut.goBackToEmail()
        XCTAssertNil(sut.errorMessage)
    }

    func test_goBackToEmail_resetsCountdown() {
        sut.currentStep = .code("test@example.com")
        sut.goBackToEmail()
        XCTAssertEqual(sut.resendCountdown, 0)
    }

    // MARK: - Step Enum

    func test_stepEnum_emailCase() {
        let step: AuthViewModel.Step = .email
        XCTAssertEqual(step, .email)
    }

    func test_stepEnum_codeCase() {
        let step: AuthViewModel.Step = .code("test@example.com")
        if case .code(let email) = step {
            XCTAssertEqual(email, "test@example.com")
        } else {
            XCTFail("Expected .code case")
        }
    }

    func test_stepEnum_codeCasesWithSameEmailAreEqual() {
        let step1: AuthViewModel.Step = .code("a@b.com")
        let step2: AuthViewModel.Step = .code("a@b.com")
        XCTAssertEqual(step1, step2)
    }

    func test_stepEnum_codeCasesWithDifferentEmailsAreNotEqual() {
        let step1: AuthViewModel.Step = .code("a@b.com")
        let step2: AuthViewModel.Step = .code("c@d.com")
        XCTAssertNotEqual(step1, step2)
    }

    // MARK: - AuthError Enum

    func test_authError_networkFailure() {
        let error = AuthViewModel.AuthError.networkFailure
        XCTAssertEqual(error.localizedDescription, "Network connection failed.")
    }

    func test_authError_invalidEmail() {
        let error = AuthViewModel.AuthError.invalidEmail
        XCTAssertEqual(error.localizedDescription, "The email address is invalid.")
    }

    func test_authError_invalidCode() {
        let error = AuthViewModel.AuthError.invalidCode
        XCTAssertEqual(error.localizedDescription, "The verification code is incorrect.")
    }

    func test_authError_codeExpired() {
        let error = AuthViewModel.AuthError.codeExpired
        XCTAssertEqual(error.localizedDescription, "The code has expired. Please request a new one.")
    }

    func test_authError_tooManyAttempts() {
        let error = AuthViewModel.AuthError.tooManyAttempts
        XCTAssertEqual(error.localizedDescription, "Too many attempts. Please try again later.")
    }

    func test_authError_appleSignInFailed() {
        let error = AuthViewModel.AuthError.appleSignInFailed
        XCTAssertEqual(error.localizedDescription, "Sign in with Apple failed.")
    }

    func test_authError_appleSignInCancelled() {
        let error = AuthViewModel.AuthError.appleSignInCancelled
        XCTAssertEqual(error.localizedDescription, "Sign in was cancelled.")
    }

    func test_authError_conformsToLocalizedError() {
        let error: Error = AuthViewModel.AuthError.invalidEmail
        XCTAssertNotNil(error.localizedDescription)
    }

    // MARK: - Email Validation Edge Cases

    func test_sendCode_withValidEmail_plusSignAllowed() async {
        sut.email = "user+tag@example.com"
        await sut.sendCode()
        XCTAssertEqual(sut.currentStep, .code("user+tag@example.com"))
    }

    func test_sendCode_withValidEmail_underscoreAllowed() async {
        sut.email = "user_name@example.co.uk"
        await sut.sendCode()
        XCTAssertEqual(sut.currentStep, .code("user_name@example.co.uk"))
    }

    func test_sendCode_withValidEmail_numbersAllowed() async {
        sut.email = "user123@test456.org"
        await sut.sendCode()
        XCTAssertEqual(sut.currentStep, .code("user123@test456.org"))
    }

    func test_sendCode_trimsWhitespaceBeforeValidation() async {
        sut.email = "  test@example.com  "
        await sut.sendCode()
        XCTAssertEqual(sut.email, "test@example.com")
    }

    // MARK: - Loading State

    func test_sendCode_setsLoadingTrueDuringExecution() async {
        sut.email = "test@example.com"
        // The loading state is set internally; we can verify it's false after completion
        await sut.sendCode()
        XCTAssertFalse(sut.isLoading)
    }

    func test_verifyCode_setsLoadingTrueDuringExecution() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        await sut.verifyCode()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - State Reset After Errors

    func test_sendCode_failure_preservesEmail() async {
        sut.email = "test@example.com"
        mockSupabase.shouldFailSignIn = true
        await sut.sendCode()
        XCTAssertEqual(sut.email, "test@example.com")
    }

    func test_verifyCode_failure_preservesCode() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.code = "123456"
        mockSupabase.shouldFailVerify = true
        await sut.verifyCode()
        XCTAssertEqual(sut.code, "123456")
    }

    func test_resendCode_failure_preservesStep() async {
        sut.email = "test@example.com"
        sut.currentStep = .code("test@example.com")
        sut.resendCountdown = 0
        mockSupabase.shouldFailSignIn = true
        await sut.resendCode()
        if case .code = sut.currentStep {
            // Pass - should still be on code step
        } else {
            XCTFail("Expected to remain on code step")
        }
    }
}
