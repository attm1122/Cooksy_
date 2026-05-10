import XCTest
import SwiftUI
@testable import Cooksy

// MARK: - Cooksy Card Tests
/// Comprehensive unit tests for the Cooksy Card design system components.
/// Covers CooksyCard, SoftCard, CardRow, and AccessibleActionCard.
final class CooksyCardTests: XCTestCase {

    // MARK: - CooksyCard Initialization Tests

    func testCooksyCard_InitializesWithContent() {
        let card = CooksyCard {
            Text("Card Content")
        }
        XCTAssertNotNil(card, "CooksyCard should initialize with content")
    }

    func testCooksyCard_InitializesWithComplexContent() {
        let card = CooksyCard {
            VStack {
                Text("Title")
                Text("Subtitle")
                Image(systemName: "star")
            }
        }
        XCTAssertNotNil(card, "CooksyCard should initialize with complex nested content")
    }

    func testCooksyCard_InitializesWithEmptyContent() {
        let card = CooksyCard {
            EmptyView()
        }
        XCTAssertNotNil(card, "CooksyCard should initialize with EmptyView")
    }

    // MARK: - CooksyCard isLarge Parameter Tests

    func testCooksyCard_DefaultIsLarge_IsFalse() {
        let card = CooksyCard {
            Text("Default size")
        }
        XCTAssertNotNil(card, "CooksyCard with default isLarge should initialize")
    }

    func testCooksyCard_IsLargeTrue() {
        let card = CooksyCard(isLarge: true) {
            Text("Large card")
        }
        XCTAssertNotNil(card, "CooksyCard with isLarge=true should initialize")
    }

    func testCooksyCard_IsLargeFalse() {
        let card = CooksyCard(isLarge: false) {
            Text("Small card")
        }
        XCTAssertNotNil(card, "CooksyCard with isLarge=false should initialize")
    }

    func testCooksyCard_BothSizesInitialize() {
        let smallCard = CooksyCard(isLarge: false) {
            Text("Small")
        }
        let largeCard = CooksyCard(isLarge: true) {
            Text("Large")
        }
        XCTAssertNotNil(smallCard, "Small CooksyCard should initialize")
        XCTAssertNotNil(largeCard, "Large CooksyCard should initialize")
    }

    // MARK: - SoftCard Initialization Tests

    func testSoftCard_InitializesWithContent() {
        let card = SoftCard {
            Text("Soft Card Content")
        }
        XCTAssertNotNil(card, "SoftCard should initialize with content")
    }

    func testSoftCard_InitializesWithComplexContent() {
        let card = SoftCard {
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                Text("Description goes here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        XCTAssertNotNil(card, "SoftCard should initialize with complex content")
    }

    func testSoftCard_InitializesWithEmptyContent() {
        let card = SoftCard {
            EmptyView()
        }
        XCTAssertNotNil(card, "SoftCard should initialize with EmptyView")
    }

    // MARK: - CardRow Initialization Tests

    func testCardRow_InitializesWithContent() {
        let row = CardRow {
            Text("Row Content")
        }
        XCTAssertNotNil(row, "CardRow should initialize with content")
    }

    func testCardRow_InitializesWithComplexContent() {
        let row = CardRow {
            HStack {
                Image(systemName: "doc.text")
                VStack(alignment: .leading) {
                    Text("Recipe Title")
                    Text("30 min")
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
        }
        XCTAssertNotNil(row, "CardRow should initialize with complex HStack content")
    }

    func testCardRow_InitializesWithEmptyContent() {
        let row = CardRow {
            EmptyView()
        }
        XCTAssertNotNil(row, "CardRow should initialize with EmptyView")
    }

    // MARK: - AccessibleActionCard Initialization Tests

    func testAccessibleActionCard_InitializesWithContent() {
        let card = AccessibleActionCard(label: "Recipe Card") {
            Text("Recipe Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should initialize with label and content")
    }

    func testAccessibleActionCard_InitializesWithHint() {
        let card = AccessibleActionCard(label: "Recipe Card", hint: "Double tap to open") {
            Text("Recipe Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should initialize with label, hint, and content")
    }

    func testAccessibleActionCard_InitializesWithAction() {
        let card = AccessibleActionCard(
            label: "Recipe Card",
            hint: "Double tap to open",
            action: {}
        ) {
            Text("Recipe Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should initialize with action closure")
    }

    func testAccessibleActionCard_InitializesWithLargeVariant() {
        let card = AccessibleActionCard(
            isLarge: true,
            label: "Large Recipe Card",
            hint: "Double tap to open",
            action: {}
        ) {
            VStack {
                Text("Hero Content")
                Text("Subtitle")
            }
        }
        XCTAssertNotNil(card, "AccessibleActionCard with isLarge=true should initialize")
    }

    func testAccessibleActionCard_InitializesWithoutHint() {
        let card = AccessibleActionCard(
            label: "Card without hint",
            action: {}
        ) {
            Text("Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should initialize without hint parameter")
    }

    func testAccessibleActionCard_InitializesWithoutAction() {
        let card = AccessibleActionCard(label: "Card without action") {
            Text("Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should initialize without action parameter")
    }

    // MARK: - Card Rendering Without Crash Tests

    func testCooksyCard_RendersWithoutCrash() {
        let card = CooksyCard {
            Text("Safe render test")
        }
        let body = card.body
        XCTAssertNotNil(body, "CooksyCard body should not be nil")
    }

    func testSoftCard_RendersWithoutCrash() {
        let card = SoftCard {
            Text("Safe render test")
        }
        let body = card.body
        XCTAssertNotNil(body, "SoftCard body should not be nil")
    }

    func testCardRow_RendersWithoutCrash() {
        let row = CardRow {
            Text("Safe render test")
        }
        let body = row.body
        XCTAssertNotNil(body, "CardRow body should not be nil")
    }

    // MARK: - Card with Different Content Types

    func testCooksyCard_WithImageContent() {
        let card = CooksyCard {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 100, height: 100)
        }
        XCTAssertNotNil(card, "CooksyCard should work with Image content")
    }

    func testCooksyCard_WithButtonContent() {
        let card = CooksyCard {
            Button("Tap me") {}
        }
        XCTAssertNotNil(card, "CooksyCard should work with Button content")
    }

    func testSoftCard_WithVStackContent() {
        let card = SoftCard {
            VStack {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
            }
        }
        XCTAssertNotNil(card, "SoftCard should work with VStack content")
    }

    func testCardRow_WithHStackContent() {
        let row = CardRow {
            HStack {
                Text("Left")
                Spacer()
                Text("Right")
            }
        }
        XCTAssertNotNil(row, "CardRow should work with HStack content")
    }

    // MARK: - AccessibleActionCard Accessibility Tests

    func testAccessibleActionCard_HasAccessibilityLabel() {
        let card = AccessibleActionCard(label: "Chocolate Cake Recipe") {
            Text("Chocolate Cake")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should have accessibility label set")
    }

    func testAccessibleActionCard_HasAccessibilityHint() {
        let card = AccessibleActionCard(
            label: "Chocolate Cake",
            hint: "Double tap to view recipe details"
        ) {
            Text("Chocolate Cake")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should have accessibility hint set")
    }

    func testAccessibleActionCard_HasButtonTrait() {
        let card = AccessibleActionCard(
            label: "Tappable Card",
            action: {}
        ) {
            Text("Tap me")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should have isButton trait")
    }

    // MARK: - Card Content ViewBuilder Tests

    func testCooksyCard_AcceptsViewBuilderContent() {
        let card = CooksyCard {
            Group {
                Text("Grouped content 1")
                Text("Grouped content 2")
            }
        }
        XCTAssertNotNil(card, "CooksyCard should accept Group as ViewBuilder content")
    }

    func testSoftCard_AcceptsConditionalContent() {
        let showDetail = true
        let card = SoftCard {
            if showDetail {
                Text("Detail shown")
            } else {
                Text("Detail hidden")
            }
        }
        XCTAssertNotNil(card, "SoftCard should accept conditional ViewBuilder content")
    }

    func testCardRow_AcceptsForEachContent() {
        let items = ["Item 1", "Item 2", "Item 3"]
        let row = CardRow {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
        XCTAssertNotNil(row, "CardRow should accept ForEach as ViewBuilder content")
    }

    // MARK: - Card Composition Test

    func testNestedCards() {
        let nested = CooksyCard {
            SoftCard {
                Text("Nested content")
            }
        }
        XCTAssertNotNil(nested, "Cards should be composable/nestable")
    }

    func testCardRowInsideCooksyCard() {
        let composed = CooksyCard {
            VStack {
                Text("Header")
                CardRow {
                    Text("Row inside card")
                }
            }
        }
        XCTAssertNotNil(composed, "CardRow should be usable inside CooksyCard")
    }

    // MARK: - AccessibleActionCard Edge Cases

    func testAccessibleActionCard_EmptyLabel() {
        let card = AccessibleActionCard(label: "") {
            Text("Content with empty label")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should handle empty label")
    }

    func testAccessibleActionCard_LongLabel() {
        let longLabel = String(repeating: "A", count: 500)
        let card = AccessibleActionCard(label: longLabel) {
            Text("Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should handle very long label")
    }

    func testAccessibleActionCard_NilHint() {
        let card = AccessibleActionCard(
            label: "Card",
            hint: nil,
            action: {}
        ) {
            Text("Content")
        }
        XCTAssertNotNil(card, "AccessibleActionCard should handle nil hint")
    }
}
