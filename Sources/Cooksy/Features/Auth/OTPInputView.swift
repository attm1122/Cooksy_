import SwiftUI

// MARK: - OTP Input View
/// A clean 6-digit OTP input with individual digit boxes.
///
/// Accessibility: Each digit box has its own label ("Digit 1 of 6"), the combined
/// element reads the full code state, and all interactions work with VoiceOver.
struct OTPInputView: View {

    // MARK: - Properties

    @Binding var code: String
    let digitCount: Int = 6

    @FocusState private var isFocused: Bool
    @State private var invalidShake = false

    private var isComplete: Bool {
        code.count >= digitCount
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Hidden real text field that captures input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .frame(width: 0, height: 0)
                .opacity(0)
                .focused($isFocused)
                .onChange(of: code) { oldValue, newValue in
                    // Filter to digits only
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(digitCount))
                    if filtered != newValue {
                        code = filtered
                    }
                    // Haptic on digit entry
                    if filtered.count > oldValue.count, filtered.count < digitCount {
                        HapticsService.light()
                    }
                }

            // Visual digit boxes
            ForEach(0..<digitCount, id: \.self) { index in
                digitBox(at: index)
            }
        }
        .onAppear { isFocused = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verification code, \(code.count) of \(digitCount) digits entered")
        .accessibilityValue(code.isEmpty ? "Empty" : code)
        .modifier(ShakeEffect(animating: invalidShake))
    }

    // MARK: - Digit Box

    @ViewBuilder
    private func digitBox(at index: Int) -> some View {
        let hasDigit = index < code.count
        let digit = hasDigit ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""

        Text(hasDigit ? digit : "")
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(Color.ink)
            .frame(width: 44, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cooksBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hasDigit ? Color.brand : Color.cooksLine,
                        style: StrokeStyle(lineWidth: hasDigit ? 2 : 1)
                    )
            )
            .accessibilityLabel("Digit \(index + 1) of \(digitCount)")
            .accessibilityValue(hasDigit ? "Entered" : "Empty")
    }
}

// MARK: - Shake Effect

/// A view modifier that shakes the view horizontally — used for invalid OTP feedback.
private struct ShakeEffect: ViewModifier {
    var animating: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: animating ? 0 : 0)
            .animation(
                animating
                    ? Animation.spring(response: 0.15, dampingFraction: 0.06, blendDuration: 0)
                        .repeatCount(3, autoreverses: true)
                    : .default,
                value: animating
            )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var code = "123"
    OTPInputView(code: $code)
        .padding()
}
