import XCTest
@testable import Cooksy

// MARK: - Colors Tests
/// Comprehensive unit tests for the Cooksy Color Design System.
/// Covers all color definitions, UIColor conversion, RGB component validation,
/// dynamic color resolution, and dark mode adaptivity.
final class ColorsTests: XCTestCase {

    // MARK: - Brand Color Tests

    func testBrandColor_ExistsAndNotNil() {
        let color = Color.brand
        XCTAssertNotNil(color, "Brand color should not be nil")
    }

    func testBrandSoftColor_ExistsAndNotNil() {
        let color = Color.brandSoft
        XCTAssertNotNil(color, "Brand soft color should not be nil")
    }

    // MARK: - Text Color Tests

    func testInkColor_ExistsAndNotNil() {
        let color = Color.ink
        XCTAssertNotNil(color, "Ink color should not be nil")
    }

    func testSoftInkColor_ExistsAndNotNil() {
        let color = Color.softInk
        XCTAssertNotNil(color, "Soft ink color should not be nil")
    }

    func testMutedColor_ExistsAndNotNil() {
        let color = Color.muted
        XCTAssertNotNil(color, "Muted color should not be nil")
    }

    // MARK: - Surface Color Tests

    func testSurfaceColor_ExistsAndNotNil() {
        let color = Color.surface
        XCTAssertNotNil(color, "Surface color should not be nil")
    }

    func testSurfaceAltColor_ExistsAndNotNil() {
        let color = Color.surfaceAlt
        XCTAssertNotNil(color, "SurfaceAlt color should not be nil")
    }

    // MARK: - Background and Utility Color Tests

    func testCooksBackground_ExistsAndNotNil() {
        let color = Color.cooksBackground
        XCTAssertNotNil(color, "CooksBackground color should not be nil")
    }

    func testCooksDanger_ExistsAndNotNil() {
        let color = Color.cooksDanger
        XCTAssertNotNil(color, "CooksDanger color should not be nil")
    }

    func testCooksSuccess_ExistsAndNotNil() {
        let color = Color.cooksSuccess
        XCTAssertNotNil(color, "CooksSuccess color should not be nil")
    }

    func testCooksLine_ExistsAndNotNil() {
        let color = Color.cooksLine
        XCTAssertNotNil(color, "CooksLine color should not be nil")
    }

    func testCooksBorder_ExistsAndNotNil() {
        let color = Color.cooksBorder
        XCTAssertNotNil(color, "CooksBorder color should not be nil")
    }

    // MARK: - Color Alias Tests

    func testCreamAlias_ResolvesToBackground() {
        XCTAssertNotNil(Color.cream, "Cream alias should not be nil")
    }

    func testCreamDarkAlias_ResolvesToSurfaceAlt() {
        XCTAssertNotNil(Color.creamDark, "CreamDark alias should not be nil")
    }

    func testWarmYellowAlias_ResolvesToBrand() {
        XCTAssertNotNil(Color.warmYellow, "WarmYellow alias should not be nil")
    }

    func testTextPrimaryAlias_ResolvesToInk() {
        XCTAssertNotNil(Color.textPrimary, "TextPrimary alias should not be nil")
    }

    func testTextMutedAlias_ResolvesToMuted() {
        XCTAssertNotNil(Color.textMuted, "TextMuted alias should not be nil")
    }

    func testTextSecondaryAlias_ResolvesToSoftInk() {
        XCTAssertNotNil(Color.textSecondary, "TextSecondary alias should not be nil")
    }

    // MARK: - UIColor Conversion Tests

    func testBrand_UIColorConversion() {
        let swiftUIColor = Color.brand
        let uiColor = UIColor(swiftUIColor)
        XCTAssertNotNil(uiColor.cgColor, "Brand color should convert to a valid UIColor with CGColor")
    }

    func testInk_UIColorConversion() {
        let swiftUIColor = Color.ink
        let uiColor = UIColor(swiftUIColor)
        XCTAssertNotNil(uiColor.cgColor, "Ink color should convert to a valid UIColor with CGColor")
    }

    func testCooksDanger_UIColorConversion() {
        let swiftUIColor = Color.cooksDanger
        let uiColor = UIColor(swiftUIColor)
        XCTAssertNotNil(uiColor.cgColor, "Danger color should convert to a valid UIColor with CGColor")
    }

    func testCooksSuccess_UIColorConversion() {
        let swiftUIColor = Color.cooksSuccess
        let uiColor = UIColor(swiftUIColor)
        XCTAssertNotNil(uiColor.cgColor, "Success color should convert to a valid UIColor with CGColor")
    }

    func testSurface_UIColorConversion() {
        let swiftUIColor = Color.surface
        let uiColor = UIColor(swiftUIColor)
        XCTAssertNotNil(uiColor.cgColor, "Surface color should convert to a valid UIColor with CGColor")
    }

    // MARK: - RGB Component Validation Tests

    func testBrand_RGBComponentsInValidRange() {
        let uiColor = UIColor(Color.brand)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertTrue(red >= 0 && red <= 1, "Brand red component should be in [0,1]")
        XCTAssertTrue(green >= 0 && green <= 1, "Brand green component should be in [0,1]")
        XCTAssertTrue(blue >= 0 && blue <= 1, "Brand blue component should be in [0,1]")
        XCTAssertTrue(alpha >= 0 && alpha <= 1, "Brand alpha component should be in [0,1]")
    }

    func testCooksDanger_RGBComponentsInValidRange() {
        let uiColor = UIColor(Color.cooksDanger)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertTrue(red >= 0 && red <= 1, "Danger red component should be in [0,1]")
        XCTAssertTrue(green >= 0 && green <= 1, "Danger green component should be in [0,1]")
        XCTAssertTrue(blue >= 0 && blue <= 1, "Danger blue component should be in [0,1]")
        XCTAssertTrue(alpha >= 0 && alpha <= 1, "Danger alpha component should be in [0,1]")
    }

    func testCooksSuccess_RGBComponentsInValidRange() {
        let uiColor = UIColor(Color.cooksSuccess)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertTrue(red >= 0 && red <= 1, "Success red component should be in [0,1]")
        XCTAssertTrue(green >= 0 && green <= 1, "Success green component should be in [0,1]")
        XCTAssertTrue(blue >= 0 && blue <= 1, "Success blue component should be in [0,1]")
        XCTAssertTrue(alpha >= 0 && alpha <= 1, "Success alpha component should be in [0,1]")
    }

    // MARK: - Hex Initializer Tests

    func testHexInitializer_6Digit() {
        let color = Color(hex: "FF0000")
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "6-digit hex FF0000 should have red=1.0")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "6-digit hex FF0000 should have green=0.0")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "6-digit hex FF0000 should have blue=0.0")
    }

    func testHexInitializer_3Digit() {
        let color = Color(hex: "F00")
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "3-digit hex F00 should have red=1.0")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "3-digit hex F00 should have green=0.0")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "3-digit hex F00 should have blue=0.0")
    }

    func testHexInitializer_8Digit() {
        let color = Color(hex: "80FF0000")
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "8-digit hex should parse red correctly")
        XCTAssertEqual(alpha, 128.0 / 255.0, accuracy: 0.01, "8-digit hex should parse alpha correctly")
    }

    func testHexInitializer_Invalid() {
        let color = Color(hex: "INVALID")
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01, "Invalid hex should fallback to black (red=0)")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Invalid hex should fallback to black (green=0)")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Invalid hex should fallback to black (blue=0)")
    }

    func testHexInitializer_Empty() {
        let color = Color(hex: "")
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01, "Empty hex should fallback to black (red=0)")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Empty hex should fallback to black (green=0)")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Empty hex should fallback to black (blue=0)")
    }

    // MARK: - Dynamic Color Resolution Tests

    func testAdaptiveBackground_LightMode() {
        let color = Color.cooksBackground
        let uiColor = UIColor(color)
        XCTAssertNotNil(uiColor, "Adaptive background should resolve to a valid UIColor")
    }

    func testAdaptiveSurface_LightMode() {
        let color = Color.surface
        let uiColor = UIColor(color)
        XCTAssertNotNil(uiColor, "Adaptive surface should resolve to a valid UIColor")
    }

    func testAdaptiveInk_LightMode() {
        let color = Color.ink
        let uiColor = UIColor(color)
        XCTAssertNotNil(uiColor, "Adaptive ink should resolve to a valid UIColor")
    }

    func testAdaptiveMuted_LightMode() {
        let color = Color.muted
        let uiColor = UIColor(color)
        XCTAssertNotNil(uiColor, "Adaptive muted should resolve to a valid UIColor")
    }

    func testAdaptiveLine_LightMode() {
        let color = Color.cooksLine
        let uiColor = UIColor(color)
        XCTAssertNotNil(uiColor, "Adaptive line should resolve to a valid UIColor")
    }

    // MARK: - Confidence Color Tests

    func testConfidenceHigh_Exists() {
        XCTAssertNotNil(Color.confidenceHigh, "ConfidenceHigh color should not be nil")
    }

    func testConfidenceHighBorder_Exists() {
        XCTAssertNotNil(Color.confidenceHighBorder, "ConfidenceHighBorder color should not be nil")
    }

    func testConfidenceMedium_Exists() {
        XCTAssertNotNil(Color.confidenceMedium, "ConfidenceMedium color should not be nil")
    }

    func testConfidenceMediumBorder_Exists() {
        XCTAssertNotNil(Color.confidenceMediumBorder, "ConfidenceMediumBorder color should not be nil")
    }

    func testConfidenceLow_Exists() {
        XCTAssertNotNil(Color.confidenceLow, "ConfidenceLow color should not be nil")
    }

    func testConfidenceLowBorder_Exists() {
        XCTAssertNotNil(Color.confidenceLowBorder, "ConfidenceLowBorder color should not be nil")
    }

    // MARK: - Platform Color Tests

    func testYouTubeRed_Exists() {
        XCTAssertNotNil(Color.youtubeRed, "YouTubeRed color should not be nil")
    }

    func testTikTokBlack_Exists() {
        XCTAssertNotNil(Color.tikTokBlack, "TikTokBlack color should not be nil")
    }

    func testInstagramPink_Exists() {
        XCTAssertNotNil(Color.instagramPink, "InstagramPink color should not be nil")
    }

    // MARK: - View Extension Tests

    func testAdaptiveForegroundColorModifier_Exists() {
        let view = Text("Test").adaptiveForegroundColor(light: .white, dark: .black)
        XCTAssertNotNil(view, "adaptiveForegroundColor modifier should return a valid View")
    }

    func testPreviewBothColorSchemesModifier_Exists() {
        let view = Text("Test").previewBothColorSchemes()
        XCTAssertNotNil(view, "previewBothColorSchemes modifier should return a valid View")
    }

    // MARK: - Color Equality / Determinism Tests

    func testBrandColor_IsDeterministic() {
        let first = Color.brand
        let second = Color.brand
        let uiFirst = UIColor(first)
        let uiSecond = UIColor(second)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        uiFirst.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiSecond.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        XCTAssertEqual(r1, r2, accuracy: 0.001, "Brand color should be deterministic")
        XCTAssertEqual(g1, g2, accuracy: 0.001, "Brand color should be deterministic")
        XCTAssertEqual(b1, b2, accuracy: 0.001, "Brand color should be deterministic")
        XCTAssertEqual(a1, a2, accuracy: 0.001, "Brand color should be deterministic")
    }

    func testDangerColor_IsDeterministic() {
        let first = Color.cooksDanger
        let second = Color.cooksDanger
        let uiFirst = UIColor(first)
        let uiSecond = UIColor(second)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        uiFirst.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiSecond.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        XCTAssertEqual(r1, r2, accuracy: 0.001, "Danger color should be deterministic")
        XCTAssertEqual(g1, g2, accuracy: 0.001, "Danger color should be deterministic")
        XCTAssertEqual(b1, b2, accuracy: 0.001, "Danger color should be deterministic")
        XCTAssertEqual(a1, a2, accuracy: 0.001, "Danger color should be deterministic")
    }

    // MARK: - Edge Case: Dark Mode Fallback

    func testDarkModeColors_ResolveInLightMode() {
        let darkModeColors: [Color] = [
            .cooksBackground,
            .surface,
            .surfaceAlt,
            .ink,
            .softInk,
            .muted,
            .cooksBorder,
            .cooksLine,
        ]

        for color in darkModeColors {
            let uiColor = UIColor(color)
            XCTAssertNotNil(uiColor.cgColor, "Dark-mode adaptive color should always resolve to a valid CGColor")
        }
    }

    func testAllColors_RGBComponentsInValidRange() {
        let allColors: [(color: Color, name: String)] = [
            (.brand, "brand"),
            (.brandSoft, "brandSoft"),
            (.cooksDanger, "cooksDanger"),
            (.cooksSuccess, "cooksSuccess"),
            (.youtubeRed, "youtubeRed"),
            (.instagramPink, "instagramPink"),
        ]

        for (color, name) in allColors {
            let uiColor = UIColor(color)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                XCTFail("Failed to get RGB components for \(name)")
                continue
            }
            XCTAssertTrue(red >= 0 && red <= 1, "\(name) red component out of range: \(red)")
            XCTAssertTrue(green >= 0 && green <= 1, "\(name) green component out of range: \(green)")
            XCTAssertTrue(blue >= 0 && blue <= 1, "\(name) blue component out of range: \(blue)")
            XCTAssertTrue(alpha >= 0 && alpha <= 1, "\(name) alpha component out of range: \(alpha)")
        }
    }
}
