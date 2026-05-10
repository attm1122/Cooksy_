import SwiftUI
import SwiftData

// MARK: - Home View

struct HomeView: View {

    // MARK: - Dependencies

    @Environment(\.supabase) private var supabase
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = HomeViewModel()
    @State private var importService = ImportService()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {

                    // MARK: - Greeting
                    greetingBar

                    // MARK: - Hero Card
                    heroCard

                    // MARK: - Import Section
                    importSection

                    // MARK: - Recently Saved
                    recentlySavedSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.cooksBackground)
            .navigationTitle("Cooksy")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadRecipes()
            }
            .overlay(alignment: .top) {
                RecipeReadyBanner(
                    isVisible: $viewModel.showCompletionBanner,
                    recipe: viewModel.completedRecipe,
                    onDismiss: { viewModel.dismissCompletion() }
                )
            }
        }
        .task {
            // Configure ViewModel with injected dependencies
            viewModel.configure(
                supabase: supabase,
                modelContext: modelContext,
                importService: importService
            )
            await viewModel.loadRecipes()
        }
    }

    // MARK: - Greeting Bar

    private var greetingBar: some View {
        HStack {
            let name = viewModel.userFirstName
            Text(name.isEmpty ? viewModel.greeting : "\(viewModel.greeting), \(name)")
                .font(.cooksCallout)
                .foregroundStyle(Color.muted)

            Spacer()
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        CooksyCard(isLarge: true) {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.brand)

                VStack(spacing: 6) {
                    let name = viewModel.userFirstName
                    Text(name.isEmpty ? "Save recipes from anywhere. Cook them later." : "\(name), save recipes from anywhere. Cook them later.")
                        .font(.cooksH2)
                        .foregroundStyle(.ink)
                        .multilineTextAlignment(.center)

                    Text("Paste a link and we'll extract the ingredients, steps, and timings.")
                        .font(.cooksCallout)
                        .foregroundStyle(.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Import Section

    private var importSection: some View {
        VStack(spacing: 16) {
            // URL Input
            URLInputField(text: $viewModel.sourceUrl)

            // URL Error
            if let error = viewModel.urlError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(.cooksCaption)
                }
                .foregroundStyle(.cooksDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }

            // Platform Badges
            HStack(spacing: 10) {
                PlatformBadge(platform: .youtube)
                PlatformBadge(platform: .tiktok)
                PlatformBadge(platform: .instagram)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Import Button
            Button {
                Task {
                    await viewModel.importRecipe()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isImporting {
                        ProgressView()
                            .tint(.ink)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(viewModel.isImporting ? "Saving..." : "Save Recipe")
                        .font(.cooksBodyBold)
                }
            }
            .primaryButton()
            .disabled(!viewModel.canImport)
            .opacity(viewModel.canImport ? 1.0 : 0.6)
        }
    }

    // MARK: - Recently Saved Section

    @ViewBuilder
    private var recentlySavedSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Text("Recently saved")
                    .font(.cooksH3)
                    .foregroundStyle(.ink)

                Spacer()

                NavigationLink {
                    RecipesView()
                } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.cooksCallout.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.brand)
                }
            }
            .padding(.bottom, 12)

            // Recipe List or Empty State
            if viewModel.recipes.isEmpty {
                EmptyStateView(
                    icon: "bookmark.slash",
                    title: "No saved recipes",
                    description: "Paste a recipe video link above to save your first recipe."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recipes.prefix(5)) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            RecipeRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0.6)
                                .offset(y: phase.isIdentity ? 0 : 10)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recipe Ready Banner

/// A simple inline banner shown when a recipe has been successfully imported.
private struct RecipeReadyBanner: View {
    @Binding var isVisible: Bool
    var recipe: Recipe?
    var onDismiss: () -> Void

    var body: some View {
        if isVisible, let recipe = recipe {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.cooksSuccess)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recipe saved!")
                        .font(.cooksCallout.weight(.semibold))
                        .foregroundStyle(.ink)

                    Text(recipe.title)
                        .font(.cooksCaption)
                        .foregroundStyle(.muted)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.muted)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.cooksLine))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.surface)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.cooksSuccess.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
roundStyle(.cooksSuccess)
                    .decorative()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recipe saved!")
                        .font(.cooksCallout.weight(.semibold))
                        .foregroundStyle(.ink)

                    Text(recipe.title)
                        .font(.cooksCaption)
                        .foregroundStyle(.muted)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.muted)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.cooksLine))
                }
                .accessibilityLabel("Dismiss recipe saved banner")
                .accessibilityIdentifier(AccessibilityID.dismissBannerButton)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.surface)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.cooksSuccess.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .accessibleAnimation(.easeOut(duration: 0.3), value: isVisible)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Recipe saved: \(recipe.title)")
            .accessibilityAnnouncement()
            .accessibilityIdentifier(AccessibilityID.recipeCompletionBanner)
        }
    }
}

// MARK: - Accessibility Announcement Modifier

private struct AccessibilityAnnouncementModifier: ViewModifier {
    @State private var hasAnnounced = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAnnounced {
                    hasAnnounced = true
                    // Allow layout to settle before announcing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIAccessibility.post(notification: .layoutChanged, argument: nil)
                    }
                }
            }
    }
}

private extension View {
    func accessibilityAnnouncement() -> some View {
        modifier(AccessibilityAnnouncementModifier())
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
