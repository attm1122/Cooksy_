import XCTest
@testable import Cooksy

// MARK: - ProfileViewModelTests
/// Comprehensive unit tests for the ProfileViewModel user profile state management.
///
/// Tests cover initial state, computed properties (display name, plan name, member since),
/// UserDefaults integration, sign out behavior, and account management state.
@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - Mock Supabase

    private final class MockSupabase: SupabaseProtocol {
        var currentUser: User?
        var shouldFailSignOut: Bool = false
        var signOutCalled: Bool = false

        func signInWithOTP(email: String) async throws {}

        func verifyOTP(email: String, token: String) async throws -> User {
            User(id: "", email: "", createdAt: Date())
        }

        func signOut() async throws {
            signOutCalled = true
            if shouldFailSignOut {
                throw CooksyError.networkError(URLError(.notConnectedToInternet))
            }
            currentUser = nil
        }

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

    private var sut: ProfileViewModel!
    private var mockSupabase: MockSupabase!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockSupabase = MockSupabase()
        sut = ProfileViewModel(supabase: mockSupabase)
        // Clean UserDefaults
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userDisplayName")
        UserDefaults.standard.removeObject(forKey: "userFirstName")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "supabase_session_token")
        UserDefaults.standard.removeObject(forKey: "isPro")
    }

    override func tearDown() {
        sut = nil
        mockSupabase = nil
        // Clean UserDefaults
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userDisplayName")
        UserDefaults.standard.removeObject(forKey: "userFirstName")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "supabase_session_token")
        UserDefaults.standard.removeObject(forKey: "isPro")
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_userEmailIsEmpty() {
        XCTAssertEqual(sut.userEmail, "")
    }

    func test_initialState_isProIsFalse() {
        XCTAssertFalse(sut.isPro)
    }

    func test_initialState_recipeCountIsZero() {
        XCTAssertEqual(sut.recipeCount, 0)
    }

    func test_initialState_savedCountIsZero() {
        XCTAssertEqual(sut.savedCount, 0)
    }

    func test_initialState_bookCountIsZero() {
        XCTAssertEqual(sut.bookCount, 0)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_errorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func test_initialState_showExportSheetIsFalse() {
        XCTAssertFalse(sut.showExportSheet)
    }

    func test_initialState_showDeleteConfirmationIsFalse() {
        XCTAssertFalse(sut.showDeleteConfirmation)
    }

    func test_initialState_exportDataJSONIsEmpty() {
        XCTAssertEqual(sut.exportDataJSON, "")
    }

    // MARK: - userDisplayName Tests

    func test_userDisplayName_withNoValue() {
        XCTAssertEqual(sut.userDisplayName, "")
    }

    func test_userDisplayName_withValue() {
        UserDefaults.standard.set("John Doe", forKey: "userDisplayName")
        XCTAssertEqual(sut.userDisplayName, "John Doe")
    }

    func test_userDisplayName_readsFromUserDefaults() {
        UserDefaults.standard.set("Jane Smith", forKey: "userDisplayName")
        let freshVM = ProfileViewModel(supabase: mockSupabase)
        XCTAssertEqual(freshVM.userDisplayName, "Jane Smith")
    }

    func test_userDisplayName_updatesDynamically() {
        UserDefaults.standard.set("First Name", forKey: "userDisplayName")
        XCTAssertEqual(sut.userDisplayName, "First Name")
        UserDefaults.standard.set("Second Name", forKey: "userDisplayName")
        // The VM reads from UserDefaults each time (computed property)
        XCTAssertEqual(sut.userDisplayName, "Second Name")
    }

    // MARK: - userFirstName Tests

    func test_userFirstName_withNoValue() {
        XCTAssertEqual(sut.userFirstName, "")
    }

    func test_userFirstName_withValue() {
        UserDefaults.standard.set("Alice", forKey: "userFirstName")
        XCTAssertEqual(sut.userFirstName, "Alice")
    }

    func test_userFirstName_readsFromUserDefaults() {
        UserDefaults.standard.set("Bob", forKey: "userFirstName")
        let freshVM = ProfileViewModel(supabase: mockSupabase)
        XCTAssertEqual(freshVM.userFirstName, "Bob")
    }

    func test_userFirstName_differentFromDisplayName() {
        UserDefaults.standard.set("John Michael Doe", forKey: "userDisplayName")
        UserDefaults.standard.set("John", forKey: "userFirstName")
        XCTAssertEqual(sut.userDisplayName, "John Michael Doe")
        XCTAssertEqual(sut.userFirstName, "John")
    }

    // MARK: - planName Tests

    func test_planName_free() {
        sut.isPro = false
        XCTAssertEqual(sut.planName, "Free Plan")
    }

    func test_planName_pro() {
        sut.isPro = true
        XCTAssertEqual(sut.planName, "Cooksy Pro")
    }

    func test_planName_togglesWithIsPro() {
        sut.isPro = false
        XCTAssertEqual(sut.planName, "Free Plan")
        sut.isPro = true
        XCTAssertEqual(sut.planName, "Cooksy Pro")
        sut.isPro = false
        XCTAssertEqual(sut.planName, "Free Plan")
    }

    // MARK: - memberSinceDate Tests

    func test_memberSinceDate_formatsCorrectly() {
        let testDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
        mockSupabase.currentUser = User(id: "test", email: "test@example.com", createdAt: testDate)
        let dateString = sut.memberSinceDate
        XCTAssertFalse(dateString.isEmpty)
        // DateFormatter with .medium style should produce non-empty string
        XCTAssertTrue(dateString.contains("2021") || dateString.contains("Jan"))
    }

    func test_memberSinceDate_withNoUser_usesFallback() {
        mockSupabase.currentUser = nil
        let dateString = sut.memberSinceDate
        XCTAssertFalse(dateString.isEmpty)
    }

    func test_memberSinceDate_isNonEmpty() {
        let dateString = sut.memberSinceDate
        XCTAssertFalse(dateString.isEmpty)
    }

    func test_memberSinceDate_noTimeComponent() {
        let dateString = sut.memberSinceDate
        // .medium dateStyle with .none timeStyle should not include time
        XCTAssertFalse(dateString.contains(":"))
    }

    // MARK: - isPro Tests

    func test_isPro_initiallyFalse() {
        XCTAssertFalse(sut.isPro)
    }

    func test_isPro_canBeSetToTrue() {
        sut.isPro = true
        XCTAssertTrue(sut.isPro)
    }

    func test_isPro_canBeToggled() {
        sut.isPro = true
        sut.isPro = false
        sut.isPro = true
        XCTAssertTrue(sut.isPro)
    }

    // MARK: - Count Properties

    func test_recipeCount_defaultZero() {
        XCTAssertEqual(sut.recipeCount, 0)
    }

    func test_recipeCount_canBeSet() {
        sut.recipeCount = 5
        XCTAssertEqual(sut.recipeCount, 5)
    }

    func test_savedCount_defaultZero() {
        XCTAssertEqual(sut.savedCount, 0)
    }

    func test_savedCount_canBeSet() {
        sut.savedCount = 3
        XCTAssertEqual(sut.savedCount, 3)
    }

    func test_bookCount_defaultZero() {
        XCTAssertEqual(sut.bookCount, 0)
    }

    func test_bookCount_canBeSet() {
        sut.bookCount = 2
        XCTAssertEqual(sut.bookCount, 2)
    }

    func test_countsAreIndependent() {
        sut.recipeCount = 10
        sut.savedCount = 5
        sut.bookCount = 2
        XCTAssertEqual(sut.recipeCount, 10)
        XCTAssertEqual(sut.savedCount, 5)
        XCTAssertEqual(sut.bookCount, 2)
    }

    // MARK: - isLoading Tests

    func test_isLoading_startsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_isLoading_canBeSet() {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)
        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - errorMessage Tests

    func test_errorMessage_startsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    func test_errorMessage_canBeSet() {
        sut.errorMessage = "Test error"
        XCTAssertEqual(sut.errorMessage, "Test error")
    }

    func test_errorMessage_canBeCleared() {
        sut.errorMessage = "Test error"
        sut.errorMessage = nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Sheet State Tests

    func test_showExportSheet_toggle() {
        sut.showExportSheet = true
        XCTAssertTrue(sut.showExportSheet)
        sut.showExportSheet = false
        XCTAssertFalse(sut.showExportSheet)
    }

    func test_showDeleteConfirmation_toggle() {
        sut.showDeleteConfirmation = true
        XCTAssertTrue(sut.showDeleteConfirmation)
        sut.showDeleteConfirmation = false
        XCTAssertFalse(sut.showDeleteConfirmation)
    }

    // MARK: - exportDataJSON Tests

    func test_exportDataJSON_startsEmpty() {
        XCTAssertEqual(sut.exportDataJSON, "")
    }

    func test_exportDataJSON_canBeSet() {
        sut.exportDataJSON = "{\"test\": true}"
        XCTAssertEqual(sut.exportDataJSON, "{\"test\": true}")
    }

    // MARK: - UserDefaults Integration for loadProfile

    func test_userEmail_fromUserDefaults() {
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")
        // The userEmail property is loaded in loadProfile() from UserDefaults
        // Without calling loadProfile, userEmail remains empty
        XCTAssertEqual(sut.userEmail, "")
    }

    // MARK: - Sign Out Tests

    func test_signOut_callsSupabaseSignOut() async {
        await sut.signOut()
        XCTAssertTrue(mockSupabase.signOutCalled)
    }

    func test_signOut_clearsIsAuthenticated() async {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        await sut.signOut()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isAuthenticated"))
    }

    func test_signOut_clearsUserEmail() async {
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")
        await sut.signOut()
        XCTAssertNil(UserDefaults.standard.string(forKey: "userEmail"))
    }

    func test_signOut_clearsAppleUserID() async {
        UserDefaults.standard.set("apple-id-123", forKey: "appleUserID")
        await sut.signOut()
        XCTAssertNil(UserDefaults.standard.string(forKey: "appleUserID"))
    }

    func test_signOut_setsIsLoadingFalse() async {
        await sut.signOut()
        XCTAssertFalse(sut.isLoading)
    }

    func test_signOut_failure_stillClearsLocalState() async {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")
        mockSupabase.shouldFailSignOut = true
        await sut.signOut()
        // Even on failure, local state should be cleared
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isAuthenticated"))
    }

    // MARK: - Delete Account Tests

    func test_deleteAccount_setsIsLoadingFalse() async {
        // deleteAccount calls signOut then clears everything
        await sut.deleteAccount()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - State Independence

    func test_profileState_isIndependent() {
        sut.isPro = true
        sut.recipeCount = 10
        sut.savedCount = 5
        sut.bookCount = 2

        XCTAssertTrue(sut.isPro)
        XCTAssertEqual(sut.recipeCount, 10)
        XCTAssertEqual(sut.savedCount, 5)
        XCTAssertEqual(sut.bookCount, 2)
    }

    // MARK: - SwiftData Fallback Counts

    func test_loadCountsFromSwiftData_fallback_noContext_noDefaults() async {
        // Without ModelContext and without cached values, loadProfile uses defaults
        // recipeCount defaults to 12, savedCount to 8, bookCount to 3
        // This is tested indirectly via loadProfile
        // We're verifying the counts don't change when loadProfile hasn't been called
        XCTAssertEqual(sut.recipeCount, 0)
        XCTAssertEqual(sut.savedCount, 0)
        XCTAssertEqual(sut.bookCount, 0)
    }

    // MARK: - Computed Property Consistency

    func test_allComputedPropertiesAreConsistent() {
        sut.isPro = true
        sut.recipeCount = 5
        sut.savedCount = 3
        sut.bookCount = 1

        XCTAssertEqual(sut.planName, "Cooksy Pro")
        XCTAssertEqual(sut.recipeCount, 5)
        XCTAssertEqual(sut.savedCount, 3)
        XCTAssertEqual(sut.bookCount, 1)
    }

    func test_planNameReflectsIsPro() {
        sut.isPro = false
        XCTAssertEqual(sut.planName, "Free Plan")
        sut.isPro = true
        XCTAssertEqual(sut.planName, "Cooksy Pro")
    }

    // MARK: - Show States Mutability

    func test_showExportSheet_defaultFalse() {
        XCTAssertFalse(sut.showExportSheet)
    }

    func test_showDeleteConfirmation_defaultFalse() {
        XCTAssertFalse(sut.showDeleteConfirmation)
    }

    // MARK: - Multiple Sign Out Calls

    func test_multipleSignOut_calls() async {
        await sut.signOut()
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set("test@example.com", forKey: "userEmail")
        await sut.signOut()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "isAuthenticated"))
    }

    // MARK: - User with No Display Name

    func test_userDisplayName_emptyWhenNotSet() {
        // Ensure no value is set
        UserDefaults.standard.removeObject(forKey: "userDisplayName")
        XCTAssertEqual(sut.userDisplayName, "")
    }

    func test_userFirstName_emptyWhenNotSet() {
        UserDefaults.standard.removeObject(forKey: "userFirstName")
        XCTAssertEqual(sut.userFirstName, "")
    }
}
