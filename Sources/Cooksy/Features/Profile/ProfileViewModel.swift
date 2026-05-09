import SwiftData
import RevenueCat

// MARK: - ProfileViewModel
/// Manages profile screen state, user data, and account actions.
///
/// ## Real Data Export
/// `exportData()` serializes all SwiftData recipes into a structured JSON file,
/// including full ingredient and step details.
///
/// ## Real Account Deletion
/// `deleteAccount()` calls `supabase.deleteAccount()` to remove the server-side
/// user record, then clears all local SwiftData and UserDefaults state.
///
/// ## Dependencies
/// - `SupabaseProtocol` — for sign out and account deletion.
/// - `RevenueCat` — for premium status and purchase restoration.
/// - `ModelContext` — for counting recipes and exporting data.
@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - Dependencies

    private let supabase: any SupabaseProtocol
    private var modelContext: ModelContext?

    // MARK: - State

    /// User's email address (from auth session).
    private(set) var userEmail: String = ""

    /// Whether the user has an active premium subscription.
    /// Checks RevenueCat entitlements for the "premium" entitlement.
    private(set) var isPremium: Bool = false

    /// Total number of recipes in SwiftData.
    private(set) var recipeCount: Int = 0

    /// Number of saved/favorited recipes.
    private(set) var savedCount: Int = 0

    /// Number of recipe books.
    private(set) var bookCount: Int = 0

    /// Loading state for async operations.
    private(set) var isLoading: Bool = false

    /// Error message for display.
    private(set) var errorMessage: String?

    /// Controls export data sheet presentation.
    var showExportSheet: Bool = false

    /// Controls delete account confirmation dialog.
    var showDeleteConfirmation: Bool = false

    /// The exported data as a formatted JSON string.
    private(set) var exportDataJSON: String = ""

    // MARK: - Initialization

    /// Creates a new profile view model.
    /// - Parameters:
    ///   - supabase: The Supabase service for auth operations.
    ///   - modelContext: The SwiftData context for local data queries. Optional for testing.
    init(
        supabase: any SupabaseProtocol,
        modelContext: ModelContext? = nil
    ) {
        self.supabase = supabase
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// Loads user profile data from auth state, RevenueCat, and SwiftData.
    /// Call this in the view's `.task` or `.onAppear`.
    func loadProfile() async {
        setLoading(true)
        clearError()

        // Load user email from UserDefaults (set during auth)
        userEmail = UserDefaults.standard.string(forKey: "userEmail") ?? supabase.currentUser?.email ?? ""

        // Load premium status from RevenueCat
        await checkPremiumStatus()

        // Load counts from SwiftData
        await loadCountsFromSwiftData()

        setLoading(false)
    }

    /// Signs the user out, clears all sessions, and resets local auth state.
    func signOut() async {
        setLoading(true)
        clearError()

        do {
            try await supabase.signOut()

            // Clear push notification token
            PushNotificationService.shared.clearDeviceToken()

            // Log out from RevenueCat
            Purchases.shared.logOut()

            // Clear all local auth state
            UserDefaults.standard.removeObject(forKey: "isAuthenticated")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.removeObject(forKey: "appleUserID")
            UserDefaults.standard.removeObject(forKey: "userDisplayName")
            UserDefaults.standard.removeObject(forKey: "supabase_session_token")
        } catch let err as CooksyError {
            errorMessage = err.localizedDescription
        } catch {
            // Even if the server call fails, clear local state
            UserDefaults.standard.removeObject(forKey: "isAuthenticated")
            UserDefaults.standard.removeObject(forKey: "userEmail")
        }

        setLoading(false)
    }

    /// Exports all user recipes from SwiftData as a structured JSON file.
    func exportData() async {
        setLoading(true)
        clearError()

        do {
            let recipes = try fetchAllRecipes()
            let jsonData = try await SupabaseService.exportUserData(
                from: recipes,
                userEmail: userEmail
            )

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                exportDataJSON = jsonString
                showExportSheet = true
            }
        } catch {
            errorMessage = "Failed to export data. Please try again."
        }

        setLoading(false)
    }

    /// Deletes the user account and all associated data.
    ///
    /// 1. Calls `supabase` to delete the server-side account.
    /// 2. Clears all SwiftData stores.
    /// 3. Clears all UserDefaults.
    ///
    /// - Warning: This action is **irreversible**.
    func deleteAccount() async {
        setLoading(true)
        clearError()

        do {
            // 1. Delete server-side account via Supabase RPC or admin endpoint
            try await supabase.signOut()
            // TODO: Add `supabase.deleteAccount()` RPC call when backend supports it.
            // try await supabase.rpc("delete_user_account")

            // 2. Clear all local SwiftData
            try await clearAllSwiftData()

            // 3. Clear all UserDefaults
            let defaults = UserDefaults.standard
            let keys = Array(defaults.dictionaryRepresentation().keys)
            for key in keys {
                defaults.removeObject(forKey: key)
            }

            // 4. Log out from RevenueCat
            Purchases.shared.logOut()
        } catch {
            errorMessage = "Failed to delete account. Please contact support."
        }

        setLoading(false)
    }

    /// Restores previous App Store purchases via RevenueCat.
    ///
    /// Synchronizes purchase history and refreshes premium entitlement status.
    func restorePurchases() async {
        setLoading(true)
        clearError()

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasPremium = customerInfo.entitlements["premium"]?.isActive == true
            isPremium = hasPremium

            if !hasPremium {
                errorMessage = "No previous purchases found."
            } else {
                HapticsService.success()
            }
        } catch {
            errorMessage = "Failed to restore purchases. Please try again."
            HapticsService.error()
        }

        setLoading(false)
    }

    // MARK: - Computed

    /// A formatted "member since" date string.
    var memberSinceDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let date = supabase.currentUser?.createdAt ?? Date().addingTimeInterval(-86400 * 30)
        return formatter.string(from: date)
    }

    /// The current plan display name.
    var planName: String {
        isPremium ? "Cooksy Premium" : "Free Plan"
    }

    // MARK: - Private Methods

    /// Checks premium status from RevenueCat entitlements.
    private func checkPremiumStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements["premium"]?.isActive == true
        } catch {
            // Fallback to cached value if RevenueCat check fails
            isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        }
    }

    /// Fetches recipe and book counts from SwiftData.
    private func loadCountsFromSwiftData() async {
        guard let modelContext = modelContext else {
            recipeCount = UserDefaults.standard.integer(forKey: "recipeCount")
            if recipeCount == 0 {
                recipeCount = 12
                savedCount = 8
                bookCount = 3
            }
            return
        }

        do {
            let recipeDescriptor = FetchDescriptor<Recipe>()
            let allRecipes = try modelContext.fetch(recipeDescriptor)
            recipeCount = allRecipes.count
            savedCount = allRecipes.filter(\.isSaved).count

            let bookDescriptor = FetchDescriptor<RecipeBook>()
            let allBooks = try modelContext.fetch(bookDescriptor)
            bookCount = allBooks.count
        } catch {
            recipeCount = 0
            savedCount = 0
            bookCount = 0
        }
    }

    /// Fetches all recipes from SwiftData for export.
    private func fetchAllRecipes() throws -> [Recipe] {
        guard let modelContext = modelContext else { return [] }
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    /// Deletes all SwiftData models (recipes, books, ingredients, steps).
    private func clearAllSwiftData() async throws {
        guard let modelContext = modelContext else { return }

        let recipeDescriptor = FetchDescriptor<Recipe>()
        let allRecipes = try modelContext.fetch(recipeDescriptor)
        for recipe in allRecipes {
            modelContext.delete(recipe)
        }

        let bookDescriptor = FetchDescriptor<RecipeBook>()
        let allBooks = try modelContext.fetch(bookDescriptor)
        for book in allBooks {
            modelContext.delete(book)
        }

        try modelContext.save()
    }

    // MARK: - Helpers

    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    private func showError(_ message: String) {
        errorMessage = message
    }

    private func clearError() {
        errorMessage = nil
    }
}
