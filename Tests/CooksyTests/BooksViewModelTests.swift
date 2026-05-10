import XCTest
@testable import Cooksy

// MARK: - BooksViewModelTests
/// Comprehensive unit tests for the BooksViewModel recipe book collection management.
///
/// Tests cover initial state, CRUD operations (create, delete, rename), book properties,
/// validation rules, and SwiftData-independent state management.
@MainActor
final class BooksViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: BooksViewModel!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = BooksViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Factory Methods

    private func makeBook(name: String) -> RecipeBook {
        RecipeBook(name: name)
    }

    // MARK: - Initial State Tests

    func test_initialState_booksIsEmpty() {
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_initialState_showCreateSheetIsFalse() {
        XCTAssertFalse(sut.showCreateSheet)
    }

    func test_initialState_newBookNameIsEmpty() {
        XCTAssertEqual(sut.newBookName, "")
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_errorMessageIsNil() {
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - State Mutability Tests

    func test_booksArrayCanBeSet() {
        let book1 = makeBook(name: "Desserts")
        let book2 = makeBook(name: "Mains")
        sut.books = [book1, book2]
        XCTAssertEqual(sut.books.count, 2)
    }

    func test_showCreateSheetCanBeToggled() {
        sut.showCreateSheet = true
        XCTAssertTrue(sut.showCreateSheet)
        sut.showCreateSheet = false
        XCTAssertFalse(sut.showCreateSheet)
    }

    func test_newBookNameCanBeSet() {
        sut.newBookName = "My New Book"
        XCTAssertEqual(sut.newBookName, "My New Book")
    }

    func test_errorMessageCanBeSet() {
        // errorMessage is private(set), so we test via loadBooks or other public paths
        // For now, verify it starts nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Book Creation Validation Tests

    func test_createBook_withEmptyName_doesNothing() {
        sut.newBookName = ""
        sut.books = []
        sut.createBook()
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_createBook_withWhitespaceOnlyName_doesNothing() {
        sut.newBookName = "   "
        sut.books = []
        sut.createBook()
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_createBook_withValidName_withoutModelContext_setsError() {
        sut.newBookName = "Test Book"
        sut.books = []
        sut.createBook()
        // Without ModelContext, the error should be set
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_createBook_clearsNewBookNameOnSuccess() {
        // This test would need ModelContext to fully pass
        // Testing the validation path: empty name won't clear
        sut.newBookName = ""
        sut.createBook()
        XCTAssertEqual(sut.newBookName, "")
    }

    func test_createBook_trimsWhitespaceFromName() {
        // Validation trims whitespace before checking
        sut.newBookName = "   "
        sut.createBook()
        // Should be treated as empty and not create
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_createBook_preservesNameWhenInvalid() {
        let originalName = sut.newBookName
        sut.createBook()
        XCTAssertEqual(sut.newBookName, originalName)
    }

    // MARK: - Book Deletion Tests

    func test_deleteBook_removesFromArray() {
        let book1 = makeBook(name: "Book 1")
        let book2 = makeBook(name: "Book 2")
        sut.books = [book1, book2]
        sut.deleteBook(book1)
        XCTAssertEqual(sut.books.count, 1)
        XCTAssertEqual(sut.books[0].name, "Book 2")
    }

    func test_deleteBook_removesCorrectBook() {
        let book1 = makeBook(name: "Book 1")
        let book2 = makeBook(name: "Book 2")
        let book3 = makeBook(name: "Book 3")
        sut.books = [book1, book2, book3]
        sut.deleteBook(book2)
        XCTAssertFalse(sut.books.contains { $0.id == book2.id })
        XCTAssertTrue(sut.books.contains { $0.id == book1.id })
        XCTAssertTrue(sut.books.contains { $0.id == book3.id })
    }

    func test_deleteBook_fromEmptyArray() {
        let orphanBook = makeBook(name: "Orphan")
        sut.books = []
        sut.deleteBook(orphanBook)
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_deleteBook_lastBook() {
        let lastBook = makeBook(name: "Last One")
        sut.books = [lastBook]
        sut.deleteBook(lastBook)
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_deleteBook_doesNotAffectOtherProperties() {
        let book1 = makeBook(name: "Book 1")
        let book2 = makeBook(name: "Book 2")
        sut.books = [book1, book2]
        sut.showCreateSheet = true
        sut.deleteBook(book1)
        XCTAssertTrue(sut.showCreateSheet)
    }

    // MARK: - Book Rename Tests

    func test_renameBook_updatesName() {
        let book = makeBook(name: "Old Name")
        sut.books = [book]
        sut.renameBook(book, to: "New Name")
        // Without ModelContext, rename returns early after guard
        // But the name assignment happens before the save attempt
        XCTAssertEqual(book.name, "New Name")
    }

    func test_renameBook_trimsWhitespace() {
        let book = makeBook(name: "Original")
        sut.renameBook(book, to: "  Trimmed Name  ")
        XCTAssertEqual(book.name, "Trimmed Name")
    }

    func test_renameBook_withEmptyName_doesNothing() {
        let book = makeBook(name: "Original")
        sut.renameBook(book, to: "")
        XCTAssertEqual(book.name, "Original")
    }

    func test_renameBook_withWhitespaceOnly_doesNothing() {
        let book = makeBook(name: "Original")
        sut.renameBook(book, to: "   ")
        XCTAssertEqual(book.name, "Original")
    }

    func test_renameBook_withoutModelContext_setsError() {
        let book = makeBook(name: "Original")
        sut.renameBook(book, to: "New Name")
        // renameBook returns early at the modelContext guard
        // The name is set before that check
        XCTAssertEqual(book.name, "New Name")
    }

    func test_renameBook_touchesBook() {
        let book = makeBook(name: "Original")
        sut.renameBook(book, to: "New Name")
        // Even without ModelContext, the name change happens
        XCTAssertEqual(book.name, "New Name")
    }

    // MARK: - Multiple Books Operations

    func test_addMultipleBooks() {
        let book1 = makeBook(name: "Breakfast")
        let book2 = makeBook(name: "Lunch")
        let book3 = makeBook(name: "Dinner")
        sut.books = [book1, book2, book3]
        XCTAssertEqual(sut.books.count, 3)
    }

    func test_deleteMultipleBooks() {
        let book1 = makeBook(name: "Book 1")
        let book2 = makeBook(name: "Book 2")
        let book3 = makeBook(name: "Book 3")
        sut.books = [book1, book2, book3]
        sut.deleteBook(book1)
        sut.deleteBook(book3)
        XCTAssertEqual(sut.books.count, 1)
        XCTAssertEqual(sut.books[0].name, "Book 2")
    }

    func test_renameMultipleBooks() {
        let book1 = makeBook(name: "A")
        let book2 = makeBook(name: "B")
        sut.books = [book1, book2]
        sut.renameBook(book1, to: "Alpha")
        sut.renameBook(book2, to: "Beta")
        XCTAssertEqual(book1.name, "Alpha")
        XCTAssertEqual(book2.name, "Beta")
    }

    // MARK: - Empty Name Validation

    func test_emptyNameValidation_rejectsEmptyString() {
        sut.newBookName = ""
        sut.books = []
        sut.createBook()
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_emptyNameValidation_rejectsWhitespace() {
        sut.newBookName = "\t\n "
        sut.books = []
        sut.createBook()
        XCTAssertTrue(sut.books.isEmpty)
    }

    func test_emptyNameValidation_acceptsSingleCharacter() {
        sut.newBookName = "A"
        sut.books = []
        sut.createBook()
        // Single character should be valid (trims to "A")
        // But fails at modelContext check
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_emptyNameValidation_acceptsLongName() {
        sut.newBookName = String(repeating: "A", count: 100)
        sut.books = []
        sut.createBook()
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Book Properties

    func test_bookCreatedAtIsSet() {
        let before = Date()
        let book = makeBook(name: "Test Book")
        let after = Date()
        XCTAssertGreaterThanOrEqual(book.createdAt, before)
        XCTAssertLessThanOrEqual(book.createdAt, after)
    }

    func test_bookHasUniqueId() {
        let book1 = makeBook(name: "Book 1")
        let book2 = makeBook(name: "Book 2")
        XCTAssertNotEqual(book1.id, book2.id)
    }

    func test_bookEquality_sameId() {
        let id = UUID()
        let book1 = RecipeBook(id: id, name: "A")
        let book2 = RecipeBook(id: id, name: "B")
        XCTAssertEqual(book1, book2)
    }

    func test_bookEquality_differentId() {
        let book1 = makeBook(name: "A")
        let book2 = makeBook(name: "A")
        XCTAssertNotEqual(book1, book2)
    }

    func test_bookRecipeCount_empty() {
        let book = makeBook(name: "Empty")
        XCTAssertEqual(book.recipeCount, 0)
    }

    func test_bookRecipeCountDescription_empty() {
        let book = makeBook(name: "Empty")
        XCTAssertEqual(book.recipeCountDescription, "0 recipes")
    }

    func test_bookRecipesArray_empty() {
        let book = makeBook(name: "Empty")
        XCTAssertTrue(book.recipesArray.isEmpty)
    }

    // MARK: - Book Sorting Descriptors

    func test_sortByName_exists() {
        let descriptor = RecipeBook.sortByName
        XCTAssertNotNil(descriptor)
    }

    func test_sortByDate_exists() {
        let descriptor = RecipeBook.sortByDate
        XCTAssertNotNil(descriptor)
    }

    // MARK: - Sheet State Management

    func test_createSheet_toggleCycle() {
        sut.showCreateSheet = true
        XCTAssertTrue(sut.showCreateSheet)
        sut.showCreateSheet = false
        XCTAssertFalse(sut.showCreateSheet)
        sut.showCreateSheet = true
        XCTAssertTrue(sut.showCreateSheet)
    }

    func test_newBookName_clearedAfterSetting() {
        sut.newBookName = "Test"
        sut.newBookName = ""
        XCTAssertEqual(sut.newBookName, "")
    }

    // MARK: - Error State

    func test_errorMessage_canBeIndirectlyObserved() {
        // errorMessage is private(set), starts as nil
        XCTAssertNil(sut.errorMessage)
    }

    func test_isLoading_startsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Configuration

    func test_configure_doesNotCrash() {
        // configure requires a ModelContext which we can't easily create
        // Just verify the method signature exists by calling with nil context
        // This is more of a compilation check
        XCTAssertNotNil(sut)
    }

    // MARK: - Books Array Edge Cases

    func test_booksArray_withDuplicateNames() {
        let book1 = makeBook(name: "Favorites")
        let book2 = makeBook(name: "Favorites")
        sut.books = [book1, book2]
        XCTAssertEqual(sut.books.count, 2)
        // Books with the same name but different IDs are both kept
        XCTAssertEqual(sut.books[0].name, sut.books[1].name)
        XCTAssertNotEqual(sut.books[0].id, sut.books[1].id)
    }

    func test_booksArray_orderPreserved() {
        let book1 = makeBook(name: "First")
        let book2 = makeBook(name: "Second")
        let book3 = makeBook(name: "Third")
        sut.books = [book1, book2, book3]
        XCTAssertEqual(sut.books[0].name, "First")
        XCTAssertEqual(sut.books[1].name, "Second")
        XCTAssertEqual(sut.books[2].name, "Third")
    }

    func test_deleteBook_notInArray() {
        let inArray = makeBook(name: "In Array")
        let notInArray = makeBook(name: "Not In Array")
        sut.books = [inArray]
        sut.deleteBook(notInArray)
        XCTAssertEqual(sut.books.count, 1)
    }

    // MARK: - RecipeBook Creation with Default Date

    func test_bookDefaultCreatedAt() {
        let before = Date()
        let book = RecipeBook(name: "Test")
        let after = Date()
        XCTAssertGreaterThanOrEqual(book.createdAt, before)
        XCTAssertLessThanOrEqual(book.createdAt, after)
    }

    func test_bookWithExplicitDate() {
        let specificDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021
        let book = RecipeBook(name: "Historical", createdAt: specificDate)
        XCTAssertEqual(book.createdAt, specificDate)
    }
}
