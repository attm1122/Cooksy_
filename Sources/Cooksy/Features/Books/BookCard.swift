import SwiftUI
import SwiftData

// MARK: - Book Card
/// A visually rich card displaying a recipe book with its icon, name,
/// recipe count, and creation date. Fully accessible with VoiceOver.
struct BookCard: View {

    // MARK: - Properties

    let book: RecipeBook
    var onTap: (() -> Void)? = nil

    private var recipeCount: Int {
        book.recipes?.count ?? 0
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with icon
                ZStack {
                    Circle()
                        .fill(Color.brand.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.brand)
                }
                .padding(.bottom, 12)

                // Book name
                Text(book.name)
                    .font(.cooksH3)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                // Recipe count
                Text("\(recipeCount) recipe\(recipeCount == 1 ? "" : "s")")
                    .font(.cooksCaption)
                    .foregroundStyle(Color.muted)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(book.name), \(recipeCount) recipes")
        .accessibilityHint("Double tap to open this book")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    BookCard(book: RecipeBook(name: "Weeknight Dinners"))
        .padding()
        .background(Color.cooksBackground)
}
