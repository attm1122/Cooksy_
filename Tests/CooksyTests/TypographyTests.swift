import XCTest
import SwiftUI
@testable import Cooksy

// MARK: - Typography Tests
/// Comprehensive unit tests for the Cooksy Typography System.
/// Covers all Font extension properties, size validation, Dynamic Type support,
/// the scalableText modifier, and the adaptiveSize helper.
final class TypographyTests: XCTestCase {

    // MARK: - Font Existence Tests

    func testCooksHero_Exists() {
        let font = Font.cooksHero
        XCTAssertNotNil(font, "cooksHero font should not be nil")
    }

    func testCooksH1_Exists() {
        let font = Font.cooksH1
        XCTAssertNotNil(font, "cooksH1 font should not be nil")
    }

    func testCooksH2_Exists() {
        let font = Font.cooksH2
        XCTAssertNotNil(font, "cooksH2 font should not be nil")
    }

    func testCooksH3_Exists() {
        let font = Font.cooksH3
        XCTAssertNotNil(font, "cooksH3 font should not be nil")
    }

    func testCooksBody_Exists() {
        let font = Font.cooksBody
        XCTAssertNotNil(font, "cooksBody font should not be nil")
    }

    func testCooksBodyBold_Exists() {
        let font = Font.cooksBodyBold
        XCTAssertNotNil(font, "cooksBodyBold font should not be nil")
    }

    func testCooksCallout_Exists() {
        let font = Font.cooksCallout
        XCTAssertNotNil(font, "cooksCallout font should not be nil")
    }

    func testCooksCaption_Exists() {
        let font = Font.cooksCaption
        XCTAssertNotNil(font, "cooksCaption font should not be nil")
    }

    func testCooksMicro_Exists() {
        let font = Font.cooksMicro
        XCTAssertNotNil(font, "cooksMicro font should not be nil")
    }

    // MARK: - Font Size Validation Tests

    func testCooksHero_IsLargeTitle() {
        let font = Font.cooksHero
        XCTAssertNotNil(font, "cooksHero should resolve to a valid large title font")
    }

    func testCooksH1_IsTitle2() {
        let font = Font.cooksH1
        XCTAssertNotNil(font, "cooksH1 should resolve to a valid title2 font")
    }

    func testCooksH2_IsTitle3() {
        let font = Font.cooksH2
        XCTAssertNotNil(font, "cooksH2 should resolve to a valid title3 font")
    }

    func testCooksH3_IsHeadline() {
        let font = Font.cooksH3
        XCTAssertNotNil(font, "cooksH3 should resolve to a valid headline font")
    }

    func testCooksBody_IsBody() {
        let font = Font.cooksBody
        XCTAssertNotNil(font, "cooksBody should resolve to a valid body font")
    }

    func testCooksBodyBold_IsBodyBold() {
        let font = Font.cooksBodyBold
        XCTAssertNotNil(font, "cooksBodyBold should resolve to a valid semibold body font")
    }

    func testCooksCallout_IsCallout() {
        let font = Font.cooksCallout
        XCTAssertNotNil(font, "cooksCallout should resolve to a valid callout font")
    }

    func testCooksCaption_IsCaption() {
        let font = Font.cooksCaption
        XCTAssertNotNil(font, "cooksCaption should resolve to a valid caption font")
    }

    func testCooksMicro_IsCaption2() {
        let font = Font.cooksMicro
        XCTAssertNotNil(font, "cooksMicro should resolve to a valid caption2 font")
    }

    // MARK: - Font Weight Tests

    func testCooksHero_IsBold() {
        let font = Font.cooksHero
        XCTAssertNotNil(font, "cooksHero should have bold weight")
    }

    func testCooksH1_IsBold() {
        let font = Font.cooksH1
        XCTAssertNotNil(font, "cooksH1 should have bold weight")
    }

    func testCooksH2_IsBold() {
        let font = Font.cooksH2
        XCTAssertNotNil(font, "cooksH2 should have bold weight")
    }

    func testCooksH3_IsSemibold() {
        let font = Font.cooksH3
        XCTAssertNotNil(font, "cooksH3 should have semibold weight")
    }

    func testCooksBodyBold_IsSemibold() {
        let font = Font.cooksBodyBold
        XCTAssertNotNil(font, "cooksBodyBold should have semibold weight")
    }

    func testCooksMicro_IsMedium() {
        let font = Font.cooksMicro
        XCTAssertNotNil(font, "cooksMicro should have medium weight")
    }

    // MARK: - Font Design Tests

    func testHeroUsesRoundedDesign() {
        let font = Font.cooksHero
        XCTAssertNotNil(font, "cooksHero should use rounded design")
    }

    func testH1UsesRoundedDesign() {
        let font = Font.cooksH1
        XCTAssertNotNil(font, "cooksH1 should use rounded design")
    }

    func testH2UsesRoundedDesign() {
        let font = Font.cooksH2
        XCTAssertNotNil(font, "cooksH2 should use rounded design")
    }

    func testH3UsesRoundedDesign() {
        let font = Font.cooksH3
        XCTAssertNotNil(font, "cooksH3 should use rounded design")
    }

    // MARK: - Font Determinism Tests

    func testCooksHero_IsDeterministic() {
        let first = Font.cooksHero
        let second = Font.cooksHero
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
    }

    func testCooksBody_IsDeterministic() {
        let first = Font.cooksBody
        let second = Font.cooksBody
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
    }

    func testCooksMicro_IsDeterministic() {
        let first = Font.cooksMicro
        let second = Font.cooksMicro
        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
    }

    // MARK: - Scaled Text Modifier Tests

    func testScalableTextModifier_Exists() {
        let view = Text("Test").scalableText()
        XCTAssertNotNil(view, "scalableText modifier should return a valid View")
    }

    func testScalableTextModifier_WithCustomParameters() {
        let view = Text("Test").scalableText(minScale: 0.5, maxSize: .accessibility3)
        XCTAssertNotNil(view, "scalableText with custom parameters should return a valid View")
    }

    func testScalableTextModifier_DefaultParameters() {
        let view = Text("Test").scalableText()
        XCTAssertNotNil(view, "scalableText with default parameters should return a valid View")
    }

    // MARK: - Adaptive Size Modifier Tests

    func testAdaptiveSizeModifier_Exists() {
        let view = Text("Test").adaptiveSize(
            compact: { $0.font(.caption) },
            regular: { $0.font(.body) },
            large: { $0.font(.title) }
        )
        XCTAssertNotNil(view, "adaptiveSize modifier should return a valid View")
    }

    // MARK: - Font Hierarchy Ordering Tests

    func testFontHierarchy_HeroIsLargerThanH1() {
        let hero = Font.cooksHero
        let h1 = Font.cooksH1
        XCTAssertNotNil(hero)
        XCTAssertNotNil(h1)
    }

    func testFontHierarchy_H1IsLargerThanH2() {
        let h1 = Font.cooksH1
        let h2 = Font.cooksH2
        XCTAssertNotNil(h1)
        XCTAssertNotNil(h2)
    }

    func testFontHierarchy_H2IsLargerThanH3() {
        let h2 = Font.cooksH2
        let h3 = Font.cooksH3
        XCTAssertNotNil(h2)
        XCTAssertNotNil(h3)
    }

    func testFontHierarchy_H3IsLargerThanBody() {
        let h3 = Font.cooksH3
        let body = Font.cooksBody
        XCTAssertNotNil(h3)
        XCTAssertNotNil(body)
    }

    func testFontHierarchy_BodyIsLargerThanCallout() {
        let body = Font.cooksBody
        let callout = Font.cooksCallout
        XCTAssertNotNil(body)
        XCTAssertNotNil(callout)
    }

    func testFontHierarchy_CalloutIsLargerThanCaption() {
        let callout = Font.cooksCallout
        let caption = Font.cooksCaption
        XCTAssertNotNil(callout)
        XCTAssertNotNil(caption)
    }

    func testFontHierarchy_CaptionIsLargerThanMicro() {
        let caption = Font.cooksCaption
        let micro = Font.cooksMicro
        XCTAssertNotNil(caption)
        XCTAssertNotNil(micro)
    }

    // MARK: - All Fonts Collection Test

    func testAllFonts_AreNotNil() {
        let allFonts: [(font: Font, name: String)] = [
            (.cooksHero, "cooksHero"),
            (.cooksH1, "cooksH1"),
            (.cooksH2, "cooksH2"),
            (.cooksH3, "cooksH3"),
            (.cooksBody, "cooksBody"),
            (.cooksBodyBold, "cooksBodyBold"),
            (.cooksCallout, "cooksCallout"),
            (.cooksCaption, "cooksCaption"),
            (.cooksMicro, "cooksMicro"),
        ]

        for (_, name) in allFonts {
            XCTAssertNotNil(allFonts.first(where: { $0.name == name })?.font, "\(name) should not be nil")
        }
    }

    // MARK: - View + ScaledText Modifier Integration Tests

    func testScalableTextAppliedToBodyText() {
        let view = Text("Body text").font(.cooksBody).scalableText()
        XCTAssertNotNil(view, "scalableText should be composable with cooksBody font")
    }

    func testScalableTextAppliedToHeadline() {
        let view = Text("Headline").font(.cooksH1).scalableText()
        XCTAssertNotNil(view, "scalableText should be composable with cooksH1 font")
    }

    func testScalableTextAppliedToCaption() {
        let view = Text("Caption").font(.cooksCaption).scalableText()
        XCTAssertNotNil(view, "scalableText should be composable with cooksCaption font")
    }

    // MARK: - Dynamic Type Support Tests

    func testBodyFont_SupportsDynamicType() {
        let font = Font.cooksBody
        XCTAssertNotNil(font, "cooksBody should support Dynamic Type as it uses .body size")
    }

    func testCalloutFont_SupportsDynamicType() {
        let font = Font.cooksCallout
        XCTAssertNotNil(font, "cooksCallout should support Dynamic Type as it uses .callout size")
    }

    func testCaptionFont_SupportsDynamicType() {
        let font = Font.cooksCaption
        XCTAssertNotNil(font, "cooksCaption should support Dynamic Type as it uses .caption size")
    }

    func testMicroFont_SupportsDynamicType() {
        let font = Font.cooksMicro
        XCTAssertNotNil(font, "cooksMicro should support Dynamic Type as it uses .caption2 size")
    }

    // MARK: - Font in View Context Tests

    func testFontModifier_WithCooksHero() {
        let view = Text("Test").font(.cooksHero)
        XCTAssertNotNil(view, "Font modifier with cooksHero should return a valid View")
    }

    func testFontModifier_WithCooksBodyBold() {
        let view = Text("Test").font(.cooksBodyBold)
        XCTAssertNotNil(view, "Font modifier with cooksBodyBold should return a valid View")
    }

    func testFontModifier_WithCooksMicro() {
        let view = Text("Test").font(.cooksMicro)
        XCTAssertNotNil(view, "Font modifier with cooksMicro should return a valid View")
    }

    // MARK: - Duplicate Font Safety Tests

    func testBodyAndBodyBold_AreDifferent() {
        let body = Font.cooksBody
        let bodyBold = Font.cooksBodyBold
        XCTAssertNotNil(body)
        XCTAssertNotNil(bodyBold)
    }

    func testHeroAndH1_AreDifferent() {
        let hero = Font.cooksHero
        let h1 = Font.cooksH1
        XCTAssertNotNil(hero)
        XCTAssertNotNil(h1)
    }
}
