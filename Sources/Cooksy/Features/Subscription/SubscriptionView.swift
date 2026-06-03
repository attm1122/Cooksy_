import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Subscription View
/// Complete subscription management screen with plan selection,
/// feature comparison, RevenueCat Paywall, and Customer Center integration.
struct SubscriptionView: View {

    @State private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss

    private let termsURL = AppLinks.terms
    private let privacyURL = AppLinks.privacy

    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cooksBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        planIndicatorView
                        planSelectorView
                            .padding(.horizontal)
                        featureComparisonView
                            .padding(.horizontal)
                        ctaButtonView
                            .padding(.horizontal)
                        secondaryActionsView
                        customerCenterButton
                        finePrintView
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Cooksy Pro")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier(AccessibilityID.subscriptionView)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticsService.light()
                        dismiss()
                    }
                    .foregroundStyle(.brand)
                    .accessibilityLabel("Close subscription screen")
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showTerms) {
            SafariView(url: termsURL)
        }
        .sheet(isPresented: $showPrivacy) {
            SafariView(url: privacyURL)
        }
        // RevenueCat Paywall
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
                .onDismiss {
                    viewModel.dismissPaywall()
                    Task { await viewModel.refreshCustomerInfo() }
                }
        }
        // RevenueCat Customer Center
        .sheet(isPresented: $viewModel.showCustomerCenter) {
            CustomerCenterView()
                .onDismiss {
                    viewModel.dismissCustomerCenter()
                    Task { await viewModel.refreshCustomerInfo() }
                }
        }
        // Error alert
        .alert("Subscription", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "An unexpected error occurred.")
        }
        .overlay(loadingOverlay)
    }

    // MARK: - Current Plan Indicator

    private var planIndicatorView: some View {
        HStack(spacing: 8) {
            if viewModel.isPro {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.brand)
                    .decorative()
                if let expiry = viewModel.expirationDate, viewModel.willAutoRenew {
                    Text("Cooksy Pro — Renews \(expiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(.cooksCallout.weight(.medium))
                        .foregroundStyle(.ink)
                        .scalableText()
                } else if viewModel.willAutoRenew {
                    Text("Cooksy Pro Active")
                        .font(.cooksCallout.weight(.medium))
                        .foregroundStyle(.ink)
                        .scalableText()
                } else {
                    Text("Cooksy Pro Active")
                        .font(.cooksCallout.weight(.medium))
                        .foregroundStyle(.ink)
                        .scalableText()
                }
            } else {
                Image(systemName: "sparkles")
                    .foregroundStyle(.brand)
                    .decorative()
                Text("Upgrade to unlock all features")
                    .font(.cooksCallout.weight(.medium))
                    .foregroundStyle(.ink)
                    .scalableText()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(viewModel.isPro ? Color.brand.opacity(0.15) : Color.brand.opacity(0.10))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Plan Selector

    private var planSelectorView: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SubscriptionViewModel.Plan.allCases) { plan in
                AccessiblePlanCard(
                    plan: plan,
                    isSelected: viewModel.selectedPlan == plan,
                    isPro: viewModel.isPro,
                    offering: viewModel.currentOffering
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectedPlan = plan
                    }
                    HapticsService.medium()
                    let price = priceDisplay(for: plan)
                    announceToVoiceOver("\(plan.rawValue) plan selected, \(price)")
                }
                .accessibilityIdentifier("\(AccessibilityID.planCardPrefix)\(plan.rawValue)")
            }
        }
    }

    // MARK: - Feature Comparison

    private var featureComparisonView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's included")
                .font(.cooksH3)
                .foregroundStyle(.ink)
                .accessibleHeading(.h2)

            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Feature")
                        .font(.cooksCaption.weight(.medium))
                        .foregroundStyle(.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Free")
                        .font(.cooksCaption.weight(.medium))
                        .foregroundStyle(.muted)
                        .frame(width: 50, alignment: .center)

                    Text("Pro")
                        .font(.cooksCaption.weight(.medium))
                        .foregroundStyle(.brand)
                        .frame(width: 50, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cooksBackground.opacity(0.5))

                // Feature rows
                ForEach(Array(viewModel.planFeatures.enumerated()), id: \.offset) { index, feature in
                    AccessibleFeatureRow(
                        name: feature.name,
                        freeAvailable: feature.free,
                        premiumAvailable: feature.premium
                    )

                    if index < viewModel.planFeatures.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                            .decorative()
                    }
                }
            }
            .background(Color.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - CTA Button

    private var ctaButtonView: some View {
        Group {
            if viewModel.isPro {
                PrimaryButton("Manage Subscription", icon: "arrow.up.forward.app") {
                    HapticsService.medium()
                    viewModel.manageSubscription()
                }
                .accessibilityLabel("Manage your subscription in the App Store")
            } else if viewModel.selectedPlan == .free {
                SecondaryButton("Continue with Free", isEnabled: false) {
                    HapticsService.light()
                    dismiss()
                }
                .accessibilityLabel("Continue with free plan")
            } else {
                PrimaryButton(subscribeButtonTitle) {
                    HapticsService.heavy()
                    Task {
                        // Require biometric auth for subscription purchase
                        let authenticated = await BiometricAuthService.shared.authenticate(
                            reason: "Authenticate to confirm your Cooksy Pro subscription."
                        )
                        guard authenticated else { return }

                        // Then proceed with purchase
                        await viewModel.purchase(plan: viewModel.selectedPlan)
                    }
                }
                .accessibilityLabel("Subscribe to \(viewModel.selectedPlan.rawValue)")
                .accessibilityIdentifier(AccessibilityID.subscribeButton)
            }
        }
    }

    private var subscribeButtonTitle: String {
        if let pkg = findPackage(for: viewModel.selectedPlan) {
            return "Subscribe — \(pkg.localizedPriceString)"
        }
        return "Subscribe"
    }

    // MARK: - Secondary Actions

    private var secondaryActionsView: some View {
        VStack(spacing: 8) {
            if !viewModel.isPro {
                TertiaryButton("Restore Purchases", icon: "arrow.clockwise") {
                    HapticsService.medium()
                    Task { await viewModel.restorePurchases() }
                    announceToVoiceOver("Restoring purchases")
                }
                .accessibilityLabel("Restore previous purchases")
            }
        }
    }

    // MARK: - Customer Center

    private var customerCenterButton: some View {
        Group {
            if viewModel.isPro {
                TertiaryButton("Customer Center", icon: "person.crop.circle") {
                    HapticsService.light()
                    viewModel.presentCustomerCenter()
                }
                .accessibilityLabel("Open Customer Center to manage your subscription, request refunds, or contact support")
            }
        }
    }

    // MARK: - Fine Print

    private var finePrintView: some View {
        VStack(spacing: 12) {
            Text(finePrintText)
                .font(.caption2)
                .foregroundStyle(.muted.opacity(0.7))
                .multilineTextAlignment(.center)
                .scalableText()

            HStack(spacing: 4) {
                Button("Terms of Service") { showTerms = true }
                    .font(.cooksMicro)
                    .foregroundStyle(.brand)
                    .accessibilityLabel("View Terms of Service")

                Text("·")
                    .font(.cooksMicro)
                    .foregroundStyle(.muted)
                    .decorative()

                Button("Privacy Policy") { showPrivacy = true }
                    .font(.cooksMicro)
                    .foregroundStyle(.brand)
                    .accessibilityLabel("View Privacy Policy")
            }
        }
    }

    private var finePrintText: String {
        if viewModel.selectedPlan != .free {
            return "Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage or cancel your subscription in your Account Settings."
        } else {
            return "Upgrade to Cooksy Pro anytime to unlock all features."
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.brand)
                            .accessibilityLabel("Loading subscription details")
                    )
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Helpers

    /// Finds the RevenueCat package for a given plan.
    private func findPackage(for plan: SubscriptionViewModel.Plan) -> Package? {
        // Try standard identifier
        if let match = viewModel.offerings.first(where: { $0.identifier == plan.packageIdentifier }) {
            return match
        }
        // Fall back to period matching
        return viewModel.offerings.first { pkg in
            guard let period = pkg.storeProduct.subscriptionPeriod else {
                return false
            }
            switch plan {
            case .monthly: return period.unit == .month && period.value == 1
            case .yearly: return period.unit == .year && period.value == 1
            case .free: return false
            }
        }
    }

    /// Returns a human-readable price string for a plan.
    private func priceDisplay(for plan: SubscriptionViewModel.Plan) -> String {
        guard let pkg = findPackage(for: plan) else { return plan.rawValue }
        return pkg.localizedPriceString
    }
}

// MARK: - Accessible Plan Card

/// A selectable card representing a subscription plan with full VoiceOver support.
struct AccessiblePlanCard: View {
    let plan: SubscriptionViewModel.Plan
    let isSelected: Bool
    let isPro: Bool
    let offering: Offering?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Badge
                if let badge = plan.badge {
                    Text(badge)
                        .font(.cooksMicro.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isSelected ? Color.brand : Color.brand.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Color.clear.frame(height: 20).decorative()
                }

                // Plan name
                Text(plan.rawValue)
                    .font(.cooksCallout.weight(.semibold))
                    .foregroundStyle(isSelected ? .ink : .muted)
                    .scalableText()

                // Price from RevenueCat
                Text(priceText)
                    .font(.cooksBodyBold)
                    .foregroundStyle(isSelected ? .brand : .ink)
                    .scalableText()

                // Description
                Text(plan.description)
                    .font(.cooksMicro)
                    .foregroundStyle(.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 28)

                // Savings
                if let savings = plan.savings {
                    Text(savings)
                        .font(.cooksMicro.weight(.medium))
                        .foregroundStyle(.cooksSuccess)
                        .scalableText()
                } else {
                    Color.clear.frame(height: 14).decorative()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.brand.opacity(0.12) : Color.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.brand)
                        .font(.cooksCallout)
                        .offset(x: -6, y: 6)
                        .decorative()
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(plan == .free && !isPro && isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.rawValue), \(priceText), \(plan.description)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select")
    }

    private var priceText: String {
        // Find the package for this plan
        let pkg = offering?.availablePackages.first { pkg in
            if pkg.identifier == plan.packageIdentifier { return true }
            guard let period = pkg.storeProduct.subscriptionPeriod else {
                return false
            }
            switch plan {
            case .monthly: return period.unit == .month && period.value == 1
            case .yearly: return period.unit == .year && period.value == 1
            case .free: return false
            }
        }

        guard let package = pkg else { return plan == .free ? "Free" : "—" }

        return package.localizedPriceString
    }
}

// MARK: - Accessible Feature Row

/// A single feature row in the comparison list with VoiceOver-friendly labels.
struct AccessibleFeatureRow: View {
    let name: String
    let freeAvailable: Bool
    let premiumAvailable: Bool

    var body: some View {
        HStack {
            Text(name)
                .font(.cooksCallout)
                .foregroundStyle(.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scalableText()

            Image(systemName: freeAvailable ? "checkmark" : "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(freeAvailable ? .green : .red.opacity(0.5))
                .frame(width: 50, alignment: .center)
                .decorative()

            Image(systemName: premiumAvailable ? "checkmark" : "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(premiumAvailable ? .green : .red.opacity(0.5))
                .frame(width: 50, alignment: .center)
                .decorative()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(freeAvailable ? "included" : "not included") in Free, \(premiumAvailable ? "included" : "not included") in Pro")
    }
}

// MARK: - Previews

#Preview("SubscriptionView - Not Pro") {
    SubscriptionView()
}

#Preview("SubscriptionView - Pro") {
    SubscriptionView()
}
