import SwiftUI

// MARK: - Cooksy Text Field

/// Styled text field used throughout the app for URL input, email entry, etc.
/// Features a warm background with a brand-colored focus ring.
/// Fully accessible with proper labels, traits, and keyboard support.
struct CooksyTextField: View {
    var title: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure = false
    var submitLabel: SubmitLabel = .done

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder.isEmpty ? title : placeholder, text: $text)
                    .accessibilityLabel(title)
            } else {
                TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                    .accessibilityLabel(title)
            }
        }
        .font(.cooksCallout)
        .foregroundStyle(.softInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.cooksBackground)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    isFocused ? Color.brand : Color.cooksLine,
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .focused($isFocused)
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .textInputAutocapitalization(autocapitalization)
        .autocorrectionDisabled()
        .submitLabel(submitLabel)
        .accessibilityAddTraits(.isSearchField)
    }
}

// MARK: - Paste-Aware URL Field

/// A text field that shows a "Paste" button when the clipboard contains a supported URL.
/// Fully accessible with proper labels, paste action, and keyboard support.
struct URLInputField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    @State private var clipboardHasURL = false

    var body: some View {
        HStack(spacing: 8) {
            CooksyTextField(
                title: "Recipe URL",
                placeholder: "Paste a recipe video link...",
                text: $text,
                keyboardType: .URL,
                textContentType: .URL,
                autocapitalization: .never,
                submitLabel: .go
            )
            .accessibilityLabel("Recipe URL from YouTube, TikTok, or Instagram")
            .accessibilityHint("Paste a link to a recipe video to save it")

            if clipboardHasURL {
                Button {
                    if let pasteboard = UIPasteboard.general.string {
                        text = pasteboard
                        announceToVoiceOver("URL pasted from clipboard")
                    }
                    HapticsService.light()
                } label: {
                    Text("Paste")
                        .font(.cooksCaption.weight(.semibold))
                        .foregroundStyle(.brand)
                        .padding(.trailing, 8)
                }
                .accessibilityLabel("Paste URL from clipboard")
                .accessibilityHint("Pastes the copied URL into the text field")
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            checkClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkClipboard()
        }
    }

    private func checkClipboard() {
        guard let pasteboard = UIPasteboard.general.string else {
            clipboardHasURL = false
            return
        }
        clipboardHasURL = Validators.isSupportedURL(pasteboard) && text.isEmpty
    }
}
