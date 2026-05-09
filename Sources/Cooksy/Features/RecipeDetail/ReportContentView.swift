import SwiftUI

// MARK: - Report Content View
/// A sheet that allows users to report inappropriate or incorrect recipe content.
/// Reports are submitted to the backend for content moderation review.
/// Fully accessible with VoiceOver labels, state announcements, and proper form structure.
struct ReportContentView: View {
    
    // MARK: - Dependencies

    @Environment(\.supabase) private var supabase

    // MARK: - Properties

    /// The recipe being reported
    let recipe: Recipe

    /// Called when the sheet should be dismissed
    let onDismiss: () -> Void
    
    // MARK: - State
    
    @State private var selectedReason: ReportReason = .inappropriate
    @State private var additionalDetails: String = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Recipe Info Section
                recipeInfoSection
                
                // MARK: Reason Section
                reasonSection
                
                // MARK: Details Section
                detailsSection
                
                // MARK: Submit Section
                submitSection
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        announceToVoiceOver("Report cancelled")
                        onDismiss()
                    }
                    .accessibilityLabel("Cancel reporting")
                    .accessibilityHint("Closes the report form without submitting")
                }
            }
            .accessibilityLabel("Report content form for \(recipe.title)")
        }
        .alert("Report Submitted", isPresented: $showConfirmation) {
            Button("OK") {
                onDismiss()
            }
        } message: {
            Text("Thank you for helping keep Cooksy safe. Our moderation team will review this report within 24 hours.")
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Recipe Info Section
    
    private var recipeInfoSection: some View {
        Section {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.brand.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.brand)
                            .decorative()
                    )
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .accessibilityLabel("Recipe: \(recipe.title)")
                    
                    Text("By \(recipe.sourceCreator)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("By \(recipe.sourceCreator)")
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Reporting recipe: \(recipe.title) by \(recipe.sourceCreator)")
        } header: {
            Text("Reporting")
                .font(.cooksCaption)
                .accessibilityLabel("Reporting section")
        }
    }
    
    // MARK: - Reason Section
    
    private var reasonSection: some View {
        Section {
            Picker("Reason", selection: $selectedReason) {
                ForEach(ReportReason.allCases) { reason in
                    Text(reason.displayName)
                        .tag(reason)
                        .accessibilityLabel(reason.displayName)
                        .accessibilityHint(reason.description)
                }
            }
            .pickerStyle(.inline)
            .accessibilityLabel("Report reason")
            .accessibilityValue(selectedReason.displayName)
            .accessibilityHint("Select why you are reporting this content")
            .onChange(of: selectedReason) { _, newReason in
                announceToVoiceOver("Selected: \(newReason.displayName). \(newReason.description)")
            }
        } header: {
            Text("Why are you reporting this?")
                .font(.cooksCaption)
                .accessibilityLabel("Why are you reporting this content?")
        } footer: {
            Text(selectedReason.description)
                .font(.caption)
                .accessibilityLabel("Description: \(selectedReason.description)")
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        Section {
            TextEditor(text: $additionalDetails)
                .frame(minHeight: 100)
                .accessibilityLabel("Additional details")
                .accessibilityHint("Optionally provide more information about your report")
                .overlay(alignment: .topLeading) {
                    if additionalDetails.isEmpty {
                        Text("Provide any additional details (optional)...")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        } header: {
            Text("Additional Details")
                .font(.cooksCaption)
                .accessibilityLabel("Additional details section")
        }
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        Section {
            Button {
                Task { await submitReport() }
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .accessibilityLabel("Submitting report")
                    } else {
                        Text("Submit Report")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .listRowBackground(Color.cooksDanger)
            .foregroundStyle(.white)
            .disabled(isSubmitting)
            .accessibilityLabel("Submit report")
            .accessibilityHint("Submits your content report to the moderation team")
            .accessibilityIdentifier("submitReportButton")
        }
    }
    
    // MARK: - Submit Report
    
    private func submitReport() async {
        isSubmitting = true
        errorMessage = nil
        announceToVoiceOver("Submitting report for \(recipe.title)")
        
        do {
            try await supabase.submitContentReport(
                recipeId: recipe.id.uuidString,
                reason: selectedReason.rawValue,
                details: additionalDetails.isEmpty ? nil : additionalDetails
            )
            showConfirmation = true
            announceToVoiceOver("Report submitted successfully. Our moderation team will review it within 24 hours.")
        } catch {
            errorMessage = "Failed to submit report. Please try again."
            announceToVoiceOver("Failed to submit report. Please try again.")
        }
        
        isSubmitting = false
    }
}

// MARK: - Report Reason

/// The available reasons for reporting content.
enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "spam"
    case inappropriate = "inappropriate"
    case incorrect = "incorrect"
    case other = "other"
    
    var id: String { rawValue }
    
    /// Display name shown in the picker
    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .inappropriate: return "Inappropriate Content"
        case .incorrect: return "Incorrect Information"
        case .other: return "Other"
        }
    }
    
    /// Description explaining the reason
    var description: String {
        switch self {
        case .spam:
            return "Unwanted promotional content or repeated posts."
        case .inappropriate:
            return "Content that violates our community guidelines."
        case .incorrect:
            return "Recipe information that is wrong or misleading."
        case .other:
            return "Any other issue not covered above."
        }
    }
}

// MARK: - Preview

#Preview {
    let recipe = Recipe(
        title: "Test Recipe",
        sourceUrl: "https://example.com",
        sourcePlatform: .youtube,
        sourceCreator: "Test Chef",
        sourceTitle: "Test Video"
    )
    
    ReportContentView(recipe: recipe) {}
}
