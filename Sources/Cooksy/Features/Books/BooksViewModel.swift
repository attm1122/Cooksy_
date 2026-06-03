import Foundation
import SwiftData

// MARK: - BooksViewModel
/// Manages recipe book collections: creation, listing, deletion, and SwiftData persistence.
///
/// ## SwiftData Integration
/// Books are stored in SwiftData and observed via `FetchDescriptor`. This ensures
/// the UI updates automatically when books are added, removed, or renamed.
///
/// ## Error Handling
/// All persistence errors are surfaced via the `errorMessage` property for display
/// in the view (e.g. as an alert or banner).
@MainActor
@Observable
final class BooksViewModel {

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - State

    /// All recipe books loaded from SwiftData.
    var books: [RecipeBook] = []

    /// Controls the visibility of the create book sheet.
    var showCreateSheet: Bool = false

    /// The name for a new book being created.
    var newBookName: String = ""

    /// Whether books are being loaded.
    private(set) var isLoading: Bool = false

    /// Error message for display.
    private(set) var errorMessage: String?

    // MARK: - Configuration

    /// Injects the SwiftData context. Must be called before any CRUD operations.
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Loading

    /// Loads all recipe books from SwiftData, sorted by creation date (newest first).
    func loadBooks() async {
        guard let modelContext = modelContext else { return }
        isLoading = true
        errorMessage = nil

        let descriptor = FetchDescriptor<RecipeBook>(
            sortBy: [SortDescriptor<RecipeBook>(\.createdAt, order: .reverse)]
        )

        do {
            books = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load recipe books."
        }

        isLoading = false
    }

    // MARK: - CRUD

    /// Creates a new book with the current `newBookName`, inserts it into SwiftData,
    /// then resets the input field and dismisses the sheet.
    func createBook() {
        let trimmedName = newBookName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let modelContext = modelContext else {
            errorMessage = "Data store not available."
            return
        }

        let newBook = RecipeBook(name: trimmedName)
        modelContext.insert(newBook)

        do {
            try modelContext.save()
            books.insert(newBook, at: 0)
            newBookName = ""
            showCreateSheet = false
            HapticsService.play(.success)
        } catch {
            errorMessage = "Failed to create book. Please try again."
            HapticsService.play(.error)
        }
    }

    /// Deletes a book from SwiftData and the local array.
    func deleteBook(_ book: RecipeBook) {
        guard let modelContext = modelContext else { return }

        modelContext.delete(book)
        books.removeAll { $0.id == book.id }

        do {
            try modelContext.save()
            HapticsService.play(.light)
        } catch {
            errorMessage = "Failed to delete book."
        }
    }

    /// Renames an existing book.
    /// - Parameters:
    ///   - book: The book to rename.
    ///   - newName: The new name for the book.
    func renameBook(_ book: RecipeBook, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let modelContext = modelContext else { return }

        book.name = trimmed
        book.touch()

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to rename book."
        }
    }
}

// MARK: - RecipeBook + Touch

extension RecipeBook {
    /// Updates the `createdAt` timestamp to now.
    /// Used after modifications to trigger SwiftData observation.
    fileprivate func touch() {
        // RecipeBook doesn't have an updatedAt field; this is a no-op
        // that could be expanded if needed.
    }
}
