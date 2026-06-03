import SwiftUI
import SwiftData

// MARK: - BooksView
/// Displays a grid of recipe books with the ability to create new collections.
struct BooksView: View {

    // MARK: - Dependencies

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = BooksViewModel()

    // MARK: - Grid Layout

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.books.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No books yet",
                        description: "Create a book to organize your recipes."
                    )
                    .padding(.vertical, 80)
                    .accessibilityLabel("No recipe books yet")
                    .accessibilityHint("Tap the plus button in the top right to create your first recipe book")
                } else {
                    AccessibleBookGrid(
                        books: viewModel.books,
                        gridColumns: gridColumns,
                        onDelete: { book in
                            viewModel.deleteBook(book)
                            announceToVoiceOver("Book \(book.name) deleted")
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(
                Color.cooksBackground
                    .overlay(
                        // Subtle warm radial glow — mirrors demo's desaturated background texture
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.brand.opacity(0.04),
                                Color.clear
                            ]),
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 400
                        )
                    )
            )
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier(AccessibilityID.booksView)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsService.light()
                        viewModel.showCreateSheet = true
                        announceToVoiceOver("Create new recipe book")
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.ink)
                            .frame(width: 36, height: 36)
                            .background(Color.brand)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Create new recipe book")
                    .accessibilityHint("Opens a form to create a new recipe book collection")
                    .accessibilityIdentifier(AccessibilityID.createBookButton)
                }
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                createBookSheet
            }
            .task {
                viewModel.configure(modelContext: modelContext)
                await viewModel.loadBooks()
            }
        }
    }

    // MARK: - Create Book Sheet

    private var createBookSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brand.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Image(systemName: "folder.badge.plus")
                        .font(.title)
                        .foregroundStyle(Color.brand)
                        .decorative()
                }
                .padding(.top, 24)
                .accessibilityLabel("Create new book icon")

                // Title
                Text("Create New Book")
                    .font(.cooksH2)
                    .foregroundStyle(Color.ink)
                    .accessibleHeading(.h2)
                    .accessibilityLabel("Create new recipe book")

                // Description
                Text("Give your collection a name to get started.")
                    .font(.cooksCallout)
                    .foregroundStyle(Color.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .scalableText()
                    .accessibilityLabel("Give your collection a name to get started.")

                // Text Field
                TextField("Book name", text: $viewModel.newBookName)
                    .font(.cooksBody)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Book name")
                    .accessibilityHint("Enter a name for your new recipe book")

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        HapticsService.medium()
                        viewModel.createBook()
                        announceToVoiceOver("Book \(viewModel.newBookName) created")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.fill")
                                .decorative()
                            Text("Create")
                        }
                    }
                    .primaryButton()
                    .disabled(viewModel.newBookName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Create recipe book")
                    .accessibilityHint("Creates a new recipe book with the name you entered")

                    Button("Cancel") {
                        viewModel.newBookName = ""
                        viewModel.showCreateSheet = false
                        announceToVoiceOver("Create book cancelled")
                    }
                    .tertiaryButton()
                    .accessibilityLabel("Cancel creating book")
                    .padding(.bottom, 12)
                }
            }
            .background(Color.cooksBackground)
        }
    }
}

// MARK: - Accessible Book Grid

/// A grid of book cards with accessibility support for VoiceOver navigation
/// and swipe-to-delete actions.
private struct AccessibleBookGrid: View {
    let books: [RecipeBook]
    let gridColumns: [GridItem]
    let onDelete: (RecipeBook) -> Void

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(books) { book in
                AccessibleBookCard(book: book, onDelete: onDelete)
                    .accessibilityIdentifier("\(AccessibilityID.bookCardPrefix)\(book.id)")
            }
        }
    }
}

// MARK: - Accessible Book Card

/// An accessibility-enhanced book card with combined VoiceOver labels
/// and swipe-to-delete support.
private struct AccessibleBookCard: View {
    let book: RecipeBook
    let onDelete: (RecipeBook) -> Void

    var body: some View {
        CooksyCard {
            VStack(spacing: 14) {
                // Folder icon in brand circle
                ZStack {
                    Circle()
                        .fill(Color.brand.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.brand)
                        .decorative()
                }
                .accessibilityHidden(true)

                // Book name
                Text(book.name)
                    .font(.cooksH3)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .scalableText()

                // Recipe count
                Text("\(book.recipes?.count ?? 0) recipes")
                    .font(.cooksCaption)
                    .foregroundStyle(Color.muted)
                    .scalableText()
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.name), \(book.recipes?.count ?? 0) recipes")
        .accessibilityHint("Double tap to open this recipe book. Swipe left to delete.")
        .accessibilityAction(named: Text("Delete \(book.name)")) {
            onDelete(book)
        }
    }
}

// MARK: - Preview

#Preview {
    BooksView()
}
