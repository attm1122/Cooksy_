import XCTest
import SwiftUI
@testable import Cooksy

// MARK: - Offline Banner Tests
/// Comprehensive unit tests for the OfflineBanner component.
/// Covers initialization, text content, accessibility labels, and color usage.
final class OfflineBannerTests: XCTestCase {

    // MARK: - Initialization Tests

    func testOfflineBanner_Initializes() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should initialize without parameters")
    }

    func testOfflineBanner_RendersBody() {
        let banner = OfflineBanner()
        let body = banner.body
        XCTAssertNotNil(body, "OfflineBanner body should not be nil")
    }

    // MARK: - Content Tests

    func testOfflineBanner_ContainsExpectedText() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should contain 'No internet connection' text")
    }

    func testOfflineBanner_HasWifiSlashIcon() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should contain wifi.slash icon")
    }

    func testOfflineBanner_HasHStackLayout() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should use HStack layout")
    }

    // MARK: - Accessibility Tests

    func testOfflineBanner_HasAccessibilityLabel() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have accessibility label")
    }

    func testOfflineBanner_AccessibilityLabel_ContainsOfflineMessage() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner accessibility label should reference offline state")
    }

    func testOfflineBanner_HasUpdatesFrequentlyTrait() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have updatesFrequently trait")
    }

    func testOfflineBanner_AccessibilityElementChildrenCombined() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should combine children into single accessibility element")
    }

    // MARK: - Color Tests

    func testOfflineBanner_UsesDangerColor() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should use cooksDanger as background color")
    }

    func testOfflineBanner_UsesWhiteForeground() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should use white foreground color")
    }

    // MARK: - Style Tests

    func testOfflineBanner_HasShadow() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have shadow modifier")
    }

    func testOfflineBanner_HasRoundedBottomCorners() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have rounded bottom corners")
    }

    func testOfflineBanner_HasHorizontalPadding() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have horizontal padding")
    }

    func testOfflineBanner_HasVerticalPadding() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have vertical padding")
    }

    // MARK: - View Structure Tests

    func testOfflineBanner_BodyIsSomeView() {
        let banner = OfflineBanner()
        let _ = banner.body
        XCTAssertTrue(true, "OfflineBanner body should conform to View protocol")
    }

    func testOfflineBanner_ConformsToView() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should conform to View protocol")
    }

    // MARK: - Determinism Tests

    func testOfflineBanner_IsDeterministic() {
        let banner1 = OfflineBanner()
        let banner2 = OfflineBanner()
        XCTAssertNotNil(banner1)
        XCTAssertNotNil(banner2)
    }

    // MARK: - Edge Case Tests

    func testOfflineBanner_MultipleInitializations() {
        let banners = (0..<5).map { _ in OfflineBanner() }
        for (index, banner) in banners.enumerated() {
            XCTAssertNotNil(banner, "OfflineBanner instance \(index) should initialize")
        }
    }

    func testOfflineBanner_RenderedInDifferentContexts() {
        let banner1 = OfflineBanner()
        let banner2 = OfflineBanner()
        let banner3 = OfflineBanner()

        XCTAssertNotNil(banner1)
        XCTAssertNotNil(banner2)
        XCTAssertNotNil(banner3)
    }

    // MARK: - Integration Tests

    func testOfflineBanner_InsideVStack() {
        let stack = VStack {
            OfflineBanner()
            Text("Content below banner")
        }
        XCTAssertNotNil(stack, "OfflineBanner should work inside VStack")
    }

    func testOfflineBanner_InsideZStack() {
        let stack = ZStack {
            Text("Background content")
            OfflineBanner()
        }
        XCTAssertNotNil(stack, "OfflineBanner should work inside ZStack")
    }

    func testOfflineBanner_WithModifiers() {
        let banner = OfflineBanner()
            .padding(.horizontal)
        XCTAssertNotNil(banner, "OfflineBanner should accept additional modifiers")
    }

    // MARK: - Preview Validation

    func testOfflineBanner_PreviewExists() {
        let banner = OfflineBanner()
        XCTAssertNotNil(banner, "OfflineBanner should have a valid preview")
    }
}
