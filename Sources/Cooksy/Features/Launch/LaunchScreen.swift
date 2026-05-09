import SwiftUI

// MARK: - Launch Screen
/// A SwiftUI-based launch screen displayed on app startup.
/// Shows the Cooksy logo centered on a cream background with a subtle
/// animated pulse effect to provide visual feedback while the app initializes.
///
/// Fully accessible with Reduce Motion compliance and proper VoiceOver labels.
struct LaunchScreen: View {
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.cooksBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo with optional pulse animation (respects Reduce Motion)
                CooksyLogo(size: 100)
                    .scaleEffect(isReduceMotionEnabled ? 1.0 : (isPulsing ? 1.05 : 1.0))
                    .opacity(isReduceMotionEnabled ? 1.0 : (isPulsing ? 0.9 : 1.0))
                    .accessibleAnimation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .accessibilityLabel("Cooksy logo")
                
                Text("Cooksy")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.ink)
                    .accessibleHeading(.h1)
                    .scalableText(minScale: 0.5)
                    .accessibilityLabel("Cooksy")
                
                Text("Recipe Intelligence")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.muted)
                    .opacity(0.8)
                    .scalableText()
                    .accessibilityLabel("Recipe Intelligence")

                // Hidden progress indicator for VoiceOver users
                if UIAccessibility.isVoiceOverRunning {
                    ProgressView()
                        .tint(.brand)
                        .scaleEffect(0.8)
                        .padding(.top, 12)
                        .accessibilityLabel("Loading Cooksy, please wait")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Cooksy, Recipe Intelligence. Loading.")
        }
        .onAppear {
            if !isReduceMotionEnabled {
                isPulsing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreen()
}
