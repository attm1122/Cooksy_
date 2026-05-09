import SwiftUI

// MARK: - Auth View
/// Complete authentication flow view that handles both email entry
/// and OTP verification steps in a unified NavigationStack.
///
/// Fully accessible with VoiceOver labels, error announcements, OTP digit labels,
/// and proper form navigation.
struct AuthView: View {
    /// Closure called when authentication is successful
    let onAuthenticated: () -> Void
    
    /// ViewModel managing auth state and logic
    @State private var viewModel: AuthViewModel
    
    /// Focus state for email field
    @FocusState private var emailFocused: Bool
    
    init(onAuthenticated: @escaping () -> Void = {}) {
        self.onAuthenticated = onAuthenticated
        // Temporary initialization - will be replaced in body via task
        _viewModel = State(wrappedValue: AuthViewModel(
            supabase: MockSupabaseService(),
            onAuthenticated: onAuthenticated
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Cream background
                Color.cream.ignoresSafeArea()
                
                // Content based on current step
                switch viewModel.currentStep {
                case .email:
                    emailStepView
                        .accessibleAnimation(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ), value: viewModel.currentStep)
                    
                case .code(let email):
                    codeStepView(email: email)
                        .accessibleAnimation(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ), value: viewModel.currentStep)
                }
            }
            .accessibleAnimation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            .overlay(loadingOverlay)
            .accessibilityIdentifier(AccessibilityID.authView)
        }

    }
    
    // MARK: - Email Step
    
    private var emailStepView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo and header
                VStack(spacing: 16) {
                    CooksyLogo(size: 64)
                    
                    Text("Sign In")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.textPrimary)
                        .accessibleHeading(.h1)
                    
                    Text("Enter your email to get started")
                        .font(.system(size: 15))
                        .foregroundStyle(.textMuted)
                        .multilineTextAlignment(.center)
                        .scalableText()
                }
                .padding(.top, 40)
                
                // Error banner
                if let error = viewModel.errorMessage {
                    AccessibleErrorBanner(message: error)
                        .accessibleAnimation(.move(edge: .top).combined(with: .opacity), value: viewModel.errorMessage)
                }
                
                // Email input
                VStack(spacing: 20) {
                    CooksyTextField(
                        title: "Email",
                        placeholder: "you@example.com",
                        text: $viewModel.email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never
                    )
                    .focused($emailFocused)
                    .accessibilityLabel("Email address for sign in")
                    .accessibilityHint("Enter the email address associated with your account")
                    .accessibilityIdentifier(AccessibilityID.emailInputField)
                    .submitLabel(.continue)
                    .onSubmit {
                        Task { await viewModel.sendCode() }
                    }
                    
                    // Continue button
                    PrimaryButton(
                        "Continue",
                        icon: "arrow.right",
                        isEnabled: !viewModel.email.isEmpty
                    ) {
                        Task { await viewModel.sendCode() }
                    }
                    .accessibilityLabel("Continue to verification code")
                    .accessibilityHint("Sends a verification code to your email address")
                    .accessibilityIdentifier(AccessibilityID.continueButton)
                }
                
                Spacer()
                
                // Terms text
                Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption)
                    .foregroundStyle(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .scalableText()
                    .accessibilityLabel("By continuing, you agree to our Terms of Service and Privacy Policy")
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            emailFocused = true
        }
    }
    
    // MARK: - Code Step
    
    private func codeStepView(email: String) -> some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge.shield.half.filled.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.brand)
                        .decorative()
                    
                    Text("Check your email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.textPrimary)
                        .accessibleHeading(.h1)
                    
                    Text("Enter the 6-digit code sent to \(email)")
                        .font(.system(size: 15))
                        .foregroundStyle(.textMuted)
                        .multilineTextAlignment(.center)
                        .scalableText()
                        .accessibilityLabel("Enter the 6 digit verification code sent to \(email)")
                }
                .padding(.top, 40)
                
                // Error banner
                if let error = viewModel.errorMessage {
                    AccessibleErrorBanner(message: error)
                        .accessibleAnimation(.move(edge: .top).combined(with: .opacity), value: viewModel.errorMessage)
                }
                
                // OTP Input
                VStack(spacing: 24) {
                    AccessibleOTPInputView(code: $viewModel.code)
                        .accessibilityIdentifier(AccessibilityID.otpInputView)
                        .onChange(of: viewModel.code) { _, newCode in
                            if newCode.count == 6 {
                                announceToVoiceOver("Code entered, verifying...")
                                Task { await viewModel.verifyCode() }
                            }
                        }
                    
                    // Verify button
                    PrimaryButton(
                        "Verify",
                        isEnabled: viewModel.code.count == 6
                    ) {
                        Task { await viewModel.verifyCode() }
                    }
                    .accessibilityLabel("Verify code")
                    .accessibilityHint("Verifies the 6-digit code and signs you in")
                    .accessibilityIdentifier(AccessibilityID.verifyButton)
                    
                    // Resend code button
                    resendCodeSection(email: email)
                    
                    // Change email button
                    TertiaryButton("Change email", icon: "arrow.backward") {
                        viewModel.goBackToEmail()
                        announceToVoiceOver("Returning to email entry")
                    }
                    .padding(.top, 8)
                    .accessibilityLabel("Change email address")
                    .accessibilityHint("Go back to enter a different email address")
                    .accessibilityIdentifier(AccessibilityID.changeEmailButton)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Resend Code Section

    @ViewBuilder
    private func resendCodeSection(email: String) -> some View {
        HStack(spacing: 4) {
            Text("Didn't receive it?")
                .font(.subheadline)
                .foregroundStyle(.textMuted)
            
            if viewModel.resendCountdown > 0 {
                Text("Resend in \(viewModel.resendCountdown)s")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.textMuted)
                    .accessibilityLabel("Resend verification code, \(AccessibilityFormatter.countdown(viewModel.resendCountdown))")
            } else {
                TertiaryButton("Resend code") {
                    Task { await viewModel.resendCode() }
                    announceToVoiceOver("Verification code resent to \(email)")
                }
                .accessibilityLabel("Resend verification code")
                .accessibilityHint("Sends a new verification code to \(email)")
                .accessibilityIdentifier(AccessibilityID.resendCodeButton)
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.4)
                            .tint(.brand)
                            .accessibilityLabel("Loading, please wait")
                    )
                    .transition(.opacity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Loading")
            }
        }
    }
}

// MARK: - Accessible Error Banner

/// An accessibility-enhanced error banner that announces its message to VoiceOver.
struct AccessibleErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .decorative()
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.leading)
                .scalableText()
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .onAppear {
            announceToVoiceOver("Error: \(message)")
        }
    }
}

// MARK: - Accessible OTP Input View

/// A fully accessible 6-digit OTP code input component.
///
/// Features:
/// - Hidden TextField captures actual keyboard input
/// - Visual digit boxes show entered digits with focus indication
/// - Auto-advances focus as digits are entered
/// - Handles backspace to delete and move back
/// - Auto-submits when 6 digits are entered
/// - Full VoiceOver support with per-digit labels and combined element
struct AccessibleOTPInputView: View {
    /// The 6-digit code entered by the user (bound to ViewModel)
    @Binding var code: String
    
    /// Maximum number of digits (always 6 for OTP)
    private let digitCount = 6
    
    /// Which digit box is currently focused (0-5)
    @State private var focusedIndex: Int = 0
    
    /// Internal text field that captures keyboard input
    @State private var internalText: String = ""
    
    /// Focus state for the hidden text field
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<digitCount, id: \.self) { index in
                digitBox(at: index)
                    .onTapGesture {
                        focusedIndex = min(index, code.count)
                        isTextFieldFocused = true
                    }
            }
        }
        // Hidden text field captures all keyboard input
        .background(
            TextField("", text: $internalText)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isTextFieldFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
                .onChange(of: internalText) { _, newValue in
                    handleTextChange(newValue)
                }
        )
        .onAppear {
            // Sync internal text with bound code
            internalText = code
            // Auto-focus on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedIndex = code.count
                isTextFieldFocused = true
            }
        }
        .onChange(of: code) { _, newCode in
            if internalText != newCode {
                internalText = newCode
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verification code, \(code.count) of \(digitCount) digits entered")
        .accessibilityHint("Tap to enter the \(digitCount)-digit code from your email")
    }
    
    // MARK: - Digit Box
    
    /// Creates a single digit box at the given index
    private func digitBox(at index: Int) -> some View {
        let digit = code.count > index ? String(code[code.index(code.startIndex, offsetBy: index)]) : nil
        let isFocused = focusedIndex == index && isTextFieldFocused
        let isFilled = code.count > index
        
        return Text(digit ?? " ")
            .font(.system(size: 24, weight: .semibold, design: .monospaced))
            .foregroundStyle(isFilled ? Color.textPrimary : Color.textMuted.opacity(0.4))
            .frame(width: 44, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.creamDark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? Color.brand : Color.clear,
                        lineWidth: 2
                    )
            )
            .accessibleAnimation(.easeInOut(duration: 0.2), value: isFocused)
            .accessibleAnimation(.easeInOut(duration: 0.2), value: isFilled)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Digit \(index + 1)")
            .accessibilityValue(code.count > index ? "Entered, \(digit ?? "")" : "Empty")
    }
    
    // MARK: - Text Handling
    
    /// Processes text changes from the hidden text field
    private func handleTextChange(_ newValue: String) {
        // Filter to digits only
        let filtered = String(newValue.filter { $0.isNumber }.prefix(digitCount))
        
        // Detect backspace (text got shorter)
        if filtered.count < code.count {
            // Move focus back
            focusedIndex = max(filtered.count, 0)
            if filtered.count < code.count {
                let removedDigit = code.dropLast().last.map(String.init) ?? ""
                announceToVoiceOver("Digit \(removedDigit) deleted")
            }
        } else if filtered.count > code.count {
            // New digit entered, announce and advance focus
            let newDigit = filtered.last.map(String.init) ?? ""
            focusedIndex = min(filtered.count, digitCount - 1)
            announceToVoiceOver("Digit \(newDigit) entered")
        }
        
        // Update both internal and external state
        internalText = filtered
        code = filtered
        
        // Auto-submit when complete
        if filtered.count == digitCount {
            isTextFieldFocused = false
            announceToVoiceOver("All 6 digits entered")
        }
    }
}

// MARK: - Preview

#Preview("AuthView - Email Step") {
    AuthView(onAuthenticated: {})
}

#Preview("AuthView - Code Step") {
    AuthView(onAuthenticated: {})
}
