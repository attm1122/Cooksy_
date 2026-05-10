import XCTest
@testable import Cooksy

// MARK: - DeepLinkService Tests
/// Comprehensive unit tests for the DeepLinkService.
/// Covers handle(url:) for all URL types, URL generation methods,
/// activeTarget publisher, clearTarget(), invalid URL handling, and singleton pattern.
@MainActor
final class DeepLinkServiceTests: XCTestCase {

    private var service: DeepLinkService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        service = DeepLinkService.shared
        service.clearTarget()
    }

    override func tearDown() {
        service.clearTarget()
        service = nil
        super.tearDown()
    }

    // MARK: - Singleton Pattern Tests

    func testSharedInstanceExists() {
        let service = DeepLinkService.shared
        XCTAssertNotNil(service)
    }

    func testSharedReturnsSameInstance() {
        let service1 = DeepLinkService.shared
        let service2 = DeepLinkService.shared
        XCTAssertTrue(service1 === service2)
    }

    // MARK: - handle(url:) Recipe Tests

    func testHandleRecipeDeepLink() {
        let url = URL(string: "cooksy://recipe/abc123")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleRecipeDeepLinkSetsActiveTarget() {
        let url = URL(string: "cooksy://recipe/abc123")!
        service.handle(url: url)
        if case .recipe(let id) = service.activeTarget {
            XCTAssertEqual(id, "abc123")
        } else {
            XCTFail("Expected .recipe target")
        }
    }

    func testHandleRecipeWithUUID() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let url = URL(string: "cooksy://recipe/\(uuid)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleRecipeWithTrailingSlash() {
        let url = URL(string: "cooksy://recipe/abc123/")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleRecipeWithPathPrefix() {
        let url = URL(string: "cooksy://recipe//abc123")!
        service.handle(url: url)
    }

    // MARK: - handle(url:) Import Tests

    func testHandleImportDeepLink() {
        let encodedUrl = "https://www.youtube.com/watch?v=abc123".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleImportDeepLinkSetsActiveTarget() {
        let videoUrl = "https://www.youtube.com/watch?v=abc123"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        service.handle(url: url)
        if case .importVideo(let returnedUrl) = service.activeTarget {
            XCTAssertEqual(returnedUrl, videoUrl)
        } else {
            XCTFail("Expected .importVideo target")
        }
    }

    func testHandleImportWithTikTokURL() {
        let videoUrl = "https://www.tiktok.com/@chef/video/123456"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleImportWithInstagramURL() {
        let videoUrl = "https://www.instagram.com/reel/abc123"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleImportWithoutUrlParameter() {
        let url = URL(string: "cooksy://import")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    // MARK: - handle(url:) Subscription Tests

    func testHandleSubscriptionDeepLink() {
        let url = URL(string: "cooksy://subscription")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleSubscriptionSetsActiveTarget() {
        let url = URL(string: "cooksy://subscription")!
        service.handle(url: url)
        if case .subscription = service.activeTarget {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .subscription target")
        }
    }

    // MARK: - handle(url:) Profile Tests

    func testHandleProfileDeepLink() {
        let url = URL(string: "cooksy://profile")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleProfileSetsActiveTarget() {
        let url = URL(string: "cooksy://profile")!
        service.handle(url: url)
        if case .profile = service.activeTarget {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .profile target")
        }
    }

    // MARK: - handle(url:) Settings Tests

    func testHandleSettingsDeepLink() {
        let url = URL(string: "cooksy://settings")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleSettingsSetsActiveTarget() {
        let url = URL(string: "cooksy://settings")!
        service.handle(url: url)
        if case .settings = service.activeTarget {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .settings target")
        }
    }

    // MARK: - Invalid URL Handling Tests

    func testHandleInvalidScheme() {
        let url = URL(string: "https://recipe/abc123")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleUnknownHost() {
        let url = URL(string: "cooksy://unknown")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleEmptyHost() {
        let url = URL(string: "cooksy://")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleCompletelyInvalidURL() {
        let url = URL(string: "not-a-url")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleURLWithNoComponents() {
        let url = URL(string: "cooksy://")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleUnknownDeepLinkPath() {
        let url = URL(string: "cooksy://random/path")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleURLWithQueryOnUnknownHost() {
        let url = URL(string: "cooksy://random?param=value")!
        let handled = service.handle(url: url)
        XCTAssertFalse(handled)
    }

    // MARK: - recipeLink(recipeId:) Tests

    func testRecipeLinkGeneratesCorrectURL() {
        let link = DeepLinkService.recipeLink(recipeId: "abc123")
        XCTAssertEqual(link, "cooksy://recipe/abc123")
    }

    func testRecipeLinkWithUUID() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let link = DeepLinkService.recipeLink(recipeId: uuid)
        XCTAssertEqual(link, "cooksy://recipe/\(uuid)")
    }

    func testRecipeLinkWithEmptyId() {
        let link = DeepLinkService.recipeLink(recipeId: "")
        XCTAssertEqual(link, "cooksy://recipe/")
    }

    func testRecipeLinkWithSpecialCharacters() {
        let link = DeepLinkService.recipeLink(recipeId: "recipe-123_test")
        XCTAssertEqual(link, "cooksy://recipe/recipe-123_test")
    }

    func testRecipeLinkWithUnicode() {
        let link = DeepLinkService.recipeLink(recipeId: "\u{1F370}")
        XCTAssertEqual(link, "cooksy://recipe/\u{1F370}")
    }

    // MARK: - recipeWebLink(recipeId:) Tests

    func testRecipeWebLinkGeneratesCorrectURL() {
        let link = DeepLinkService.recipeWebLink(recipeId: "abc123")
        XCTAssertEqual(link, "https://cooksy.app/recipe/abc123")
    }

    func testRecipeWebLinkWithUUID() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let link = DeepLinkService.recipeWebLink(recipeId: uuid)
        XCTAssertEqual(link, "https://cooksy.app/recipe/\(uuid)")
    }

    func testRecipeWebLinkWithEmptyId() {
        let link = DeepLinkService.recipeWebLink(recipeId: "")
        XCTAssertEqual(link, "https://cooksy.app/recipe/")
    }

    func testRecipeWebLinkWithSpecialCharacters() {
        let link = DeepLinkService.recipeWebLink(recipeId: "recipe-123_test")
        XCTAssertEqual(link, "https://cooksy.app/recipe/recipe-123_test")
    }

    func testRecipeWebLinkUsesHttpsScheme() {
        let link = DeepLinkService.recipeWebLink(recipeId: "any")
        XCTAssertTrue(link.hasPrefix("https://"))
    }

    func testRecipeWebLinkUsesCorrectDomain() {
        let link = DeepLinkService.recipeWebLink(recipeId: "any")
        XCTAssertTrue(link.contains("cooksy.app"))
    }

    // MARK: - importLink(videoUrl:) Tests

    func testImportLinkGeneratesCorrectURL() {
        let link = DeepLinkService.importLink(videoUrl: "https://youtube.com/watch?v=abc")
        XCTAssertTrue(link.hasPrefix("cooksy://import"))
    }

    func testImportLinkContainsUrlParameter() {
        let link = DeepLinkService.importLink(videoUrl: "https://youtube.com/watch?v=abc")
        XCTAssertTrue(link.contains("url="))
    }

    func testImportLinkWithEmptyURL() {
        let link = DeepLinkService.importLink(videoUrl: "")
        XCTAssertTrue(link.hasPrefix("cooksy://import"))
    }

    func testImportLinkWithSpecialCharacters() {
        let link = DeepLinkService.importLink(videoUrl: "https://example.com?a=1&b=2")
        XCTAssertTrue(link.hasPrefix("cooksy://import"))
    }

    func testImportLinkWithUnicode() {
        let link = DeepLinkService.importLink(videoUrl: "https://example.com/\u{4E2D}\u{6587}")
        XCTAssertTrue(link.hasPrefix("cooksy://import"))
    }

    func testImportLinkEncodesQueryParameters() {
        let videoUrl = "https://youtube.com/watch?v=abc&feature=share"
        let link = DeepLinkService.importLink(videoUrl: videoUrl)
        XCTAssertTrue(link.hasPrefix("cooksy://import"))
    }

    // MARK: - activeTarget Tests

    func testActiveTargetInitiallyNil() {
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    func testActiveTargetAfterHandlingRecipe() {
        let url = URL(string: "cooksy://recipe/test123")!
        service.handle(url: url)
        XCTAssertNotNil(service.activeTarget)
    }

    func testActiveTargetAfterHandlingSubscription() {
        let url = URL(string: "cooksy://subscription")!
        service.handle(url: url)
        XCTAssertNotNil(service.activeTarget)
    }

    func testActiveTargetAfterHandlingInvalidURL() {
        let url = URL(string: "cooksy://unknown")!
        service.handle(url: url)
        XCTAssertNil(service.activeTarget)
    }

    // MARK: - clearTarget() Tests

    func testClearTarget() {
        let url = URL(string: "cooksy://recipe/abc123")!
        service.handle(url: url)
        XCTAssertNotNil(service.activeTarget)
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    func testClearTargetWhenAlreadyNil() {
        service.clearTarget()
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    func testClearTargetAfterSubscription() {
        let url = URL(string: "cooksy://subscription")!
        service.handle(url: url)
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    func testClearTargetAfterProfile() {
        let url = URL(string: "cooksy://profile")!
        service.handle(url: url)
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    func testClearTargetAfterSettings() {
        let url = URL(string: "cooksy://settings")!
        service.handle(url: url)
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    func testClearTargetAfterImport() {
        let videoUrl = "https://www.youtube.com/watch?v=abc123"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        service.handle(url: url)
        service.clearTarget()
        XCTAssertNil(service.activeTarget)
    }

    // MARK: - DeepLinkTarget Enum Tests

    func testDeepLinkTargetRecipeExists() {
        let target = DeepLinkService.DeepLinkTarget.recipe(id: "test")
        XCTAssertNotNil(target)
    }

    func testDeepLinkTargetImportVideoExists() {
        let target = DeepLinkService.DeepLinkTarget.importVideo(url: "https://test.com")
        XCTAssertNotNil(target)
    }

    func testDeepLinkTargetSubscriptionExists() {
        let target = DeepLinkService.DeepLinkTarget.subscription
        XCTAssertNotNil(target)
    }

    func testDeepLinkTargetProfileExists() {
        let target = DeepLinkService.DeepLinkTarget.profile
        XCTAssertNotNil(target)
    }

    func testDeepLinkTargetSettingsExists() {
        let target = DeepLinkService.DeepLinkTarget.settings
        XCTAssertNotNil(target)
    }

    func testDeepLinkTargetRecipeId() {
        let target = DeepLinkService.DeepLinkTarget.recipe(id: "recipe123")
        XCTAssertEqual(target.id, "recipe-recipe123")
    }

    func testDeepLinkTargetSubscriptionId() {
        let target = DeepLinkService.DeepLinkTarget.subscription
        XCTAssertEqual(target.id, "subscription")
    }

    func testDeepLinkTargetProfileId() {
        let target = DeepLinkService.DeepLinkTarget.profile
        XCTAssertEqual(target.id, "profile")
    }

    func testDeepLinkTargetSettingsId() {
        let target = DeepLinkService.DeepLinkTarget.settings
        XCTAssertEqual(target.id, "settings")
    }

    func testDeepLinkTargetImportVideoId() {
        let url = "https://example.com/video"
        let target = DeepLinkService.DeepLinkTarget.importVideo(url: url)
        XCTAssertEqual(target.id, "import-\(url)")
    }

    func testDeepLinkTargetRecipeHashable() {
        let a = DeepLinkService.DeepLinkTarget.recipe(id: "abc")
        let b = DeepLinkService.DeepLinkTarget.recipe(id: "abc")
        XCTAssertEqual(a, b)
    }

    func testDeepLinkTargetIdentifiable() {
        let target = DeepLinkService.DeepLinkTarget.recipe(id: "test")
        XCTAssertEqual(target.id, "recipe-test")
    }

    func testDeepLinkTargetsAreNotEqual() {
        let a = DeepLinkService.DeepLinkTarget.recipe(id: "abc")
        let b = DeepLinkService.DeepLinkTarget.subscription
        XCTAssertNotEqual(a, b)
    }

    // MARK: - isProcessing Tests

    func testIsProcessingInitiallyFalse() {
        XCTAssertFalse(service.isProcessing)
    }

    func testIsProcessingAccessible() {
        let processing = service.isProcessing
        XCTAssertFalse(processing)
    }

    // MARK: - handleUniversalLink Tests

    func testHandleUniversalLinkWithRecipe() {
        let url = URL(string: "https://cooksy.app/recipe/abc123")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleUniversalLinkWithRecipeSetsTarget() {
        let url = URL(string: "https://cooksy.app/recipe/abc123")!
        service.handleUniversalLink(url: url)
        if case .recipe(let id) = service.activeTarget {
            XCTAssertEqual(id, "abc123")
        } else {
            XCTFail("Expected .recipe target from universal link")
        }
    }

    func testHandleUniversalLinkWithImport() {
        let videoUrl = "https://youtube.com/watch?v=abc"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "https://cooksy.app/import?url=\(encodedUrl)")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleUniversalLinkWithWrongDomain() {
        let url = URL(string: "https://other-app.com/recipe/abc123")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleUniversalLinkWithSubdomain() {
        let url = URL(string: "https://www.cooksy.app/recipe/abc123")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleUniversalLinkWithoutEnoughPathComponents() {
        let url = URL(string: "https://cooksy.app/recipe")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleUniversalLinkWithUnknownPath() {
        let url = URL(string: "https://cooksy.app/unknown/something")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertFalse(handled)
    }

    func testHandleUniversalLinkWithoutCooksyDomain() {
        let url = URL(string: "https://google.com/recipe/abc")!
        let handled = service.handleUniversalLink(url: url)
        XCTAssertFalse(handled)
    }

    // MARK: - Deep Link Round-Trip Tests

    func testRecipeLinkRoundTrip() {
        let recipeId = "my-recipe-123"
        let link = DeepLinkService.recipeLink(recipeId: recipeId)
        let url = URL(string: link)!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
        if case .recipe(let id) = service.activeTarget {
            XCTAssertEqual(id, recipeId)
        } else {
            XCTFail("Expected .recipe target")
        }
    }

    func testRecipeWebLinkIsNotDeepLink() {
        let link = DeepLinkService.recipeWebLink(recipeId: "abc")
        XCTAssertTrue(link.hasPrefix("https://"))
        XCTAssertFalse(link.hasPrefix("cooksy://"))
    }

    func testGeneratedLinksAreValidStrings() {
        let recipeLink = DeepLinkService.recipeLink(recipeId: "test")
        let webLink = DeepLinkService.recipeWebLink(recipeId: "test")
        let importLink = DeepLinkService.importLink(videoUrl: "https://test.com")

        XCTAssertFalse(recipeLink.isEmpty)
        XCTAssertFalse(webLink.isEmpty)
        XCTAssertFalse(importLink.isEmpty)
    }

    // MARK: - Service Characteristic Tests

    func testServiceIsObservable() {
        let service = DeepLinkService.shared
        XCTAssertNotNil(service)
    }

    func testServiceIsMainActor() {
        let service = DeepLinkService.shared
        XCTAssertNotNil(service)
    }

    func testServiceIsFinalClass() {
        let service = DeepLinkService.shared
        XCTAssertTrue(type(of: service) == DeepLinkService.self)
    }

    // MARK: - Multiple Sequential Handle Tests

    func testHandleMultipleDifferentURLs() {
        let recipeUrl = URL(string: "cooksy://recipe/abc")!
        let subUrl = URL(string: "cooksy://subscription")!
        let profileUrl = URL(string: "cooksy://profile")!

        XCTAssertTrue(service.handle(url: recipeUrl))
        XCTAssertTrue(service.handle(url: subUrl))
        XCTAssertTrue(service.handle(url: profileUrl))
    }

    func testHandleSameURLMultipleTimes() {
        let url = URL(string: "cooksy://recipe/abc")!
        for _ in 0..<5 {
            XCTAssertTrue(service.handle(url: url))
        }
    }

    // MARK: - Edge Case URL Tests

    func testHandleRecipeWithEmptyId() {
        let url = URL(string: "cooksy://recipe/")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleRecipeWithVeryLongId() {
        let longId = String(repeating: "a", count: 1000)
        let url = URL(string: "cooksy://recipe/\(longId)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleRecipeWithSpecialCharactersInId() {
        let id = "recipe-123_test.name"
        let url = URL(string: "cooksy://recipe/\(id)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleImportWithURLEncodedCharacters() {
        let videoUrl = "https://example.com?a=1&b=2#section"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }

    func testHandleImportWithQueryParamsInVideoUrl() {
        let videoUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PL&index=1"
        let encodedUrl = videoUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "cooksy://import?url=\(encodedUrl)")!
        let handled = service.handle(url: url)
        XCTAssertTrue(handled)
    }
}
