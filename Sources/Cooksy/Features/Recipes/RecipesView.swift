import SwiftUI
import SwiftData

// MARK: - RecipesView
/// Main recipes list with search, filter chips, and navigation to recipe detail.
struct RecipesView: View {

    // MARK: - Dependencies

    @Environment(\.supabase) private var supabase
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = RecipesViewModel()

    // MARK: - Filter Options

    private var filterOptions: [(label: String, accessibilityLabel: String, status: RecipeStatus?)] {
        [
            ("All", "Filter by all recipes", nil),
            ("Processing", "Filter by processing recipes", .processing),
            ("Ready", "Filter by ready recipes", .ready),
            ("Failed", "Filter by failed recipes", .failed)
        ]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        if viewModel.filteredRecipes.isEmpty {
                            emptyStateView
                        } else {
                            recipeList
                        }
                    } header: {
                        filterChipsView
                            .background(Color.cooksBackground.opacity(0.95))
                    }
                }
            }
            .background(Color.cooksBackground)
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier(AccessibilityID.recipesView)
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search recipes..."
            )
            .accessibilityLabel("Search recipes")
            .accessibilityIdentifier(AccessibilityID.recipeSearchField)
            .refreshable {
                await viewModel.loadRecipes()
            }
            .task {
                viewModel.configure(supabase: supabase, modelContext: modelContext)
                await viewModel.loadRecipes()
            }
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: viewModel.searchQuery.isEmpty && viewModel.selectedFilter == nil
                ? "No recipes yet"
                : "No recipes found",
            description: viewModel.searchQuery.isEmpty && viewModel.selectedFilter == nil
                ? "Save a recipe to get started."
                : "Try adjusting your search or filters."
        )
        .padding(.vertical, 80)
        .accessibilityLabel(viewModel.searchQuery.isEmpty && viewModel.selectedFilter == nil
            ? "No recipes saved yet. Save a recipe to get started."
            : "No recipes found matching your search. Try adjusting your search or filters.")
        .accessibilityHint("Go to the Home tab to save your first recipe")
    }

    // MARK: - Recipe List

    private var recipeList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredRecipes) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    RecipeRow(recipe: recipe)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Double tap to view recipe details")
                .accessibilityIdentifier("\(AccessibilityID.recipeRowPrefix)\(recipe.id)")
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.deleteRecipe(recipe)
                        announceToVoiceOver("Recipe \(recipe.title) deleted")
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(recipe.title)")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Filter Chips

    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filterOptions.indices, id: \.self) { index in
                    let option = filterOptions[index]
                    let isSelected = viewModel.selectedFilter == option.status

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.selectedFilter = isSelected ? nil : option.status
                        }
                        announceToVoiceOver(isSelected
                            ? "Filter cleared, showing all recipes"
                            : "Filtered by \(option.label) recipes"
                        )
                    } label: {
                        Text(option.label)
                            .font(.subheadline.weight(isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color.ink : Color.muted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.brand : Color.surfaceAlt)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.accessibilityLabel)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityHint("Double tap to \(isSelected ? "clear this filter" : "filter by \(option.label) recipes")")
                    .accessibilityIdentifier("\(AccessibilityID.filterChipPrefix)\(option.label)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Preview

#Preview {
    RecipesView()
}
