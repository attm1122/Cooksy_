import XCTest
@testable import Cooksy

// MARK: - Validators Tests
/// Comprehensive unit tests for the Validators utility.
/// Covers URL validation, email validation, OTP validation, and platform detection.
final class ValidatorsTests: XCTestCase {
    
    // MARK: - URL Validation Tests
    
    func testSupportedYouTubeURL() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/watch?v=dQw4w9WgXcQ"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/shorts/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtu.be/abc123"))
    }
    
    func testSupportedTikTokURL() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.tiktok.com/@chef/video/123456"))
        XCTAssertTrue(Validators.isSupportedURL("https://vm.tiktok.com/abc123/"))
    }
    
    func testSupportedInstagramURL() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.instagram.com/reel/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://instagr.am/p/abc123"))
    }
    
    func testUnsupportedURL() {
        XCTAssertFalse(Validators.isSupportedURL("https://www.facebook.com/video"))
        XCTAssertFalse(Validators.isSupportedURL("https://twitter.com/user/status/123"))
        XCTAssertFalse(Validators.isSupportedURL("https://google.com"))
        XCTAssertFalse(Validators.isSupportedURL("not-a-url"))
    }
    
    func testEmptyURL() {
        XCTAssertFalse(Validators.isSupportedURL(""))
    }
    
    func testMalformedURL() {
        XCTAssertFalse(Validators.isSupportedURL("://missing-scheme"))
    }
    
    // MARK: - Platform Detection Tests
    
    func testPlatformForYouTubeURL() {
        XCTAssertEqual(Validators.platformForURL("https://www.youtube.com/watch?v=123"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://youtu.be/abc123"), .youtube)
    }
    
    func testPlatformForTikTokURL() {
        XCTAssertEqual(Validators.platformForURL("https://www.tiktok.com/@user/video/123"), .tiktok)
    }
    
    func testPlatformForInstagramURL() {
        XCTAssertEqual(Validators.platformForURL("https://www.instagram.com/reel/abc"), .instagram)
        XCTAssertEqual(Validators.platformForURL("https://instagr.am/p/abc"), .instagram)
    }
    
    func testPlatformForUnsupportedURL() {
        XCTAssertNil(Validators.platformForURL("https://www.facebook.com/video"))
        XCTAssertNil(Validators.platformForURL("invalid-url"))
        XCTAssertNil(Validators.platformForURL(""))
    }
    
    // MARK: - Email Validation Tests
    
    func testValidEmails() {
        XCTAssertTrue(Validators.isValidEmail("user@example.com"))
        XCTAssertTrue(Validators.isValidEmail("test.name@domain.co.uk"))
        XCTAssertTrue(Validators.isValidEmail("user+tag@example.com"))
        XCTAssertTrue(Validators.isValidEmail("123@numeric.domain"))
        XCTAssertTrue(Validators.isValidEmail("UPPER@EXAMPLE.COM"))
    }
    
    func testInvalidEmails() {
        XCTAssertFalse(Validators.isValidEmail(""))
        XCTAssertFalse(Validators.isValidEmail("plainaddress"))
        XCTAssertFalse(Validators.isValidEmail("@missinglocal.com"))
        XCTAssertFalse(Validators.isValidEmail("missing@domain"))
        XCTAssertFalse(Validators.isValidEmail("missing@.com"))
        XCTAssertFalse(Validators.isValidEmail("spaces in@domain.com"))
    }
    
    // MARK: - OTP Validation Tests
    
    func testValidOTP() {
        XCTAssertTrue(Validators.isValidOTP("123456"))
        XCTAssertTrue(Validators.isValidOTP("000000"))
        XCTAssertTrue(Validators.isValidOTP("999999"))
    }
    
    func testInvalidOTP() {
        XCTAssertFalse(Validators.isValidOTP(""))
        XCTAssertFalse(Validators.isValidOTP("12345"))       // Too short (5)
        XCTAssertFalse(Validators.isValidOTP("1234567"))     // Too long (7)
        XCTAssertFalse(Validators.isValidOTP("12a456"))      // Contains letter
        XCTAssertFalse(Validators.isValidOTP("12 456"))      // Contains space
        XCTAssertFalse(Validators.isValidOTP("-12345"))      // Contains symbol
        XCTAssertFalse(Validators.isValidOTP("12345 "))      // Trailing space
    }
    
    // MARK: - Supported Domains Tests
    
    func testSupportedDomainsCount() {
        // We expect at least 6 supported domains
        XCTAssertGreaterThanOrEqual(Validators.supportedDomains.count, 6)
    }
    
    func testAllSupportedDomainsAreLowercase() {
        for domain in Validators.supportedDomains {
            XCTAssertEqual(domain, domain.lowercased(), "Domain '\(domain)' should be lowercase")
        }
    }
}
