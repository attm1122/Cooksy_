import Foundation
import RevenueCat

// MARK: - Subscription ViewModel
/// Manages subscription state using the RevenueCat SDK for in-app purchases.
///
/// ## RevenueCat Configuration
/// - **Offering**: `default` (configured in RevenueCat dashboard)
/// - **Products**: `monthly`, `yearly`, `lifetime`
/// - **Entitlement**: `cooksy_pro`
///
/// ## Supported Plans
/// | Plan | Identifier | Type |
/// |------|-----------|------|
/// | Free | `free` | No purchase required |
/// | Monthly | `monthly` | Auto-renewing subscription |
/// | Yearly | `yearly` | Auto-renewing subscription (best value) |
/// | Lifetime | `lifetime` | One-time purchase, permanent access |
@MainActor
@Observable
final class SubscriptionViewModel {

    // MARK: - Types

    /// Available subscription plans for UI display.
    enum Plan: String, CaseIterable, Identifiable, Sendable {
        case free = "Free"
        case monthly = "Monthly"
        case yearly = "Yearly"
        case lifetime = "Lifetime"

        var id: String { rawValue }

        var name: String { rawValue }

        /// RevenueCat package identifier used to map offerings to plans.
        var packageIdentifier: String {
            switch self {
            case .free: return ""
            case .monthly: return "$rc_monthly"
            case .yearly: return "$rc_annual"
            case .lifetime: return "$rc_lifetime"
            }
        }

        var description: String {
            switch self {
            case .free: return "Basic recipe management"
            case .monthly: return "Full access, billed monthly"
            case .yearly: return "Full access, billed annually"
            case .lifetime: return "Pay once, keep forever"
            }
        }

        var badge: String? {
            switch self {
            case .free: return nil
            case .monthly: return nil
            case .yearly: return "Best Value"
            case .lifetime: return "Forever"
            }
        }

        var savings: String? {
            switch self {
            case .free: return nil
            case .monthly: return nil
            case .yearly: return nil  // Dynamic savings computed from RevenueCat prices
            case .lifetime: return "Best Deal"
            }
        }
    }

    /// The RevenueCat entitlement identifier for premium access.
    static let entitlementIdentifier = "cooksy_pro"

    // MARK: - State

    /// RevenueCat offerings loaded from the dashboard.
    var offerings: [Package] = []

    /// The current RevenueCat offering (contains all packages).
    var currentOffering: Offering?

    /// Current customer info including entitlements.
    var customerInfo: CustomerInfo?

    /// Loading state for async operations.
    private(set) var isLoading: Bool = false

    /// Whether a purchase is currently in progress.
    private(set) var isPurchasing: Bool = false

    /// Currently selected plan in the UI.
    var selectedPlan: Plan = .yearly

    /// Error message to display to the user.
    private(set) var error: String?

    /// Whether an error alert should be shown.
    private(set) var showError: Bool = false

    /// Feature comparison data for the subscription view.
    var allFeatures: [PlanFeature] = [
        PlanFeature(name: "Import recipes from videos", free: true, pro: true),
        PlanFeature(name: "Save unlimited recipes", free: true, pro: true),
        PlanFeature(name: "Create recipe books", free: false, pro: true),
        PlanFeature(name: "Cook-along video sync", free: false, pro: true),
        PlanFeature(name: "Export recipe data", free: false, pro: true),
        PlanFeature(name: "Priority support", free: false, pro: true),
        PlanFeature(name: "Early access to new features", free: false, pro: true),
    ]

    // MARK: - Computed Properties

    /// Whether the user currently has an active Cooksy Pro entitlement.
    var isPro: Bool {
        customerInfo?.entitlements[Self.entitlementIdentifier]?.isActive == true
    }

    /// The expiration date of the current subscription (if applicable).
    var expirationDate: Date? {
        customerInfo?.entitlements[Self.entitlementIdentifier]?.expirationDate
    }

    /// Whether the current subscription will auto-renew.
    var willAutoRenew: Bool {
        guard let entitlement = customerInfo?.entitlements[Self.entitlementIdentifier] else { return false }
        return entitlement.periodType == .normal
    }

    /// Feature list for backward compatibility with existing views.
    var planFeatures: [(name: String, free: Bool, premium: Bool)] {
        allFeatures.map { ($0.name, $0.free, $0.pro) }
    }

    // MARK: - RevenueCat API

    /// Loads offerings and customer info from RevenueCat.
    ///
    /// Fetches the current offerings (products) and customer info (entitlements)
    /// from RevenueCat. Call this when the subscription view appears.
    func load() async {
        isLoading = true
        clearError()

        do {
            // Fetch customer info (entitlements)
            customerInfo = try await Purchases.shared.customerInfo()

            // Fetch offerings (products)
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                self.currentOffering = current
                self.offerings = current.availablePackages
            } else {
                // Fallback: if no current offering, show all available packages
                self.offerings = offerings.all.values.flatMap(\.availablePackages)
                if let firstOffering = offerings.all.values.first {
                    self.currentOffering = firstOffering
                }
            }
        } catch let error as RevenueCat.ErrorCode {
            handleRevenueCatError(error)
        } catch {
            setError("Unable to load subscriptions. Please check your connection and try again.")
        }

        isLoading = false
    }

    /// Purchases a plan by type.
    ///
    /// Maps the plan enum to a RevenueCat package and initiates the purchase.
    /// - Parameter plan: The plan to purchase
    func purchase(plan: Plan) async {
        guard plan != .free else { return }

        // Find the matching package from offerings
        guard let package = findPackage(for: plan) else {
            setError("This subscription option is not available right now. Please try again later.")
            return
        }

        await purchase(package)
    }

    /// Purchases a specific RevenueCat package.
    ///
    /// - Parameter package: The RevenueCat `Package` to purchase
    func purchase(_ package: Package) async {
        isPurchasing = true
        clearError()

        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo

            if result.userCancelled {
                // User cancelled — no error, just reset state
            } else {
                // Purchase successful
                HapticsService.heavy()
                AnalyticsService.shared.track("purchase_completed", properties: [
                    "product_id": package.storeProduct.productIdentifier,
                    "plan": package.identifier
                ])
            }
        } catch let error as RevenueCat.ErrorCode {
            handleRevenueCatError(error)
            HapticsService.error()
        } catch {
            setError("Purchase failed. Please try again.")
            HapticsService.error()
            AnalyticsService.shared.track("purchase_failed", properties: ["reason": error.localizedDescription])
        }

        isPurchasing = false
    }

    /// Restores previous purchases from the App Store via RevenueCat.
    func restorePurchases() async {
        isLoading = true
        clearError()

        do {
            customerInfo = try await Purchases.shared.restorePurchases()
            if !isPro {
                setError("No previous purchases found on this account.")
            } else {
                HapticsService.success()
                AnalyticsService.shared.track("restore_purchases_success")
            }
        } catch {
            setError("Restore failed. Please make sure you're signed in with the same Apple ID used for the original purchase.")
            HapticsService.error()
        }

        isLoading = false
    }

    /// Refreshes customer info from RevenueCat.
    ///
    /// Use this after app becomes active or when checking entitlement status.
    func refreshCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            #if DEBUG
            print("[SubscriptionViewModel] Failed to refresh customer info: \(error.localizedDescription)")
            #endif
        }
    }

    /// Opens the App Store subscription management page.
    func manageSubscription() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }

    // MARK: - RevenueCat Paywall

    /// Whether the RevenueCat Paywall should be shown.
    private(set) var showPaywall: Bool = false

    /// Presents the RevenueCat Paywall for the current offering.
    func presentPaywall() {
        showPaywall = true
        AnalyticsService.shared.track("paywall_presented")
    }

    /// Dismisses the RevenueCat Paywall.
    func dismissPaywall() {
        showPaywall = false
    }

    // MARK: - Customer Center

    /// Whether the Customer Center should be shown.
    private(set) var showCustomerCenter: Bool = false

    /// Presents the RevenueCat Customer Center.
    ///
    /// The Customer Center allows users to:
    /// - Manage their subscription
    /// - Restore purchases
    /// - Request a refund
    /// - Contact support
    func presentCustomerCenter() {
        showCustomerCenter = true
    }

    /// Dismisses the Customer Center.
    func dismissCustomerCenter() {
        showCustomerCenter = false
    }

    // MARK: - Package Resolution

    /// Finds the RevenueCat package matching a given plan.
    ///
    /// Attempts to match by RevenueCat's standard identifiers, then falls back
    /// to period-based matching for backward compatibility.
    private func findPackage(for plan: Plan) -> Package? {
        // Try to match by RevenueCat standard identifier
        if let match = offerings.first(where: { $0.identifier == plan.packageIdentifier }) {
            return match
        }

        // Fall back to period-based matching
        return offerings.first { pkg in
            guard let period = pkg.storeProduct.subscriptionPeriod else {
                // Lifetime products have no subscription period
                return plan == .lifetime
            }
            switch plan {
            case .monthly:
                return period.unit == .month && period.value == 1
            case .yearly:
                return period.unit == .year && period.value == 1
            case .lifetime:
                return false // Has period, so not lifetime
            case .free:
                return false
            }
        } ?? (plan == .lifetime ? offerings.first { $0.packageType == .lifetime } : nil)
    }

    // MARK: - Error Handling

    private func handleRevenueCatError(_ error: RevenueCat.ErrorCode) {
        switch error {
        case .purchaseCancelledError:
            // User cancelled — no error to show
            clearError()
        case .purchaseNotAllowedError:
            setError("Purchases are not allowed on this device. Please check your parental control settings.")
        case .purchaseInvalidError:
            setError("This purchase is not valid. The product may have been removed from the store.")
        case .networkError:
            setError("Network error. Please check your internet connection and try again.")
        case .storeProblemError:
            setError("The App Store is experiencing issues. Please try again later.")
        case .receiptAlreadyInUseError:
            setError("This receipt is already in use by another account. Please restore purchases instead.")
        case .invalidCredentialsError:
            setError("Invalid credentials. Please sign in again.")
        case .missingReceiptFileError:
            setError("Purchase receipt not found. Please try restoring your purchases.")
        case .invalidReceiptError:
            setError("Invalid purchase receipt. Please contact support.")
        case .paymentPendingError:
            setError("Payment is pending. Your subscription will activate once the payment is processed.")
        case .productAlreadyPurchasedError:
            setError("You've already purchased this product. Please restore your purchases.")
        case .productNotAvailableForPurchaseError:
            setError("This product is not available for purchase. It may have been discontinued.")
        case .customerInfoError:
            setError("Unable to verify your subscription status. Please try again later.")
        @unknown default:
            setError("Something went wrong. Please try again.")
        }
    }

    private func setError(_ message: String) {
        error = message
        showError = true
    }

    private func clearError() {
        error = nil
        showError = false
    }

    // MARK: - Types

    /// A feature comparison row for the subscription view.
    struct PlanFeature: Identifiable {
        let id = UUID()
        let name: String
        let free: Bool
        let pro: Bool
    }
}
