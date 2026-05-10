import SwiftUI

// MARK: - ContentView
/// The root view of the Cooksy app.
///
/// Handles the splash screen sequence and routes between onboarding, auth, and main app flows
/// based on the current authentication state from the injected `SupabaseProtocol`.
///
/// ## Flow
/// 1. Shows a branded splash screen for 1.5 seconds.
/// 2. Shows onboarding for first-time users (can be skipped).
/// 3. Checks `supabase.currentUser` to determine auth state.
/// 4. Presents `AuthView` if no user is signed in.
/// 5. Presents `MainTabView` once authenticated.
///
/// ## Auth State Changes
/// The view listens for changes to `supabase.currentUser` (via `@Observable`)
/// so that sign-out from any nested view immediately returns to the auth screen.
struct ContentView: View {

    // MARK: - Dependencies

    @Environment(\.supabase) private var supabase

    // MARK: - State

    /// Whether the splash screen is currently visible.
    @State private var showSplash = true

    /// Whether to show the onboarding flow. Only true for first-time users.
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    /// Whether to show the jailbreak security warning alert.
    @State private var showJailbreakWarning = false

    // MARK: - Body

    var body: some View {
        ZStack {
            if showSplash {
                splashView
                    .accessibilityLabel("Cooksy splash screen, loading")
            } else if showOnboarding {
                OnboardingView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                }
                .accessibilityLabel("Cooksy onboarding")
                .transition(.opacity)
            } else if supabase.currentUser != nil {
                MainTabView()
                    .accessibilityLabel("Cooksy main app")
                    .transition(.opacity)
            } else {
                AuthView(onAuthenticated: handleAuthentication)
                    .accessibilityLabel("Cooksy sign in")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .animation(.easeInOut(duration: 0.35), value: showOnboarding)
        .animation(.easeInOut(duration: 0.35), value: supabase.currentUser != nil)
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
        }
        // SECURITY: Apply screen capture protection to all app content
        .screenProtection()
        // SECURITY: Auto-lock after 5 minutes of inactivity — requires biometric/PIN to unlock
        .appLock(timeout: 300)
        // SECURITY: Hide sensitive content in iOS app switcher snapshot
        .backgroundSnapshotProtection()
        // SECURITY: Jailbreak detection - show warning if device appears compromised
        .onAppear {
            #if !DEBUG
            if JailbreakDetection.isDeviceJailbroken() {
                showJailbreakWarning = true
            }
            #endif
        }
        .alert("Security Warning", isPresented: $showJailbreakWarning) {
            Button("Continue", role: .cancel) { }
        } message: {
            Text("This device appears to be jailbroken. For your security, some features may be limited. We recommend using Cooksy on a non-jailbroken device.")
        }
    }

    // MARK: - Splash View

    private var splashView: some View {
        ZStack {
            Color.cooksBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                CooksyLogo(size: 80)

                Text("Cooksy")
                    .font(.cooksHero)
                    .foregroundStyle(.ink)
            }
        }
    }

    // MARK: - Auth Handler

    /// Called by `AuthView` when authentication succeeds.
    /// The `supabase.currentUser` is already set by `AuthViewModel.verifyOTP()`.
    private func handleAuthentication() {
        // The UI automatically re-evaluates because `supabase.currentUser`
        // is `@Observable` and triggers view updates.
    }
}

// MARK: - Preview

#Preview("Authenticated") {
    let mock = MockSupabaseService()
    Task { _ = try? await mock.verifyOTP(email: "preview@cooksy.app", token: "000000") }

    return ContentView()
        .environment(\.supabase, mock)
}

#Preview("Not Authenticated") {
    ContentView()
        .environment(\.supabase, MockSupabaseService())
}
