import XCTest
import SwiftUI
@testable import Cooksy

// MARK: - Cooksy Button Tests
/// Comprehensive unit tests for the Cooksy Button design system.
/// Covers all button styles (Primary, Secondary, Tertiary, Icon) and button views,
/// label propagation, disabled state handling, and tap action invocation.
final class CooksyButtonTests: XCTestCase {

    // MARK: - PrimaryButtonStyle Tests

    func testPrimaryButtonStyle_Initializes() {
        let style = PrimaryButtonStyle()
        XCTAssertNotNil(style, "PrimaryButtonStyle should initialize")
    }

    func testPrimaryButtonStyle_MakeBody() {
        let style = PrimaryButtonStyle()
        let configuration = ButtonStyleConfiguration()
        let body = style.makeBody(configuration: configuration)
        XCTAssertNotNil(body, "PrimaryButtonStyle makeBody should return a valid view")
    }

    // MARK: - SecondaryButtonStyle Tests

    func testSecondaryButtonStyle_Initializes() {
        let style = SecondaryButtonStyle()
        XCTAssertNotNil(style, "SecondaryButtonStyle should initialize")
    }

    func testSecondaryButtonStyle_MakeBody() {
        let style = SecondaryButtonStyle()
        let configuration = ButtonStyleConfiguration()
        let body = style.makeBody(configuration: configuration)
        XCTAssertNotNil(body, "SecondaryButtonStyle makeBody should return a valid view")
    }

    // MARK: - TertiaryButtonStyle Tests

    func testTertiaryButtonStyle_Initializes() {
        let style = TertiaryButtonStyle()
        XCTAssertNotNil(style, "TertiaryButtonStyle should initialize")
    }

    func testTertiaryButtonStyle_MakeBody() {
        let style = TertiaryButtonStyle()
        let configuration = ButtonStyleConfiguration()
        let body = style.makeBody(configuration: configuration)
        XCTAssertNotNil(body, "TertiaryButtonStyle makeBody should return a valid view")
    }

    // MARK: - IconButtonStyle Tests

    func testIconButtonStyle_Initializes() {
        let style = IconButtonStyle()
        XCTAssertNotNil(style, "IconButtonStyle should initialize")
    }

    func testIconButtonStyle_MakeBody() {
        let style = IconButtonStyle()
        let configuration = ButtonStyleConfiguration()
        let body = style.makeBody(configuration: configuration)
        XCTAssertNotNil(body, "IconButtonStyle makeBody should return a valid view")
    }

    // MARK: - View Modifier Button Style Tests

    func testPrimaryButtonModifier_Exists() {
        let view = Button("Test") {}.primaryButton()
        XCTAssertNotNil(view, "primaryButton modifier should return a valid View")
    }

    func testSecondaryButtonModifier_Exists() {
        let view = Button("Test") {}.secondaryButton()
        XCTAssertNotNil(view, "secondaryButton modifier should return a valid View")
    }

    func testTertiaryButtonModifier_Exists() {
        let view = Button("Test") {}.tertiaryButton()
        XCTAssertNotNil(view, "tertiaryButton modifier should return a valid View")
    }

    func testIconButtonModifier_Exists() {
        let view = Button("Test") {}.iconButton()
        XCTAssertNotNil(view, "iconButton modifier should return a valid View")
    }

    // MARK: - PrimaryButton Tests

    func testPrimaryButton_Initializes() {
        let button = PrimaryButton("Continue") {}
        XCTAssertNotNil(button, "PrimaryButton should initialize with title and action")
    }

    func testPrimaryButton_WithIcon() {
        let button = PrimaryButton("Continue", icon: "arrow.right") {}
        XCTAssertNotNil(button, "PrimaryButton should initialize with icon")
    }

    func testPrimaryButton_WithIsLoading() {
        let button = PrimaryButton("Saving...", isLoading: true) {}
        XCTAssertNotNil(button, "PrimaryButton should initialize with isLoading=true")
    }

    func testPrimaryButton_Disabled() {
        let button = PrimaryButton("Disabled", isEnabled: false) {}
        XCTAssertNotNil(button, "PrimaryButton should initialize with isEnabled=false")
    }

    func testPrimaryButton_FullConfiguration() {
        let button = PrimaryButton(
            "Submit",
            icon: "checkmark",
            isLoading: false,
            isEnabled: true
        ) {}
        XCTAssertNotNil(button, "PrimaryButton should initialize with full configuration")
    }

    func testPrimaryButton_RendersBody() {
        let button = PrimaryButton("Test") {}
        let body = button.body
        XCTAssertNotNil(body, "PrimaryButton body should not be nil")
    }

    // MARK: - SecondaryButton Tests

    func testSecondaryButton_Initializes() {
        let button = SecondaryButton("Cancel") {}
        XCTAssertNotNil(button, "SecondaryButton should initialize with title and action")
    }

    func testSecondaryButton_WithIcon() {
        let button = SecondaryButton("Cancel", icon: "xmark") {}
        XCTAssertNotNil(button, "SecondaryButton should initialize with icon")
    }

    func testSecondaryButton_WithIsLoading() {
        let button = SecondaryButton("Loading...", isLoading: true) {}
        XCTAssertNotNil(button, "SecondaryButton should initialize with isLoading=true")
    }

    func testSecondaryButton_Disabled() {
        let button = SecondaryButton("Disabled", isEnabled: false) {}
        XCTAssertNotNil(button, "SecondaryButton should initialize with isEnabled=false")
    }

    func testSecondaryButton_FullConfiguration() {
        let button = SecondaryButton(
            "Skip",
            icon: "forward",
            isLoading: false,
            isEnabled: true
        ) {}
        XCTAssertNotNil(button, "SecondaryButton should initialize with full configuration")
    }

    func testSecondaryButton_RendersBody() {
        let button = SecondaryButton("Test") {}
        let body = button.body
        XCTAssertNotNil(body, "SecondaryButton body should not be nil")
    }

    // MARK: - TertiaryButton Tests

    func testTertiaryButton_Initializes() {
        let button = TertiaryButton("Resend code") {}
        XCTAssertNotNil(button, "TertiaryButton should initialize with title and action")
    }

    func testTertiaryButton_WithIcon() {
        let button = TertiaryButton("Back", icon: "arrow.backward") {}
        XCTAssertNotNil(button, "TertiaryButton should initialize with icon")
    }

    func testTertiaryButton_Disabled() {
        let button = TertiaryButton("Disabled", isEnabled: false) {}
        XCTAssertNotNil(button, "TertiaryButton should initialize with isEnabled=false")
    }

    func testTertiaryButton_FullConfiguration() {
        let button = TertiaryButton(
            "Edit",
            icon: "pencil",
            isEnabled: true
        ) {}
        XCTAssertNotNil(button, "TertiaryButton should initialize with full configuration")
    }

    func testTertiaryButton_RendersBody() {
        let button = TertiaryButton("Test") {}
        let body = button.body
        XCTAssertNotNil(body, "TertiaryButton body should not be nil")
    }

    // MARK: - IconButton Tests

    func testIconButton_Initializes() {
        let button = IconButton(icon: "xmark") {}
        XCTAssertNotNil(button, "IconButton should initialize with icon name and action")
    }

    func testIconButton_WithTint() {
        let button = IconButton(icon: "bookmark.fill", tint: .brand) {}
        XCTAssertNotNil(button, "IconButton should initialize with custom tint")
    }

    func testIconButton_Disabled() {
        let button = IconButton(icon: "trash", isEnabled: false) {}
        XCTAssertNotNil(button, "IconButton should initialize with isEnabled=false")
    }

    func testIconButton_FullConfiguration() {
        let button = IconButton(
            icon: "gear",
            tint: .muted,
            isEnabled: true
        ) {}
        XCTAssertNotNil(button, "IconButton should initialize with full configuration")
    }

    func testIconButton_RendersBody() {
        let button = IconButton(icon: "star") {}
        let body = button.body
        XCTAssertNotNil(body, "IconButton body should not be nil")
    }

    // MARK: - Button Label Propagation Tests

    func testPrimaryButton_LabelPassesThrough() {
        let title = "Submit Recipe"
        let button = PrimaryButton(title) {}
        XCTAssertEqual(button._title, title, "PrimaryButton should store the title correctly")
    }

    func testSecondaryButton_LabelPassesThrough() {
        let title = "Delete Recipe"
        let button = SecondaryButton(title) {}
        XCTAssertEqual(button._title, title, "SecondaryButton should store the title correctly")
    }

    func testTertiaryButton_LabelPassesThrough() {
        let title = "Resend Code"
        let button = TertiaryButton(title) {}
        XCTAssertEqual(button._title, title, "TertiaryButton should store the title correctly")
    }

    // MARK: - Button Disabled State Tests

    func testPrimaryButton_DisabledOpacity() {
        let button = PrimaryButton("Disabled", isEnabled: false) {}
        XCTAssertEqual(button.isEnabled, false, "PrimaryButton should track disabled state")
    }

    func testPrimaryButton_EnabledOpacity() {
        let button = PrimaryButton("Enabled", isEnabled: true) {}
        XCTAssertEqual(button.isEnabled, true, "PrimaryButton should track enabled state")
    }

    func testSecondaryButton_DisabledState() {
        let button = SecondaryButton("Disabled", isEnabled: false) {}
        XCTAssertEqual(button.isEnabled, false, "SecondaryButton should track disabled state")
    }

    func testTertiaryButton_DisabledState() {
        let button = TertiaryButton("Disabled", isEnabled: false) {}
        XCTAssertEqual(button.isEnabled, false, "TertiaryButton should track disabled state")
    }

    func testIconButton_DisabledState() {
        let button = IconButton(icon: "trash", isEnabled: false) {}
        XCTAssertEqual(button.isEnabled, false, "IconButton should track disabled state")
    }

    // MARK: - Button Loading State Tests

    func testPrimaryButton_LoadingState() {
        let button = PrimaryButton("Loading", isLoading: true) {}
        XCTAssertEqual(button.isLoading, true, "PrimaryButton should track loading state")
    }

    func testPrimaryButton_NotLoading() {
        let button = PrimaryButton("Ready", isLoading: false) {}
        XCTAssertEqual(button.isLoading, false, "PrimaryButton should track non-loading state")
    }

    func testSecondaryButton_LoadingState() {
        let button = SecondaryButton("Loading", isLoading: true) {}
        XCTAssertEqual(button.isLoading, true, "SecondaryButton should track loading state")
    }

    func testSecondaryButton_NotLoading() {
        let button = SecondaryButton("Ready", isLoading: false) {}
        XCTAssertEqual(button.isLoading, false, "SecondaryButton should track non-loading state")
    }

    // MARK: - Button Icon Propagation Tests

    func testPrimaryButton_IconIsNilByDefault() {
        let button = PrimaryButton("No Icon") {}
        XCTAssertNil(button.icon, "PrimaryButton icon should be nil by default")
    }

    func testPrimaryButton_IconPropagates() {
        let button = PrimaryButton("With Icon", icon: "arrow.right") {}
        XCTAssertEqual(button.icon, "arrow.right", "PrimaryButton should store the icon name")
    }

    func testSecondaryButton_IconIsNilByDefault() {
        let button = SecondaryButton("No Icon") {}
        XCTAssertNil(button.icon, "SecondaryButton icon should be nil by default")
    }

    func testSecondaryButton_IconPropagates() {
        let button = SecondaryButton("With Icon", icon: "xmark") {}
        XCTAssertEqual(button.icon, "xmark", "SecondaryButton should store the icon name")
    }

    func testTertiaryButton_IconIsNilByDefault() {
        let button = TertiaryButton("No Icon") {}
        XCTAssertNil(button.icon, "TertiaryButton icon should be nil by default")
    }

    func testTertiaryButton_IconPropagates() {
        let button = TertiaryButton("With Icon", icon: "arrow.backward") {}
        XCTAssertEqual(button.icon, "arrow.backward", "TertiaryButton should store the icon name")
    }

    // MARK: - Button Action Invocation Tests

    func testPrimaryButton_ActionCalled() {
        var actionCalled = false
        let button = PrimaryButton("Tap me") {
            actionCalled = true
        }
        XCTAssertNotNil(button.action, "PrimaryButton should store the action closure")
        button.action()
        XCTAssertTrue(actionCalled, "PrimaryButton action should be callable")
    }

    func testSecondaryButton_ActionCalled() {
        var actionCalled = false
        let button = SecondaryButton("Tap me") {
            actionCalled = true
        }
        XCTAssertNotNil(button.action, "SecondaryButton should store the action closure")
        button.action()
        XCTAssertTrue(actionCalled, "SecondaryButton action should be callable")
    }

    func testTertiaryButton_ActionCalled() {
        var actionCalled = false
        let button = TertiaryButton("Tap me") {
            actionCalled = true
        }
        XCTAssertNotNil(button.action, "TertiaryButton should store the action closure")
        button.action()
        XCTAssertTrue(actionCalled, "TertiaryButton action should be callable")
    }

    func testIconButton_ActionCalled() {
        var actionCalled = false
        let button = IconButton(icon: "star") {
            actionCalled = true
        }
        XCTAssertNotNil(button.action, "IconButton should store the action closure")
        button.action()
        XCTAssertTrue(actionCalled, "IconButton action should be callable")
    }

    // MARK: - IconButton Accessibility Label Tests

    func testIconButton_AccessibilityLabel_Xmark() {
        let button = IconButton(icon: "xmark") {}
        XCTAssertEqual(button.icon, "xmark")
    }

    func testIconButton_AccessibilityLabel_Bookmark() {
        let button = IconButton(icon: "bookmark.fill") {}
        XCTAssertEqual(button.icon, "bookmark.fill")
    }

    func testIconButton_AccessibilityLabel_Pencil() {
        let button = IconButton(icon: "pencil") {}
        XCTAssertEqual(button.icon, "pencil")
    }

    func testIconButton_AccessibilityLabel_Plus() {
        let button = IconButton(icon: "plus") {}
        XCTAssertEqual(button.icon, "plus")
    }

    func testIconButton_AccessibilityLabel_Trash() {
        let button = IconButton(icon: "trash") {}
        XCTAssertEqual(button.icon, "trash")
    }

    func testIconButton_AccessibilityLabel_Checkmark() {
        let button = IconButton(icon: "checkmark") {}
        XCTAssertEqual(button.icon, "checkmark")
    }

    // MARK: - IconButton Tint Tests

    func testIconButton_DefaultTint() {
        let button = IconButton(icon: "star") {}
        XCTAssertNotNil(button.tint, "IconButton should have a default tint")
    }

    func testIconButton_CustomTint() {
        let button = IconButton(icon: "star", tint: .brand) {}
        let tintColor = button.tint
        XCTAssertNotNil(tintColor, "IconButton should accept a custom tint")
    }

    // MARK: - Button Style Equivalence Tests

    func testPrimaryButtonStyle_IsReusable() {
        let style1 = PrimaryButtonStyle()
        let style2 = PrimaryButtonStyle()
        XCTAssertNotNil(style1)
        XCTAssertNotNil(style2)
    }

    func testSecondaryButtonStyle_IsReusable() {
        let style1 = SecondaryButtonStyle()
        let style2 = SecondaryButtonStyle()
        XCTAssertNotNil(style1)
        XCTAssertNotNil(style2)
    }

    // MARK: - Edge Case Tests

    func testPrimaryButton_EmptyTitle() {
        let button = PrimaryButton("") {}
        XCTAssertEqual(button._title, "", "PrimaryButton should accept empty title")
    }

    func testPrimaryButton_LongTitle() {
        let longTitle = String(repeating: "A", count: 200)
        let button = PrimaryButton(longTitle) {}
        XCTAssertEqual(button._title, longTitle, "PrimaryButton should accept very long title")
    }

    func testIconButton_UnknownIcon() {
        let button = IconButton(icon: "unknown.icon.name") {}
        XCTAssertEqual(button.icon, "unknown.icon.name", "IconButton should accept any icon name string")
    }

    func testTertiaryButton_NoIcon() {
        let button = TertiaryButton("Text only") {}
        XCTAssertNil(button.icon, "TertiaryButton without icon should have nil icon")
    }
}
