import Foundation
import RevenueCat

// MARK: - Subscription ViewModel
/// Manages subscription state using REAL RevenueCat SDK for in-app purchases.
/// Handles loading offerings, purchasing packages, restoring purchases, and
/// checking premium entitlement status.
///
/// ## RevenueCat Integration
/// This ViewModel integrates with the RevenueCat iOS SDK (v5.0+) for:
/// - Loading product offerings configured in the RevenueCat dashboard
/// - Initiating and processing in-app purchases
/// - Restoring previous purchases via the App Store receipt
/// - Checking premium entitlement status via `CustomerInfo`
///
/// ## Setup
/// 1. Configure RevenueCat API key in `CooksyApp.configureRevenueCat()`
/// 2. Create products in App Store Connect
/// 3. Configure offerings in RevenueCat dashboard
/// 4. Map your entitlement ID to `"premium"` in RevenueCat
@MainActor
@Observable
final class SubscriptionViewModel {

    // MARK: - Types

    /// Available subscription plans for UI display.
    enum Plan: String, CaseIterable, Identifiable {
        case free = "Free"
        case monthly = "Monthly"
        case annual = "Annual"

        var id: String { rawValue }

        var name: String { rawValue }

        var price: String {
            switch self {
            case .free: return "$0/month"
            case .monthly: return "$6.99/month"
            case .annual: return "$4.99/month"
            }
        }

        var annualPrice: String {
            switch self {
            case .free: return "Free forever"
            case .monthly: return "$83.88/year"
            case .annual: return "$59.88/year"
            }
        }

        var savings: String? {
            switch self {
            case .free: return nil
            case .monthly: return nil
            case .annual: return "Save 28%"
            }
        }

        var badge: String? {
            switch self {
            case .free: return nil
            case .monthly: return nil
            case .annual: return "Best Value"
            }
        }

        var description: String {
            switch self {
            case .free: return "Basic recipe management"
            case .monthly: return "Full access, billed monthly"
            case .annual: return "Full access, billed annually"
            }
        }
    }

    /// A feature comparison row for the subscription view.
    struct PlanFeature: Identifiable {
        let id = UUID()
        let name: String
        let free: Bool
        let premium: Bool
    }

    // MARK: - State

    /// RevenueCat offerings loaded from the dashboard.
    var offerings: [Package] = []

    /// Current customer info including entitlements.
    var customerInfo: CustomerInfo?

    /// Loading state for async operations.
    private(set) var isLoading: Bool = false

    /// Whether a purchase is currently in progress.
    private(set) var isPurchasing: Bool = false

    /// Currently selected plan in the UI.
    var selectedPlan: Plan = .annual

    /// Error message to display to the user.
    private(set) var error: String?

    /// Feature comparison data for the subscription view.
    var allFeatures: [PlanFeature] = [
        PlanFeature(name: "Import recipes from videos", free: true, premium: true),
        PlanFeature(name: "Save unlimited recipes", free: true, premium: true),
        PlanFeature(name: "Create recipe books", free: false, premium: true),
        PlanFeature(name: "Export recipe data", free: false, premium: true),
        PlanFeature(name: "Priority support", free: false, premium: true),
        PlanFeature(name: "Early access to new features", free: false, premium: true),
    ]

    /// Feature list for backward compatibility with existing views.
    var planFeatures: [(name: String, free: Bool, premium: Bool)] {
        allFeatures.map { ($0.name, $0.free, $0.premium) }
    }

    /// Whether the user currently has an active premium subscription.
    /// Checks the `"premium"` entitlement via RevenueCat `CustomerInfo`.
    var isPremium: Bool {
        customerInfo?.entitlements["premium"]?.isActive == true
    }

    // MARK: - RevenueCat API

    /// Loads offerings and customer info from RevenueCat.
    ///
    /// Fetches the current offerings (products) and customer info (entitlements)
    /// from RevenueCat. Call this when the subscription view appears.
    func load() async {
        isLoading = true
        error = nil
        do {
            customerInfo = try await Purchases.shared.customerInfo()
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                self.offerings = current.availablePackages
            }
        } catch {
            self.error = "Unable to load subscription options. Please check your connection."
        }
        isLoading = false
    }

    /// Purchases a RevenueCat package.
    ///
    /// - Parameter package: The RevenueCat `Package` to purchase (obtained from `offerings`)
    func purchase(_ package: Package) async {
        isPurchasing = true
        error = nil
        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo
            if !result.userCancelled {
                // Purchase completed — entitlements updated in customerInfo
                HapticsService.heavy()
            }
        } catch {
            self.error = "Purchase failed. Please try again."
            HapticsService.error()
        }
        isPurchasing = false
    }

    /// Purchases a plan by type (convenience method for UI).
    ///
    /// Maps the plan enum to a RevenueCat package and initiates the purchase.
    /// Falls back to the first available package if no exact match is found.
    ///
    /// - Parameter plan: The plan to purchase
    func purchase(plan: Plan) async {
        guard plan != .free else { return }

        // Find the matching package from offerings based on subscription period
        let targetPackage: Package? = offerings.first { pkg in
            guard let period = pkg.storeProduct.subscriptionPeriod else { return false }
            switch plan {
            case .monthly:
                return period.unit == .month && period.value == 1
            case .annual:
                return period.unit == .year && period.value == 1
            case .free:
                return false
            }
        } ?? offerings.first

        guard let targetPackage else {
            error = "Subscription options not available. Please try again later."
            return
        }

        await purchase(targetPackage)
    }

    /// Restores previous purchases from the App Store via RevenueCat.
    ///
    /// Synchronizes the user's purchase history with RevenueCat and
    /// refreshes the premium entitlement status.
    func restorePurchases() async {
        isLoading = true
        error = nil
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
            if !isPremium {
                error = "No previous purchases found."
            } else {
                HapticsService.success()
            }
        } catch {
            self.error = "Restore failed. Please try again."
            HapticsService.error()
        }
        isLoading = false
    }

    /// Opens the App Store subscription management page.
    ///
    /// Takes the user to Apple's subscription management screen where
    /// they can cancel, change, or view their subscription details.
    func manageSubscription() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }
}
