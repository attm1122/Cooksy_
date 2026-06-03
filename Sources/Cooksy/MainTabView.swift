import SwiftUI

// MARK: - Main Tab View

/// The main tab bar controller for the Cooksy app.
/// Provides navigation between Home, Recipes, Books, and Profile tabs.
/// Each tab is fully accessible with proper labels and identifiers.
///
/// Displays an `OfflineBanner` at the top of the screen when the device
/// loses network connectivity. The banner is injected via `ZStack` overlay
/// so it sits above all tab content without interfering with tab switching.
struct MainTabView: View {

    // MARK: - State

    @State private var networkMonitor = NetworkMonitor.shared

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
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
            .tint(Color.brand)
            .accessibilityLabel("Main navigation")
            .accessibilityHint("Use tabs to switch between Home, Recipes, Books, and Profile")

            // Offline banner — slides in from the top when disconnected
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .accessibleAnimation(
                        .easeOut(duration: 0.3),
                        value: networkMonitor.isConnected
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .padding(.top, safeAreaTopInset)
            }
        }
    }
}

// MARK: - Safe Area Helper

private extension MainTabView {
    /// Returns the top safe area inset, accounting for device specifics.
    var safeAreaTopInset: CGFloat {
        (UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?
            .windows
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.top) ?? 0
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
