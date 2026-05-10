import XCTest
@testable import Cooksy

// MARK: - Validators Tests
/// Comprehensive unit tests for the Validators utility.
/// Covers URL validation, email validation, OTP validation, and platform detection
/// for all supported platforms including edge cases.
final class ValidatorsTests: XCTestCase {

    // MARK: - isSupportedURL Tests

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

    // MARK: - isSupportedURL All Platform Coverage

    func testSupportedYouTubeStandardDomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/watch?v=abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/watch?v=abc123"))
        XCTAssertTrue(Validators.isSupportedURL("http://youtube.com/watch?v=abc123"))
    }

    func testSupportedYouTubeShorts() {
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/shorts/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/shorts/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/shorts/abc123?feature=share"))
    }

    func testSupportedYouTubeShortDomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://youtu.be/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("http://youtu.be/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtu.be/abc123?t=30"))
    }

    func testSupportedTikTokStandardDomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.tiktok.com/@chef/video/123456"))
        XCTAssertTrue(Validators.isSupportedURL("https://tiktok.com/@user/video/789"))
        XCTAssertTrue(Validators.isSupportedURL("http://tiktok.com/@user/video/789"))
    }

    func testSupportedTikTokVMShortDomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://vm.tiktok.com/abc123/"))
        XCTAssertTrue(Validators.isSupportedURL("https://vm.tiktok.com/ZMeABC123/"))
        XCTAssertTrue(Validators.isSupportedURL("http://vm.tiktok.com/abc"))
    }

    func testSupportedInstagramStandardDomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.instagram.com/reel/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://instagram.com/reel/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://instagram.com/p/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://instagram.com/tv/abc123"))
    }

    func testSupportedInstagramShortDomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://instagr.am/p/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://instagr.am/reel/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("http://instagr.am/p/abc123"))
    }

    // MARK: - isSupportedURL Edge Cases

    func testSupportedURLWithQueryParameters() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/watch?v=abc123&feature=share"))
        XCTAssertTrue(Validators.isSupportedURL("https://www.tiktok.com/@user/video/123?lang=en"))
        XCTAssertTrue(Validators.isSupportedURL("https://www.instagram.com/reel/abc123?igsh=xyz"))
    }

    func testSupportedURLWithFragment() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/watch?v=abc123#t=30s"))
    }

    func testSupportedURLWithSubdomain() {
        XCTAssertTrue(Validators.isSupportedURL("https://m.youtube.com/watch?v=abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://mobile.youtube.com/watch?v=abc123"))
    }

    func testSupportedURLCaseInsensitive() {
        XCTAssertTrue(Validators.isSupportedURL("https://WWW.YOUTUBE.COM/watch?v=abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://YOUTU.BE/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://WWW.TIKTOK.COM/@user/video/123"))
        XCTAssertTrue(Validators.isSupportedURL("https://INSTAGRAM.COM/reel/abc"))
        XCTAssertTrue(Validators.isSupportedURL("https://INSTAGR.AM/p/abc"))
    }

    func testSupportedURLWithPathVariations() {
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/embed/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/v/abc123"))
        XCTAssertTrue(Validators.isSupportedURL("https://youtube.com/playlist?list=abc"))
    }

    func testSupportedURLWithWWWPrefix() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/watch?v=abc"))
        XCTAssertTrue(Validators.isSupportedURL("https://www.tiktok.com/@user/video/1"))
        XCTAssertTrue(Validators.isSupportedURL("https://www.instagram.com/reel/abc"))
    }

    func testSupportedURLWithPort() {
        XCTAssertFalse(Validators.isSupportedURL("https://youtube.com:8080/watch?v=abc"))
    }

    func testSupportedURLWithUserInfo() {
        XCTAssertFalse(Validators.isSupportedURL("https://user:pass@randomsite.com"))
    }

    func testSupportedURLWithTrailingWhitespace() {
        XCTAssertFalse(Validators.isSupportedURL(" https://youtube.com/watch?v=abc"))
        XCTAssertFalse(Validators.isSupportedURL("https://youtube.com/watch?v=abc "))
    }

    func testSupportedURLEmptyString() {
        XCTAssertFalse(Validators.isSupportedURL(""))
    }

    func testSupportedURLWhitespaceOnly() {
        XCTAssertFalse(Validators.isSupportedURL("   "))
        XCTAssertFalse(Validators.isSupportedURL("\t\n"))
    }

    func testSupportedURLMissingScheme() {
        XCTAssertFalse(Validators.isSupportedURL("youtube.com/watch?v=abc"))
    }

    func testSupportedURLFTPScheme() {
        XCTAssertFalse(Validators.isSupportedURL("ftp://youtube.com/file"))
    }

    func testSupportedURLFileScheme() {
        XCTAssertFalse(Validators.isSupportedURL("file:///path/to/video"))
    }

    func testSupportedURLLongValidYouTubeURL() {
        let longUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL&index=1&ab_channel=Test"
        XCTAssertTrue(Validators.isSupportedURL(longUrl))
    }

    // MARK: - platformForURL Tests

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

    // MARK: - platformForURL All Platform Coverage

    func testPlatformForYouTubeStandardDomain() {
        XCTAssertEqual(Validators.platformForURL("https://youtube.com/watch?v=abc"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://www.youtube.com/watch?v=abc"), .youtube)
        XCTAssertEqual(Validators.platformForURL("http://youtube.com/watch?v=abc"), .youtube)
    }

    func testPlatformForYouTubeShorts() {
        XCTAssertEqual(Validators.platformForURL("https://youtube.com/shorts/abc123"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://www.youtube.com/shorts/abc123?f=1"), .youtube)
    }

    func testPlatformForYouTubeShortDomain() {
        XCTAssertEqual(Validators.platformForURL("https://youtu.be/abc123"), .youtube)
        XCTAssertEqual(Validators.platformForURL("http://youtu.be/abc123?t=30"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://youtu.be/"), .youtube)
    }

    func testPlatformForTikTokStandardDomain() {
        XCTAssertEqual(Validators.platformForURL("https://tiktok.com/@user/video/123"), .tiktok)
        XCTAssertEqual(Validators.platformForURL("https://www.tiktok.com/@chef/video/123"), .tiktok)
        XCTAssertEqual(Validators.platformForURL("http://tiktok.com/@user/video/789"), .tiktok)
    }

    func testPlatformForTikTokVMShortDomain() {
        XCTAssertEqual(Validators.platformForURL("https://vm.tiktok.com/abc123/"), .tiktok)
        XCTAssertEqual(Validators.platformForURL("http://vm.tiktok.com/short"), .tiktok)
    }

    func testPlatformForInstagramStandardDomain() {
        XCTAssertEqual(Validators.platformForURL("https://instagram.com/reel/abc"), .instagram)
        XCTAssertEqual(Validators.platformForURL("https://www.instagram.com/p/abc"), .instagram)
        XCTAssertEqual(Validators.platformForURL("https://instagram.com/tv/abc"), .instagram)
    }

    func testPlatformForInstagramShortDomain() {
        XCTAssertEqual(Validators.platformForURL("https://instagr.am/p/abc123"), .instagram)
        XCTAssertEqual(Validators.platformForURL("https://instagr.am/reel/abc"), .instagram)
        XCTAssertEqual(Validators.platformForURL("http://instagr.am/p/abc"), .instagram)
    }

    // MARK: - platformForURL Edge Cases

    func testPlatformForURLWithQueryParameters() {
        XCTAssertEqual(Validators.platformForURL("https://www.youtube.com/watch?v=abc123&list=PL"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://www.tiktok.com/@user/video/123?lang=en"), .tiktok)
        XCTAssertEqual(Validators.platformForURL("https://www.instagram.com/reel/abc123?igsh=xyz"), .instagram)
    }

    func testPlatformForURLCaseInsensitive() {
        XCTAssertEqual(Validators.platformForURL("https://WWW.YOUTUBE.COM/watch?v=abc"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://YOUTU.BE/abc"), .youtube)
        XCTAssertEqual(Validators.platformForURL("https://WWW.TIKTOK.COM/@user/video/1"), .tiktok)
        XCTAssertEqual(Validators.platformForURL("https://INSTAGRAM.COM/reel/abc"), .instagram)
        XCTAssertEqual(Validators.platformForURL("https://INSTAGR.AM/p/abc"), .instagram)
    }

    func testPlatformForURLEmptyString() {
        XCTAssertNil(Validators.platformForURL(""))
    }

    func testPlatformForURLWhitespaceOnly() {
        XCTAssertNil(Validators.platformForURL("   "))
        XCTAssertNil(Validators.platformForURL("\t\n"))
    }

    func testPlatformForURLInvalidURL() {
        XCTAssertNil(Validators.platformForURL("not-a-url"))
        XCTAssertNil(Validators.platformForURL("://missing-scheme"))
        XCTAssertNil(Validators.platformForURL("just-some-text"))
    }

    func testPlatformForURLMissingScheme() {
        XCTAssertNil(Validators.platformForURL("youtube.com/watch?v=abc"))
    }

    func testPlatformForURLUnsupportedPlatform() {
        XCTAssertNil(Validators.platformForURL("https://www.facebook.com/video/123"))
        XCTAssertNil(Validators.platformForURL("https://twitter.com/user/status/123"))
        XCTAssertNil(Validators.platformForURL("https://google.com"))
        XCTAssertNil(Validators.platformForURL("https://vimeo.com/123456"))
        XCTAssertNil(Validators.platformForURL("https://twitch.tv/video/123"))
        XCTAssertNil(Validators.platformForURL("https://reddit.com/r/cooking"))
    }

    func testPlatformForURLWithFragment() {
        XCTAssertEqual(Validators.platformForURL("https://www.youtube.com/watch?v=abc#t=30s"), .youtube)
    }

    func testPlatformForURLWithSubdomain() {
        XCTAssertEqual(Validators.platformForURL("https://m.youtube.com/watch?v=abc"), .youtube)
    }

    // MARK: - isValidEmail Tests

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

    // MARK: - isValidEmail Edge Cases

    func testValidEmailWithDashInLocal() {
        XCTAssertTrue(Validators.isValidEmail("user-name@example.com"))
    }

    func testValidEmailWithUnderscoreInLocal() {
        XCTAssertTrue(Validators.isValidEmail("user_name@example.com"))
    }

    func testValidEmailWithPlusInLocal() {
        XCTAssertTrue(Validators.isValidEmail("user+tag+sort@example.com"))
    }

    func testValidEmailWithMultipleDotsInDomain() {
        XCTAssertTrue(Validators.isValidEmail("user@sub.domain.example.com"))
    }

    func testValidEmailWithLongTLD() {
        XCTAssertTrue(Validators.isValidEmail("user@example.technology"))
    }

    func testValidEmailWithNumericLocal() {
        XCTAssertTrue(Validators.isValidEmail("123456@example.com"))
    }

    func testValidEmailWithMixedCase() {
        XCTAssertTrue(Validators.isValidEmail("User.Name@Example.COM"))
    }

    func testValidEmailWithSingleCharacterLocal() {
        XCTAssertTrue(Validators.isValidEmail("a@b.co"))
    }

    func testValidEmailWithTwoCharacterTLD() {
        XCTAssertTrue(Validators.isValidEmail("user@example.io"))
    }

    func testInvalidEmailEmptyString() {
        XCTAssertFalse(Validators.isValidEmail(""))
    }

    func testInvalidEmailWhitespaceOnly() {
        XCTAssertFalse(Validators.isValidEmail("   "))
        XCTAssertFalse(Validators.isValidEmail("\t\n"))
    }

    func testInvalidEmailWithSpaces() {
        XCTAssertFalse(Validators.isValidEmail("user name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@exam ple.com"))
        XCTAssertFalse(Validators.isValidEmail(" user@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@example.com "))
    }

    func testInvalidEmailNoAtSymbol() {
        XCTAssertFalse(Validators.isValidEmail("userexample.com"))
    }

    func testInvalidEmailMultipleAtSymbols() {
        XCTAssertFalse(Validators.isValidEmail("user@@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user@name@example.com"))
    }

    func testInvalidEmailNoDomain() {
        XCTAssertFalse(Validators.isValidEmail("user@"))
    }

    func testInvalidEmailNoLocalPart() {
        XCTAssertFalse(Validators.isValidEmail("@example.com"))
    }

    func testInvalidEmailNoTLD() {
        XCTAssertFalse(Validators.isValidEmail("user@domain"))
    }

    func testInvalidEmailDotBeforeAt() {
        XCTAssertFalse(Validators.isValidEmail("user.@example.com"))
    }

    func testInvalidEmailConsecutiveDotsInDomain() {
        XCTAssertFalse(Validators.isValidEmail("user@domain..com"))
    }

    func testInvalidEmailSingleCharacterTLD() {
        XCTAssertFalse(Validators.isValidEmail("user@domain.c"))
    }

    func testInvalidEmailSpecialCharactersInDomain() {
        XCTAssertFalse(Validators.isValidEmail("user@dom!ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom#ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom$ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom%ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom^ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom&ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom*ain.com"))
        XCTAssertFalse(Validators.isValidEmail("user@dom(ain.com"))
    }

    func testInvalidEmailSpecialCharactersInLocal() {
        XCTAssertFalse(Validators.isValidEmail("user!name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user#name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user$name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user%name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user^name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user&name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user*name@example.com"))
        XCTAssertFalse(Validators.isValidEmail("user(name)@example.com"))
    }

    func testInvalidEmailUnicodeInLocal() {
        XCTAssertFalse(Validators.isValidEmail("\u{4E2D}\u{6587}@example.com"))
    }

    func testInvalidEmailVeryLong() {
        let local = String(repeating: "a", count: 250)
        XCTAssertFalse(Validators.isValidEmail("\(local)@example.com"))
    }

    func testInvalidEmailTabCharacter() {
        XCTAssertFalse(Validators.isValidEmail("user\tname@example.com"))
    }

    func testInvalidEmailNewlineCharacter() {
        XCTAssertFalse(Validators.isValidEmail("user\nname@example.com"))
    }

    // MARK: - isValidOTP Tests

    func testValidOTP() {
        XCTAssertTrue(Validators.isValidOTP("123456"))
        XCTAssertTrue(Validators.isValidOTP("000000"))
        XCTAssertTrue(Validators.isValidOTP("999999"))
    }

    func testInvalidOTP() {
        XCTAssertFalse(Validators.isValidOTP(""))
        XCTAssertFalse(Validators.isValidOTP("12345"))
        XCTAssertFalse(Validators.isValidOTP("1234567"))
        XCTAssertFalse(Validators.isValidOTP("12a456"))
        XCTAssertFalse(Validators.isValidOTP("12 456"))
        XCTAssertFalse(Validators.isValidOTP("-12345"))
        XCTAssertFalse(Validators.isValidOTP("12345 "))
    }

    // MARK: - isValidOTP Edge Cases

    func testValidOTPAllSameDigits() {
        XCTAssertTrue(Validators.isValidOTP("111111"))
        XCTAssertTrue(Validators.isValidOTP("222222"))
        XCTAssertTrue(Validators.isValidOTP("000000"))
    }

    func testValidOTPSequential() {
        XCTAssertTrue(Validators.isValidOTP("123456"))
        XCTAssertTrue(Validators.isValidOTP("654321"))
    }

    func testValidOTPAlternating() {
        XCTAssertTrue(Validators.isValidOTP("121212"))
    }

    func testValidOTPPalindrome() {
        XCTAssertTrue(Validators.isValidOTP("123321"))
    }

    func testInvalidOTPEmptyString() {
        XCTAssertFalse(Validators.isValidOTP(""))
    }

    func testInvalidOTPWhitespaceOnly() {
        XCTAssertFalse(Validators.isValidOTP("   "))
        XCTAssertFalse(Validators.isValidOTP("\t\n"))
    }

    func testInvalidOTPTooShort() {
        XCTAssertFalse(Validators.isValidOTP("1"))
        XCTAssertFalse(Validators.isValidOTP("12"))
        XCTAssertFalse(Validators.isValidOTP("123"))
        XCTAssertFalse(Validators.isValidOTP("1234"))
        XCTAssertFalse(Validators.isValidOTP("12345"))
    }

    func testInvalidOTPTooLong() {
        XCTAssertFalse(Validators.isValidOTP("1234567"))
        XCTAssertFalse(Validators.isValidOTP("12345678"))
        XCTAssertFalse(Validators.isValidOTP("123456789"))
        XCTAssertFalse(Validators.isValidOTP("1234567890"))
    }

    func testInvalidOTPWithLetters() {
        XCTAssertFalse(Validators.isValidOTP("12a456"))
        XCTAssertFalse(Validators.isValidOTP("abcdef"))
        XCTAssertFalse(Validators.isValidOTP("1A3456"))
        XCTAssertFalse(Validators.isValidOTP("z23456"))
        XCTAssertFalse(Validators.isValidOTP("12345f"))
    }

    func testInvalidOTPWithSpaces() {
        XCTAssertFalse(Validators.isValidOTP("12 456"))
        XCTAssertFalse(Validators.isValidOTP("123 56"))
        XCTAssertFalse(Validators.isValidOTP(" 23456"))
        XCTAssertFalse(Validators.isValidOTP("123456 "))
    }

    func testInvalidOTPWithSymbols() {
        XCTAssertFalse(Validators.isValidOTP("-12345"))
        XCTAssertFalse(Validators.isValidOTP("!@#$%^"))
        XCTAssertFalse(Validators.isValidOTP("12.456"))
        XCTAssertFalse(Validators.isValidOTP("12_456"))
        XCTAssertFalse(Validators.isValidOTP("12345+"))
    }

    func testInvalidOTPWithUnicode() {
        XCTAssertFalse(Validators.isValidOTP("\u{4E00}23456"))
        XCTAssertFalse(Validators.isValidOTP("12\u{0030}3456"))
    }

    func testInvalidOTPLeadingZeroButFiveDigits() {
        XCTAssertFalse(Validators.isValidOTP("01234"))
    }

    func testInvalidOTPWithNewline() {
        XCTAssertFalse(Validators.isValidOTP("12345\n"))
    }

    func testInvalidOTPWithTab() {
        XCTAssertFalse(Validators.isValidOTP("12345\t"))
    }

    func testInvalidOTPNegativeNumber() {
        XCTAssertFalse(Validators.isValidOTP("-12345"))
    }

    // MARK: - Supported Domains Tests

    func testSupportedDomainsCount() {
        XCTAssertGreaterThanOrEqual(Validators.supportedDomains.count, 6)
    }

    func testAllSupportedDomainsAreLowercase() {
        for domain in Validators.supportedDomains {
            XCTAssertEqual(domain, domain.lowercased(), "Domain '\(domain)' should be lowercase")
        }
    }

    func testSupportedDomainsContainsYouTube() {
        XCTAssertTrue(Validators.supportedDomains.contains("youtube.com"))
    }

    func testSupportedDomainsContainsYouTuBe() {
        XCTAssertTrue(Validators.supportedDomains.contains("youtu.be"))
    }

    func testSupportedDomainsContainsTikTok() {
        XCTAssertTrue(Validators.supportedDomains.contains("tiktok.com"))
    }

    func testSupportedDomainsContainsVMTikTok() {
        XCTAssertTrue(Validators.supportedDomains.contains("vm.tiktok.com"))
    }

    func testSupportedDomainsContainsInstagram() {
        XCTAssertTrue(Validators.supportedDomains.contains("instagram.com"))
    }

    func testSupportedDomainsContainsInstagrAm() {
        XCTAssertTrue(Validators.supportedDomains.contains("instagr.am"))
    }

    func testSupportedDomainsDoesNotContainDuplicates() {
        let uniqueDomains = Set(Validators.supportedDomains)
        XCTAssertEqual(uniqueDomains.count, Validators.supportedDomains.count)
    }

    func testSupportedDomainsAreNotEmpty() {
        for domain in Validators.supportedDomains {
            XCTAssertFalse(domain.isEmpty, "Domain should not be empty")
        }
    }

    func testSupportedDomainsDoNotContainSpaces() {
        for domain in Validators.supportedDomains {
            XCTAssertFalse(domain.contains(" "), "Domain '\(domain)' should not contain spaces")
        }
    }

    // MARK: - SourcePlatform Enum Consistency

    func testPlatformYouTubeRawValue() {
        XCTAssertEqual(SourcePlatform.youtube.rawValue, "youtube")
    }

    func testPlatformTikTokRawValue() {
        XCTAssertEqual(SourcePlatform.tiktok.rawValue, "tiktok")
    }

    func testPlatformInstagramRawValue() {
        XCTAssertEqual(SourcePlatform.instagram.rawValue, "instagram")
    }

    func testPlatformYouTubeCaseIterable() {
        XCTAssertTrue(SourcePlatform.allCases.contains(.youtube))
    }

    func testPlatformTikTokCaseIterable() {
        XCTAssertTrue(SourcePlatform.allCases.contains(.tiktok))
    }

    func testPlatformInstagramCaseIterable() {
        XCTAssertTrue(SourcePlatform.allCases.contains(.instagram))
    }

    func testPlatformCount() {
        XCTAssertEqual(SourcePlatform.allCases.count, 3)
    }

    // MARK: - isSupportedURL with URL Fragments

    func testSupportedURLWithFragmentIdentifier() {
        XCTAssertTrue(Validators.isSupportedURL("https://www.youtube.com/watch?v=abc123#comments"))
    }

    func testSupportedURLWithTimestampFragment() {
        XCTAssertTrue(Validators.isSupportedURL("https://youtu.be/abc123#t=30s"))
    }

    // MARK: - Cross-Validator Consistency Tests

    func testSupportedURLMatchesPlatformForURL() {
        let urls = [
            "https://www.youtube.com/watch?v=abc",
            "https://youtu.be/abc",
            "https://www.tiktok.com/@user/video/123",
            "https://vm.tiktok.com/abc",
            "https://www.instagram.com/reel/abc",
            "https://instagr.am/p/abc"
        ]
        for url in urls {
            if Validators.isSupportedURL(url) {
                XCTAssertNotNil(Validators.platformForURL(url), "URL '\(url)' is supported but has no platform")
            }
        }
    }

    func testUnsupportedURLReturnsNoPlatform() {
        let urls = [
            "https://www.facebook.com/video",
            "https://twitter.com/user/status/123",
            "https://google.com",
            "not-a-url",
            "",
            "https://vimeo.com/123"
        ]
        for url in urls {
            if !Validators.isSupportedURL(url) {
                XCTAssertNil(Validators.platformForURL(url), "URL '\(url)' is unsupported but returned a platform")
            }
        }
    }
}
