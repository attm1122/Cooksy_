import XCTest
@testable import Cooksy

// MARK: - CooksyError Tests
/// Comprehensive unit tests for the CooksyError enum.
/// Covers every error case, localizedDescription, errorUserInfo, Equatable conformance,
/// and edge cases including empty messages, long messages, and special characters.
final class CooksyErrorTests: XCTestCase {

    // MARK: - Error Case Existence Tests

    func testInvalidURLErrorExists() {
        let error = CooksyError.invalidURL
        XCTAssertNotNil(error)
    }

    func testUnsupportedPlatformErrorExists() {
        let error = CooksyError.unsupportedPlatform
        XCTAssertNotNil(error)
    }

    func testNetworkErrorExists() {
        let underlying = NSError(domain: "test", code: 0)
        let error = CooksyError.networkError(underlying)
        XCTAssertNotNil(error)
    }

    func testServerErrorExists() {
        let error = CooksyError.serverError(statusCode: 500, message: "Server down")
        XCTAssertNotNil(error)
    }

    func testUnauthorizedErrorExists() {
        let error = CooksyError.unauthorized
        XCTAssertNotNil(error)
    }

    func testRecipeNotFoundErrorExists() {
        let error = CooksyError.recipeNotFound
        XCTAssertNotNil(error)
    }

    func testImportFailedErrorExists() {
        let error = CooksyError.importFailed("Import failed")
        XCTAssertNotNil(error)
    }

    func testSubscriptionErrorExists() {
        let error = CooksyError.subscriptionError("Payment declined")
        XCTAssertNotNil(error)
    }

    func testValidationErrorExists() {
        let error = CooksyError.validationError("Invalid input")
        XCTAssertNotNil(error)
    }

    func testTranscriptionUnavailableErrorExists() {
        let error = CooksyError.transcriptionUnavailable("No audio")
        XCTAssertNotNil(error)
    }

    func testUnknownErrorExists() {
        let error = CooksyError.unknown
        XCTAssertNotNil(error)
    }

    // MARK: - localizedDescription Tests

    func testInvalidURLLocalizedDescription() {
        let error = CooksyError.invalidURL
        XCTAssertEqual(error.localizedDescription, "Please enter a valid URL")
    }

    func testUnsupportedPlatformLocalizedDescription() {
        let error = CooksyError.unsupportedPlatform
        XCTAssertEqual(error.localizedDescription, "Only YouTube, TikTok, and Instagram links are supported")
    }

    func testNetworkErrorLocalizedDescription() {
        let underlying = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        let error = CooksyError.networkError(underlying)
        XCTAssertTrue(error.localizedDescription.contains("Network error:"))
        XCTAssertTrue(error.localizedDescription.contains("offline"))
    }

    func testServerErrorLocalizedDescription() {
        let error = CooksyError.serverError(statusCode: 500, message: "Internal Server Error")
        XCTAssertEqual(error.localizedDescription, "Internal Server Error")
    }

    func testServerErrorReturnsMessageOnly() {
        let error = CooksyError.serverError(statusCode: 404, message: "Not Found")
        XCTAssertEqual(error.localizedDescription, "Not Found")
    }

    func testUnauthorizedLocalizedDescription() {
        let error = CooksyError.unauthorized
        XCTAssertEqual(error.localizedDescription, "Please sign in to continue")
    }

    func testRecipeNotFoundLocalizedDescription() {
        let error = CooksyError.recipeNotFound
        XCTAssertEqual(error.localizedDescription, "Recipe not found")
    }

    func testImportFailedLocalizedDescription() {
        let error = CooksyError.importFailed("Network timeout")
        XCTAssertEqual(error.localizedDescription, "Network timeout")
    }

    func testSubscriptionErrorLocalizedDescription() {
        let error = CooksyError.subscriptionError("Billing issue")
        XCTAssertEqual(error.localizedDescription, "Billing issue")
    }

    func testValidationErrorLocalizedDescription() {
        let error = CooksyError.validationError("Email is required")
        XCTAssertEqual(error.localizedDescription, "Email is required")
    }

    func testTranscriptionUnavailableLocalizedDescription() {
        let error = CooksyError.transcriptionUnavailable("No speech detected")
        XCTAssertEqual(error.localizedDescription, "No speech detected")
    }

    func testUnknownLocalizedDescription() {
        let error = CooksyError.unknown
        XCTAssertEqual(error.localizedDescription, "Something went wrong")
    }

    // MARK: - errorUserInfo Tests (via LocalizedError)

    func testErrorUserInfoContainsDescription() {
        let error = CooksyError.invalidURL as Error
        let userInfo = (error as NSError).userInfo
        XCTAssertNotNil(userInfo)
    }

    func testInvalidURLErrorUserInfo() {
        let nsError = CooksyError.invalidURL as NSError
        XCTAssertEqual(nsError.domain, "Cooksy.CooksyError")
        XCTAssertEqual(nsError.localizedDescription, "Please enter a valid URL")
    }

    func testRecipeNotFoundErrorUserInfo() {
        let nsError = CooksyError.recipeNotFound as NSError
        XCTAssertEqual(nsError.localizedDescription, "Recipe not found")
    }

    // MARK: - Equatable Conformance Tests

    func testSameSimpleErrorsAreEqual() {
        let a = CooksyError.invalidURL
        let b = CooksyError.invalidURL
        XCTAssertEqual(a, b)
    }

    func testSameRecipeNotFoundAreEqual() {
        let a = CooksyError.recipeNotFound
        let b = CooksyError.recipeNotFound
        XCTAssertEqual(a, b)
    }

    func testSameUnauthorizedAreEqual() {
        let a = CooksyError.unauthorized
        let b = CooksyError.unauthorized
        XCTAssertEqual(a, b)
    }

    func testSameUnknownAreEqual() {
        let a = CooksyError.unknown
        let b = CooksyError.unknown
        XCTAssertEqual(a, b)
    }

    func testDifferentSimpleErrorsAreNotEqual() {
        let a = CooksyError.invalidURL
        let b = CooksyError.unsupportedPlatform
        XCTAssertNotEqual(a, b)
    }

    func testInvalidURLNotEqualToUnauthorized() {
        let a = CooksyError.invalidURL
        let b = CooksyError.unauthorized
        XCTAssertNotEqual(a, b)
    }

    func testRecipeNotFoundNotEqualToUnknown() {
        let a = CooksyError.recipeNotFound
        let b = CooksyError.unknown
        XCTAssertNotEqual(a, b)
    }

    func testSameImportFailedMessagesAreEqual() {
        let a = CooksyError.importFailed("timeout")
        let b = CooksyError.importFailed("timeout")
        XCTAssertEqual(a, b)
    }

    func testDifferentImportFailedMessagesAreNotEqual() {
        let a = CooksyError.importFailed("timeout")
        let b = CooksyError.importFailed("network")
        XCTAssertNotEqual(a, b)
    }

    func testSameServerErrorAreEqual() {
        let a = CooksyError.serverError(statusCode: 500, message: "Error")
        let b = CooksyError.serverError(statusCode: 500, message: "Error")
        XCTAssertEqual(a, b)
    }

    func testDifferentStatusCodesAreNotEqual() {
        let a = CooksyError.serverError(statusCode: 500, message: "Error")
        let b = CooksyError.serverError(statusCode: 404, message: "Error")
        XCTAssertNotEqual(a, b)
    }

    func testDifferentServerMessagesAreNotEqual() {
        let a = CooksyError.serverError(statusCode: 500, message: "Error A")
        let b = CooksyError.serverError(statusCode: 500, message: "Error B")
        XCTAssertNotEqual(a, b)
    }

    func testSameSubscriptionErrorAreEqual() {
        let a = CooksyError.subscriptionError("billing")
        let b = CooksyError.subscriptionError("billing")
        XCTAssertEqual(a, b)
    }

    func testDifferentSubscriptionErrorAreNotEqual() {
        let a = CooksyError.subscriptionError("billing")
        let b = CooksyError.subscriptionError("expired")
        XCTAssertNotEqual(a, b)
    }

    func testSameValidationErrorAreEqual() {
        let a = CooksyError.validationError("invalid")
        let b = CooksyError.validationError("invalid")
        XCTAssertEqual(a, b)
    }

    func testSameTranscriptionUnavailableAreEqual() {
        let a = CooksyError.transcriptionUnavailable("no audio")
        let b = CooksyError.transcriptionUnavailable("no audio")
        XCTAssertEqual(a, b)
    }

    // MARK: - Network Error Equatable Tests

    func testNetworkErrorWithSameUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1)
        let a = CooksyError.networkError(underlying)
        let b = CooksyError.networkError(underlying)
        XCTAssertEqual(a, b)
    }

    func testNetworkErrorWithDifferentUnderlyingErrors() {
        let errA = NSError(domain: "test", code: 1)
        let errB = NSError(domain: "test", code: 2)
        let a = CooksyError.networkError(errA)
        let b = CooksyError.networkError(errB)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Edge Case Tests

    func testImportFailedWithEmptyMessage() {
        let error = CooksyError.importFailed("")
        XCTAssertEqual(error.localizedDescription, "")
    }

    func testImportFailedWithLongMessage() {
        let longMessage = String(repeating: "a", count: 10000)
        let error = CooksyError.importFailed(longMessage)
        XCTAssertEqual(error.localizedDescription, longMessage)
    }

    func testImportFailedWithSpecialCharacters() {
        let message = "Error: failed with code \n\t\\/?!@#$%^&*()"
        let error = CooksyError.importFailed(message)
        XCTAssertEqual(error.localizedDescription, message)
    }

    func testImportFailedWithUnicode() {
        let message = "Import failed: \u{1F370} \u{4E2D}\u{6587} \u{041F}\u{0440}\u{0438}\u{0432}\u{0435}\u{0442}"
        let error = CooksyError.importFailed(message)
        XCTAssertEqual(error.localizedDescription, message)
    }

    func testServerErrorWithEmptyMessage() {
        let error = CooksyError.serverError(statusCode: 500, message: "")
        XCTAssertEqual(error.localizedDescription, "")
    }

    func testServerErrorWithNegativeStatusCode() {
        let error = CooksyError.serverError(statusCode: -1, message: "Invalid")
        XCTAssertEqual(error.localizedDescription, "Invalid")
    }

    func testServerErrorWithLargeStatusCode() {
        let error = CooksyError.serverError(statusCode: 99999, message: "Unknown")
        XCTAssertEqual(error.localizedDescription, "Unknown")
    }

    func testValidationErrorWithEmptyMessage() {
        let error = CooksyError.validationError("")
        XCTAssertEqual(error.localizedDescription, "")
    }

    func testSubscriptionErrorWithEmptyMessage() {
        let error = CooksyError.subscriptionError("")
        XCTAssertEqual(error.localizedDescription, "")
    }

    func testTranscriptionUnavailableWithEmptyMessage() {
        let error = CooksyError.transcriptionUnavailable("")
        XCTAssertEqual(error.localizedDescription, "")
    }

    func testTranscriptionUnavailableWithLongMessage() {
        let longMessage = String(repeating: "x", count: 5000)
        let error = CooksyError.transcriptionUnavailable(longMessage)
        XCTAssertEqual(error.localizedDescription, longMessage)
    }

    // MARK: - Error Protocol Conformance Tests

    func testConformsToError() {
        let error: Error = CooksyError.invalidURL
        XCTAssertTrue(error is CooksyError)
    }

    func testConformsToLocalizedError() {
        let error: LocalizedError = CooksyError.invalidURL
        XCTAssertTrue(error is CooksyError)
    }

    func testConformsToEquatable() {
        let a = CooksyError.invalidURL
        let b = CooksyError.invalidURL
        XCTAssertTrue(a == b)
    }

    func testLocalizedDescriptionViaLocalizedErrorProtocol() {
        let error: LocalizedError = CooksyError.invalidURL
        XCTAssertEqual(error.errorDescription, "Please enter a valid URL")
    }

    func testAllErrorDescriptionsAreNonNil() {
        let errors: [CooksyError] = [
            .invalidURL,
            .unsupportedPlatform,
            .networkError(NSError(domain: "test", code: 0)),
            .serverError(statusCode: 500, message: "Error"),
            .unauthorized,
            .recipeNotFound,
            .importFailed("Failed"),
            .subscriptionError("Sub error"),
            .validationError("Validation error"),
            .transcriptionUnavailable("Transcription error"),
            .unknown
        ]
        for error in errors {
            XCTAssertNotNil((error as LocalizedError).errorDescription, "errorDescription should not be nil for \(error)")
        }
    }

    func testAllErrorDescriptionsAreNonEmpty() {
        let errors: [CooksyError] = [
            .invalidURL,
            .unsupportedPlatform,
            .unauthorized,
            .recipeNotFound,
            .importFailed("message"),
            .subscriptionError("message"),
            .validationError("message"),
            .transcriptionUnavailable("message"),
            .unknown
        ]
        for error in errors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Description should not be empty for \(error)")
        }
    }

    // MARK: - NSError Bridge Tests

    func testNSErrorDomain() {
        let nsError = CooksyError.invalidURL as NSError
        XCTAssertTrue(nsError.domain.contains("CooksyError"))
    }

    func testNSErrorCodeIsStable() {
        let nsError1 = CooksyError.invalidURL as NSError
        let nsError2 = CooksyError.invalidURL as NSError
        XCTAssertEqual(nsError1.code, nsError2.code)
    }

    func testDifferentCasesHaveDifferentCodes() {
        let nsError1 = CooksyError.invalidURL as NSError
        let nsError2 = CooksyError.unauthorized as NSError
        XCTAssertNotEqual(nsError1.code, nsError2.code)
    }

    // MARK: - Cross-Case Inequality Tests

    func testUnsupportedPlatformNotEqualToNetworkError() {
        let a = CooksyError.unsupportedPlatform
        let b = CooksyError.networkError(NSError(domain: "test", code: 0))
        XCTAssertNotEqual(a, b)
    }

    func testImportFailedNotEqualToValidationError() {
        let a = CooksyError.importFailed("msg")
        let b = CooksyError.validationError("msg")
        XCTAssertNotEqual(a, b)
    }

    func testServerErrorNotEqualToSubscriptionError() {
        let a = CooksyError.serverError(statusCode: 500, message: "msg")
        let b = CooksyError.subscriptionError("msg")
        XCTAssertNotEqual(a, b)
    }

    func testTranscriptionUnavailableNotEqualToUnknown() {
        let a = CooksyError.transcriptionUnavailable("msg")
        let b = CooksyError.unknown
        XCTAssertNotEqual(a, b)
    }

    func testRecipeNotFoundNotEqualToImportFailed() {
        let a = CooksyError.recipeNotFound
        let b = CooksyError.importFailed("not found")
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Type Erasure Tests

    func testErrorIdentityPreservedThroughTypeErasure() {
        let original = CooksyError.unauthorized
        let erased: Error = original
        guard let recovered = erased as? CooksyError else {
            XCTFail("Failed to recover CooksyError from type-erased Error")
            return
        }
        XCTAssertEqual(recovered, original)
    }

    func testNetworkErrorIdentityPreservedThroughTypeErasure() {
        let underlying = NSError(domain: "test.domain", code: 42)
        let original = CooksyError.networkError(underlying)
        let erased: Error = original
        guard let recovered = erased as? CooksyError else {
            XCTFail("Failed to recover CooksyError from type-erased Error")
            return
        }
        XCTAssertEqual(recovered, original)
    }
}
