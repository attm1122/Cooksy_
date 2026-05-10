import SwiftUI

// MARK: - Subscription View
/// Complete subscription management screen with plan selection,
/// feature comparison, and purchase/restore functionality.
struct SubscriptionView: View {
    /// ViewModel managing subscription state
    @State private var viewModel = SubscriptionViewModel()
    
    /// Dismiss action for navigation
    @Environment(\.dismiss) private var dismiss

    /// URLs for legal documents
    private let termsURL = URL(string: "https://cooksy.app/terms")!
    private let privacyURL = URL(string: "https://cooksy.app/privacy")!

    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cooksBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: Plan Indicator Badge
                        planIndicatorView
                        
                        // MARK: Plan Selector
                        planSelectorView
                            .padding(.horizontal)
                        
                        // MARK: Feature Comparison
                        featureComparisonView
                            .padding(.horizontal)
                        
                        // MARK: CTA Button
                        ctaButtonView
                            .padding(.horizontal)
                        
                        // MARK: Restore / Manage
                        secondaryActionsView
                        
                        // MARK: Fine Print
                        finePrintView
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier(AccessibilityID.subscriptionView)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
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
        .overlay(loadingOverlay)
    }
    
    // MARK: - Current Plan Indicator
    
    private var planIndicatorView: some View {
        HStack(spacing: 8) {
            if viewModel.isPremium {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.brand)
                    .decorative()
                Text("Cooksy Premium Active")
                    .font(.cooksCallout.weight(.medium))
                    .foregroundStyle(.ink)
                    .scalableText()
                    .accessibilityLabel("Cooksy Premium subscription is active")
            } else {
                Image(systemName: "sparkles")
                    .foregroundStyle(.brand)
                    .decorative()
                Text("Upgrade to unlock all features")
                    .font(.cooksCallout.weight(.medium))
                    .foregroundStyle(.ink)
                    .scalableText()
                    .accessibilityLabel("Upgrade to Premium to unlock all features")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(viewModel.isPremium ? Color.brand.opacity(0.15) : Color.brand.opacity(0.10))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Plan Selector
    
    private var planSelectorView: some View {
        HStack(spacing: 12) {
            ForEach(SubscriptionViewModel.Plan.allCases) { plan in
                AccessiblePlanCard(
                    plan: plan,
                    isSelected: viewModel.selectedPlan == plan,
                    isPremium: viewModel.isPremium
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectedPlan = plan
                    }
                    announceToVoiceOver("\(plan.rawValue) plan selected, \(plan.price(from: viewModel.offeringPrices)) per month")
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
                .accessibilityLabel("Feature comparison, what's included")
            
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Feature")
                        .font(.cooksCaption.weight(.medium))
                        .foregroundStyle(.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Feature name")

                    Text("Free")
                        .font(.cooksCaption.weight(.medium))
                        .foregroundStyle(.muted)
                        .frame(width: 50, alignment: .center)
                        .accessibilityLabel("Free plan")

                    Text("Premium")
                        .font(.cooksCaption.weight(.medium))
                        .foregroundStyle(.brand)
                        .frame(width: 60, alignment: .center)
                        .accessibilityLabel("Premium plan")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cooksBackground.opacity(0.5))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Feature comparison header. Features compared between Free and Premium plans.")
                
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
            if viewModel.isPremium {
                PrimaryButton("Manage Subscription", icon: "arrow.up.forward.app") {
                    viewModel.manageSubscription()
                }
                .accessibilityLabel("Manage your subscription")
                .accessibilityHint("Opens the App Store subscription management page")
            } else if viewModel.selectedPlan == .free {
                SecondaryButton("Continue with Free", isEnabled: false) {
                    dismiss()
                }
                .accessibilityLabel("Continue with free plan")
                .accessibilityHint("Uses the free plan with limited features")
            } else {
                PrimaryButton("Subscribe") {
                    Task {
                        await viewModel.purchase(plan: viewModel.selectedPlan)
                    }
                }
                .accessibilityLabel("Subscribe to \(viewModel.selectedPlan.rawValue)")
                .accessibilityHint("Purchases the \(viewModel.selectedPlan.rawValue) subscription plan")
                .accessibilityIdentifier(AccessibilityID.subscribeButton)
            }
        }
    }
    
    // MARK: - Secondary Actions
    
    private var secondaryActionsView: some View {
        VStack(spacing: 8) {
            if !viewModel.isPremium {
                TertiaryButton("Restore Purchases", icon: "arrow.clockwise") {
                    Task { await viewModel.restorePurchases() }
                    announceToVoiceOver("Restoring purchases")
                }
                .accessibilityLabel("Restore previous purchases")
                .accessibilityHint("Restores any previously purchased subscriptions")
            }
        }
    }
    
    // MARK: - Fine Print
    
    private var finePrintView: some View {
        VStack(spacing: 12) {
            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.muted.opacity(0.7))
                .multilineTextAlignment(.center)
                .scalableText()
                .accessibilityLabel("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
            
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading")
            }
        }
    }
}

// MARK: - Accessible Plan Card

/// A selectable card representing a subscription plan with full VoiceOver support.
struct AccessiblePlanCard: View {
    let plan: SubscriptionViewModel.Plan
    let isSelected: Bool
    let isPremium: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Badge
                if let badge = plan.badge {
                    Text(badge)
                        .font(.cooksMicro.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .brand)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            isSelected ? Color.brand : Color.brand.opacity(0.15)
                        )
                        .clipShape(Capsule())
                        .accessibilityLabel("\(badge) value")
                } else {
                    Color.clear
                        .frame(height: 22)
                        .decorative()
                }
                
                // Plan name
                Text(plan.rawValue)
                    .font(.cooksCallout.weight(.semibold))
                    .foregroundStyle(isSelected ? .ink : .muted)
                    .scalableText()
                
                // Price
                Text(plan.price(from: viewModel.offeringPrices))
                    .font(.cooksBodyBold)
                    .foregroundStyle(isSelected ? .brand : .ink)
                    .scalableText()

                // Annual price detail
                Text(plan.annualPrice(from: viewModel.offeringAnnualPrices))
                    .font(.cooksMicro)
                    .foregroundStyle(.muted)
                    .scalableText()

                // Savings badge
                if let savings = plan.savings {
                    Text(savings)
                        .font(.cooksMicro.weight(.medium))
                        .foregroundStyle(.cooksSuccess)
                        .scalableText()
                        .accessibilityLabel("Save \(savings)")
                } else {
                    Color.clear
                        .frame(height: 16)
                        .decorative()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.brand.opacity(0.12) : Color.surfaceAlt)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.brand : Color.clear,
                        lineWidth: 2
                    )
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
        .disabled(plan == .free && !isPremium && isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.rawValue) plan, \(plan.price(from: viewModel.offeringPrices)) per month\(plan.savings.map { ", save \($0)" } ?? "")")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select the \(plan.rawValue) plan")
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
                .accessibilityLabel("Feature: \(name)")
            
            Image(systemName: freeAvailable ? "checkmark" : "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(freeAvailable ? .green : .red.opacity(0.5))
                .frame(width: 50, alignment: .center)
                .decorative()
                .accessibilityLabel("Free plan: \(freeAvailable ? "included" : "not included")")
            
            Image(systemName: premiumAvailable ? "checkmark" : "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(premiumAvailable ? .green : .red.opacity(0.5))
                .frame(width: 60, alignment: .center)
                .decorative()
                .accessibilityLabel("Premium plan: \(premiumAvailable ? "included" : "not included")")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(freeAvailable ? "included" : "not included") in Free plan, \(premiumAvailable ? "included" : "not included") in Premium plan")
    }
}

// MARK: - Preview

#Preview("SubscriptionView - Not Premium") {
    SubscriptionView()
}

#Preview("SubscriptionView - Premium") {
    SubscriptionView()
}
    // Auto-submit when complet