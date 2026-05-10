import SwiftUI
import SwiftData

// MARK: - ProfileView
/// User profile with subscription info, statistics, settings, and sign out.
///
/// Uses `ProfileViewModel` to load real user data from auth state and SwiftData,
/// and handles account actions like data export, sign out, and account deletion.
struct ProfileView: View {

    // MARK: - Dependencies

    @Environment(\.supabase) private var supabase
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var viewModel = ProfileViewModel(
        supabase: MockSupabaseService() // Placeholder — replaced in configure()
    )

    @State private var isConfigured = false
    @State private var showExportSheet = false
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // User header
                    userHeaderSection

                    // Subscription card
                    subscriptionCard

                    // Statistics
                    statisticsSection

                    // Settings sections
                    settingsSections

                    // Sign out
                    signOutButton
                }
                .padding(.vertical, 16)
            }
            .background(Color.cooksBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showExportSheet) {
                ExportDataSheet(jsonData: viewModel.exportDataJSON)
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
            } message: {
                Text("This will permanently delete your account and all your recipes, books, and data. This action cannot be undone.")
            }
            .task {
                guard !isConfigured else { return }
                viewModel = ProfileViewModel(
                    supabase: supabase,
                    modelContext: modelContext
                )
                isConfigured = true
                await viewModel.loadProfile()
            }
        }
    }

    // MARK: - User Header

    private var userHeaderSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brand)
                    .frame(width: 64, height: 64)

                Text(viewModel.userDisplayName.isEmpty ? "👤" : String(viewModel.userDisplayName.prefix(1)))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            if viewModel.userDisplayName.isEmpty {
                Text(viewModel.userEmail)
                    .font(.cooksH3)
                    .foregroundStyle(Color.ink)
            } else {
                Text(viewModel.userDisplayName)
                    .font(.cooksH3)
                    .foregroundStyle(Color.ink)

                Text(viewModel.userEmail)
                    .font(.cooksCallout)
                    .foregroundStyle(Color.muted)
            }

            Text("Member since \(viewModel.memberSinceDate)")
                .font(.cooksCaption)
                .foregroundStyle(Color.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        CooksyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your Plan")
                        .font(.cooksMicro)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brand.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    if viewModel.isPro {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.brand)
                    }
                }

                Text(viewModel.planName)
                    .font(.cooksH3)
                    .foregroundStyle(Color.ink)

                NavigationLink(value: "subscription") {
                    HStack {
                        Text(viewModel.isPro ? "Manage Subscription" : "Upgrade to Cooksy Pro")
                            .font(.cooksCallout)
                            .fontWeight(.medium)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.cooksMicro)
                            .foregroundStyle(Color.muted)
                    }
                    .foregroundStyle(Color.brand)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        HStack(spacing: 12) {
            StatCard(value: viewModel.recipeCount, label: "Recipes")
            StatCard(value: viewModel.savedCount, label: "Saved")
        }
        .padding(.horizontal)
    }

    // MARK: - Settings Sections

    private var settingsSections: some View {
        VStack(spacing: 24) {
            // Account
            ProfileSection(title: "Account") {
                NavigationLink(value: "editProfile") {
                    ProfileRow(icon: "person.fill", title: "Edit Profile", color: .brand)
                }

                NavigationLink(value: "changePassword") {
                    ProfileRow(icon: "lock.fill", title: "Change Password", color: .brand)
                }
            }

            // Data
            ProfileSection(title: "Data") {
                Button {
                    Task { await viewModel.exportData() }
                } label: {
                    ProfileRow(icon: "square.and.arrow.up.fill", title: "Export Data", color: .brand)
                }

                Button {
                    showDeleteConfirmation = true
                } label: {
                    ProfileRow(icon: "trash.fill", title: "Delete Account", color: .cooksDanger)
                }
            }
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            HapticsService.heavy()
            Task { await viewModel.signOut() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.backward.square.fill")
                Text("Sign Out")
            }
        }
        .secondaryButton()
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: Int
    let label: String

    var body: some View {
        CooksyCard {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ink)

                Text(label)
                    .font(.cooksCaption)
                    .foregroundStyle(Color.muted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Profile Section

private struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.cooksCaption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.muted)
                .textCase(.uppercase)
                .padding(.horizontal)

            CooksyCard {
                VStack(spacing: 0) {
                    content
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.cooksBody)
                .foregroundStyle(Color.ink)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.cooksCaption)
                .foregroundStyle(Color.muted)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Export Data Sheet

/// Displays the exported JSON data with a share button.
private struct ExportDataSheet: View {
    let jsonData: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(jsonData)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: jsonData) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
ent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.cooksCaption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.muted)
                .textCase(.uppercase)
                .padding(.horizontal)
                .accessibleHeading(.h3)

            CooksyCard {
                VStack(spacing: 0) {
                    content
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .decorative()

            Text(title)
                .font(.cooksBody)
                .foregroundStyle(Color.ink)
                .scalableText()

            Spacer()

            Image(systemName: "chevron.right")
                .font(.cooksCaption)
                .foregroundStyle(Color.muted)
                .decorative()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
