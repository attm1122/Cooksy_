import XCTest
@testable import Cooksy

// MARK: - SubscriptionViewModelTests
/// Comprehensive unit tests for the SubscriptionViewModel subscription state management.
///
/// Tests cover the Plan enum (all cases, rawValue, id, name, description, badge, savings,
/// packageIdentifier), entitlement identifier, initial state, computed properties, and
/// feature comparison data — all without requiring RevenueCat SDK connectivity.
@MainActor
final class SubscriptionViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: SubscriptionViewModel!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        sut = SubscriptionViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Plan Enum Case Tests

    func test_planEnum_allCases() {
        let allCases = SubscriptionViewModel.Plan.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.free))
        XCTAssertTrue(allCases.contains(.monthly))
        XCTAssertTrue(allCases.contains(.yearly))
        XCTAssertTrue(allCases.contains(.lifetime))
    }

    func test_planEnum_freeRawValue() {
        XCTAssertEqual(SubscriptionViewModel.Plan.free.rawValue, "Free")
    }

    func test_planEnum_monthlyRawValue() {
        XCTAssertEqual(SubscriptionViewModel.Plan.monthly.rawValue, "Monthly")
    }

    func test_planEnum_yearlyRawValue() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.rawValue, "Yearly")
    }

    func test_planEnum_lifetimeRawValue() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.rawValue, "Lifetime")
    }

    // MARK: - Plan Enum Identifiable

    func test_planEnum_freeId() {
        XCTAssertEqual(SubscriptionViewModel.Plan.free.id, "Free")
    }

    func test_planEnum_monthlyId() {
        XCTAssertEqual(SubscriptionViewModel.Plan.monthly.id, "Monthly")
    }

    func test_planEnum_yearlyId() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.id, "Yearly")
    }

    func test_planEnum_lifetimeId() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.id, "Lifetime")
    }

    func test_planEnum_idEqualsRawValue() {
        for plan in SubscriptionViewModel.Plan.allCases {
            XCTAssertEqual(plan.id, plan.rawValue)
        }
    }

    // MARK: - Plan Name Tests

    func test_planName_free() {
        XCTAssertEqual(SubscriptionViewModel.Plan.free.name, "Free")
    }

    func test_planName_monthly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.monthly.name, "Monthly")
    }

    func test_planName_yearly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.name, "Yearly")
    }

    func test_planName_lifetime() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.name, "Lifetime")
    }

    func test_planName_equalsRawValue() {
        for plan in SubscriptionViewModel.Plan.allCases {
            XCTAssertEqual(plan.name, plan.rawValue)
        }
    }

    // MARK: - Plan Description Tests

    func test_planDescription_free() {
        XCTAssertEqual(SubscriptionViewModel.Plan.free.description, "Basic recipe management")
    }

    func test_planDescription_monthly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.monthly.description, "Full access, billed monthly")
    }

    func test_planDescription_yearly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.description, "Full access, billed annually")
    }

    func test_planDescription_lifetime() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.description, "Pay once, keep forever")
    }

    func test_allPlanDescriptions_areNonEmpty() {
        for plan in SubscriptionViewModel.Plan.allCases {
            XCTAssertFalse(plan.description.isEmpty)
        }
    }

    // MARK: - Plan Badge Tests

    func test_planBadge_freeIsNil() {
        XCTAssertNil(SubscriptionViewModel.Plan.free.badge)
    }

    func test_planBadge_monthlyIsNil() {
        XCTAssertNil(SubscriptionViewModel.Plan.monthly.badge)
    }

    func test_planBadge_yearly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.badge, "Best Value")
    }

    func test_planBadge_lifetime() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.badge, "Forever")
    }

    // MARK: - Plan Savings Tests

    func test_planSavings_freeIsNil() {
        XCTAssertNil(SubscriptionViewModel.Plan.free.savings)
    }

    func test_planSavings_monthlyIsNil() {
        XCTAssertNil(SubscriptionViewModel.Plan.monthly.savings)
    }

    func test_planSavings_yearly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.savings, "Save 30%")
    }

    func test_planSavings_lifetime() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.savings, "Best Deal")
    }

    // MARK: - Plan Package Identifier Tests

    func test_planPackageIdentifier_free() {
        XCTAssertEqual(SubscriptionViewModel.Plan.free.packageIdentifier, "")
    }

    func test_planPackageIdentifier_monthly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.monthly.packageIdentifier, "$rc_monthly")
    }

    func test_planPackageIdentifier_yearly() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.packageIdentifier, "$rc_annual")
    }

    func test_planPackageIdentifier_lifetime() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.packageIdentifier, "$rc_lifetime")
    }

    func test_planPackageIdentifiers_areUnique() {
        let identifiers = SubscriptionViewModel.Plan.allCases.map(\.packageIdentifier)
        let uniqueIdentifiers = Set(identifiers)
        // free is "" which is unique
        XCTAssertEqual(uniqueIdentifiers.count, identifiers.count)
    }

    // MARK: - Entitlement Identifier

    func test_entitlementIdentifier() {
        XCTAssertEqual(SubscriptionViewModel.entitlementIdentifier, "cooksy_pro")
    }

    func test_entitlementIdentifier_isStatic() {
        // Verify it's accessible without an instance
        XCTAssertEqual(SubscriptionViewModel.entitlementIdentifier, "cooksy_pro")
    }

    func test_entitlementIdentifier_doesNotChange() {
        // Call multiple times, should always be the same
        let id1 = SubscriptionViewModel.entitlementIdentifier
        let id2 = SubscriptionViewModel.entitlementIdentifier
        XCTAssertEqual(id1, id2)
    }

    // MARK: - Initial State Tests

    func test_initialState_selectedPlanIsYearly() {
        XCTAssertEqual(sut.selectedPlan, .yearly)
    }

    func test_initialState_isLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialState_isPurchasingIsFalse() {
        XCTAssertFalse(sut.isPurchasing)
    }

    func test_initialState_offeringsIsEmpty() {
        XCTAssertTrue(sut.offerings.isEmpty)
    }

    func test_initialState_currentOfferingIsNil() {
        XCTAssertNil(sut.currentOffering)
    }

    func test_initialState_customerInfoIsNil() {
        XCTAssertNil(sut.customerInfo)
    }

    func test_initialState_errorIsNil() {
        XCTAssertNil(sut.error)
    }

    func test_initialState_showErrorIsFalse() {
        XCTAssertFalse(sut.showError)
    }

    func test_initialState_showPaywallIsFalse() {
        XCTAssertFalse(sut.showPaywall)
    }

    func test_initialState_showCustomerCenterIsFalse() {
        XCTAssertFalse(sut.showCustomerCenter)
    }

    // MARK: - isPro Computed Property

    func test_isPro_noCustomerInfo() {
        sut.customerInfo = nil
        XCTAssertFalse(sut.isPro)
    }

    func test_isPro_computedPropertyExists() {
        // isPro is a computed property; verify it doesn't crash
        _ = sut.isPro
    }

    // MARK: - expirationDate Computed Property

    func test_expirationDate_noCustomerInfo() {
        sut.customerInfo = nil
        XCTAssertNil(sut.expirationDate)
    }

    func test_expirationDate_computedPropertyExists() {
        _ = sut.expirationDate
    }

    // MARK: - willAutoRenew Computed Property

    func test_willAutoRenew_noCustomerInfo() {
        sut.customerInfo = nil
        XCTAssertFalse(sut.willAutoRenew)
    }

    func test_willAutoRenew_computedPropertyExists() {
        _ = sut.willAutoRenew
    }

    // MARK: - allFeatures Tests

    func test_allFeatures_count() {
        XCTAssertEqual(sut.allFeatures.count, 7)
    }

    func test_allFeatures_notEmpty() {
        XCTAssertFalse(sut.allFeatures.isEmpty)
    }

    func test_allFeatures_firstFeatureName() {
        let first = sut.allFeatures[0]
        XCTAssertEqual(first.name, "Import recipes from videos")
        XCTAssertTrue(first.free)
        XCTAssertTrue(first.pro)
    }

    func test_allFeatures_secondFeatureName() {
        let second = sut.allFeatures[1]
        XCTAssertEqual(second.name, "Save unlimited recipes")
        XCTAssertTrue(second.free)
        XCTAssertTrue(second.pro)
    }

    func test_allFeatures_thirdFeature() {
        let third = sut.allFeatures[2]
        XCTAssertEqual(third.name, "Create recipe books")
        XCTAssertFalse(third.free)
        XCTAssertTrue(third.pro)
    }

    func test_allFeatures_fourthFeature() {
        let fourth = sut.allFeatures[3]
        XCTAssertEqual(fourth.name, "Cook-along video sync")
        XCTAssertFalse(fourth.free)
        XCTAssertTrue(fourth.pro)
    }

    func test_allFeatures_fifthFeature() {
        let fifth = sut.allFeatures[4]
        XCTAssertEqual(fifth.name, "Export recipe data")
        XCTAssertFalse(fifth.free)
        XCTAssertTrue(fifth.pro)
    }

    func test_allFeatures_sixthFeature() {
        let sixth = sut.allFeatures[5]
        XCTAssertEqual(sixth.name, "Priority support")
        XCTAssertFalse(sixth.free)
        XCTAssertTrue(sixth.pro)
    }

    func test_allFeatures_seventhFeature() {
        let seventh = sut.allFeatures[6]
        XCTAssertEqual(seventh.name, "Early access to new features")
        XCTAssertFalse(seventh.free)
        XCTAssertTrue(seventh.pro)
    }

    func test_allFeatures_allHaveNames() {
        for feature in sut.allFeatures {
            XCTAssertFalse(feature.name.isEmpty)
        }
    }

    func test_allFeatures_freeFeaturesCount() {
        let freeFeatures = sut.allFeatures.filter(\.free)
        XCTAssertEqual(freeFeatures.count, 2)
    }

    func test_allFeatures_proFeaturesCount() {
        let proFeatures = sut.allFeatures.filter(\.pro)
        XCTAssertEqual(proFeatures.count, 7)
    }

    func test_allFeatures_freeOnlyFeaturesCount() {
        let freeOnly = sut.allFeatures.filter { $0.free && !$0.pro }
        XCTAssertEqual(freeOnly.count, 0)
    }

    func test_allFeatures_proOnlyFeaturesCount() {
        let proOnly = sut.allFeatures.filter { !$0.free && $0.pro }
        XCTAssertEqual(proOnly.count, 5)
    }

    // MARK: - planFeatures Backward Compatibility

    func test_planFeatures_countMatchesAllFeatures() {
        XCTAssertEqual(sut.planFeatures.count, sut.allFeatures.count)
    }

    func test_planFeatures_notEmpty() {
        XCTAssertFalse(sut.planFeatures.isEmpty)
    }

    func test_planFeatures_nameMatches() {
        for (index, feature) in sut.planFeatures.enumerated() {
            XCTAssertEqual(feature.name, sut.allFeatures[index].name)
        }
    }

    func test_planFeatures_freeMatches() {
        for (index, feature) in sut.planFeatures.enumerated() {
            XCTAssertEqual(feature.free, sut.allFeatures[index].free)
        }
    }

    func test_planFeatures_premiumMatchesPro() {
        for (index, feature) in sut.planFeatures.enumerated() {
            XCTAssertEqual(feature.premium, sut.allFeatures[index].pro)
        }
    }

    func test_planFeatures_isTupleArray() {
        // Verify the type transforms correctly
        let features = sut.planFeatures
        XCTAssertEqual(features.count, 7)
        for feature in features {
            XCTAssertFalse(feature.name.isEmpty)
        }
    }

    // MARK: - selectedPlan Changes

    func test_selectedPlan_canChangeToFree() {
        sut.selectedPlan = .free
        XCTAssertEqual(sut.selectedPlan, .free)
    }

    func test_selectedPlan_canChangeToMonthly() {
        sut.selectedPlan = .monthly
        XCTAssertEqual(sut.selectedPlan, .monthly)
    }

    func test_selectedPlan_canChangeToYearly() {
        sut.selectedPlan = .yearly
        XCTAssertEqual(sut.selectedPlan, .yearly)
    }

    func test_selectedPlan_canChangeToLifetime() {
        sut.selectedPlan = .lifetime
        XCTAssertEqual(sut.selectedPlan, .lifetime)
    }

    func test_selectedPlan_canCycle() {
        sut.selectedPlan = .monthly
        XCTAssertEqual(sut.selectedPlan, .monthly)
        sut.selectedPlan = .yearly
        XCTAssertEqual(sut.selectedPlan, .yearly)
        sut.selectedPlan = .lifetime
        XCTAssertEqual(sut.selectedPlan, .lifetime)
        sut.selectedPlan = .free
        XCTAssertEqual(sut.selectedPlan, .free)
    }

    // MARK: - PlanFeature Identifiable

    func test_planFeature_hasId() {
        for feature in sut.allFeatures {
            XCTAssertNotNil(feature.id)
        }
    }

    func test_planFeature_idsAreUnique() {
        let ids = sut.allFeatures.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(uniqueIds.count, ids.count)
    }

    // MARK: - Sheet State Tests

    func test_showPaywall_canBeSet() {
        sut.showPaywall = true
        XCTAssertTrue(sut.showPaywall)
        sut.showPaywall = false
        XCTAssertFalse(sut.showPaywall)
    }

    func test_showCustomerCenter_canBeSet() {
        sut.showCustomerCenter = true
        XCTAssertTrue(sut.showCustomerCenter)
        sut.showCustomerCenter = false
        XCTAssertFalse(sut.showCustomerCenter)
    }

    // MARK: - Error State Tests

    func test_errorCanBeSet() {
        sut.error = "Test error message"
        XCTAssertEqual(sut.error, "Test error message")
    }

    func test_errorCanBeCleared() {
        sut.error = "Test error"
        sut.error = nil
        XCTAssertNil(sut.error)
    }

    func test_showErrorCanBeSet() {
        sut.showError = true
        XCTAssertTrue(sut.showError)
        sut.showError = false
        XCTAssertFalse(sut.showError)
    }

    // MARK: - isLoading/isPurchasing Independence

    func test_isLoadingAndIsPurchasingAreIndependent() {
        sut.isLoading = true
        sut.isPurchasing = false
        XCTAssertTrue(sut.isLoading)
        XCTAssertFalse(sut.isPurchasing)

        sut.isLoading = false
        sut.isPurchasing = true
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.isPurchasing)
    }

    // MARK: - Offerings State

    func test_offeringsCanBeSet() {
        sut.offerings = []
        XCTAssertTrue(sut.offerings.isEmpty)
    }

    // MARK: - Plan Enum Hashable

    func test_planEnum_canBeUsedInSet() {
        var plans: Set<SubscriptionViewModel.Plan> = []
        plans.insert(.free)
        plans.insert(.monthly)
        plans.insert(.yearly)
        plans.insert(.lifetime)
        XCTAssertEqual(plans.count, 4)
    }

    func test_planEnum_equality() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly, .yearly)
        XCTAssertNotEqual(SubscriptionViewModel.Plan.yearly, .monthly)
    }

    func test_planEnum_rawValueInitialization() {
        let plan = SubscriptionViewModel.Plan(rawValue: "Yearly")
        XCTAssertEqual(plan, .yearly)
    }

    func test_planEnum_invalidRawValue() {
        let plan = SubscriptionViewModel.Plan(rawValue: "Invalid")
        XCTAssertNil(plan)
    }

    // MARK: - Entitlement Consistency

    func test_entitlementIdentifierUsedInComputedProperties() {
        // isPro, expirationDate, and willAutoRenew all reference the entitlement
        // Verify the identifier is consistent
        XCTAssertEqual(SubscriptionViewModel.entitlementIdentifier, "cooksy_pro")
    }

    // MARK: - Plan Comparison

    func test_freePlanHasNoPackage() {
        XCTAssertEqual(SubscriptionViewModel.Plan.free.packageIdentifier, "")
    }

    func test_monthlyPlanHasMonthlyPackage() {
        XCTAssertEqual(SubscriptionViewModel.Plan.monthly.packageIdentifier, "$rc_monthly")
    }

    func test_yearlyPlanHasAnnualPackage() {
        XCTAssertEqual(SubscriptionViewModel.Plan.yearly.packageIdentifier, "$rc_annual")
    }

    func test_lifetimePlanHasLifetimePackage() {
        XCTAssertEqual(SubscriptionViewModel.Plan.lifetime.packageIdentifier, "$rc_lifetime")
    }

    // MARK: - Feature Count Consistency

    func test_featureCountIsSeven() {
        XCTAssertEqual(sut.allFeatures.count, 7)
        XCTAssertEqual(sut.planFeatures.count, 7)
    }

    func test_twoFreeFeatures() {
        let freeFeatures = sut.allFeatures.filter(\.free)
        XCTAssertEqual(freeFeatures.count, 2)
        XCTAssertEqual(freeFeatures[0].name, "Import recipes from videos")
        XCTAssertEqual(freeFeatures[1].name, "Save unlimited recipes")
    }

    func test_fiveProOnlyFeatures() {
        let proOnly = sut.allFeatures.filter { !$0.free && $0.pro }
        XCTAssertEqual(proOnly.count, 5)
    }
}
