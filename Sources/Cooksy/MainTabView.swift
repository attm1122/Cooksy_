import SwiftUI

// MARK: - Main Tab View

/// The main tab bar controller for the Cooksy app.
/// Provides navigation between Home, Recipes, Books, and Profile tabs.
/// Each tab is fully accessible with proper labels and identifiers.
struct MainTabView: View {

    // MARK: - Body

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .accessibilityLabel("Home tab")

            NavigationStack { RecipesView() }
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
                .accessibilityLabel("Recipes tab")

            NavigationStack { BooksView() }
                .tabItem {
                    Label("Books", systemImage: "folder")
                }
                .accessibilityLabel("Books tab")

            NavigationStack { ProfileView() }
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .accessibilityLabel("Profile tab")
        }
        .tint(.brand)
        .accessibilityLabel("Main navigation")
        .accessibilityHint("Use tabs to switch between Home, Recipes, Books, and Profile")
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
