import SwiftUI

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cooksBodyBold)
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.brand)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? (isReduceMotionEnabled ? 1.0 : 0.98) : 1.0)
            .accessibleAnimation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cooksBodyBold)
            .foregroundStyle(.softInk)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.surface)
            .overlay(Capsule().stroke(Color.cooksLine, lineWidth: 1))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Tertiary Button Style

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cooksCallout.weight(.semibold))
            .foregroundStyle(.muted)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

// MARK: - Icon Button Style

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(Color.surface)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.cooksLine, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies the primary (brand-filled) button style.
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }

    /// Applies the secondary (outlined) button style.
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }

    /// Applies the tertiary (text-only) button style.
    func tertiaryButton() -> some View {
        buttonStyle(TertiaryButtonStyle())
    }

    /// Applies the circular icon button style.
    func iconButton() -> some View {
        buttonStyle(IconButtonStyle())
    }
}

// MARK: - Primary Button View

/// A standalone primary (brand-filled) button view.
///
/// Usage:
/// ```swift
/// PrimaryButton("Continue", icon: "arrow.right") { ... }
/// PrimaryButton("Save", isLoading: true) { ... }
/// ```
struct PrimaryButton: View {
    var _title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.ink)
                        .controlSize(.small)
                        .accessibilityLabel("Loading")
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .decorative()
                }
                Text(_title)
                    .scalableText()
            }
        }
        .primaryButton()
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1.0 : 0.5)
        .accessibilityLabel(_title)
        .accessibilityHint(isEnabled ? "" : "This button is currently disabled")
    }
}

// MARK: - Secondary Button View

/// A standalone secondary (outlined) button view.
///
/// Usage:
/// ```swift
/// SecondaryButton("Cancel") { ... }
/// SecondaryButton("Skip", icon: "xmark") { ... }
/// ```
struct SecondaryButton: View {
    var _title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.softInk)
                        .controlSize(.small)
                        .accessibilityLabel("Loading")
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .decorative()
                }
                Text(_title)
                    .scalableText()
            }
        }
        .secondaryButton()
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled && !isLoading ? 1.0 : 0.5)
        .accessibilityLabel(_title)
        .accessibilityHint(isEnabled ? "" : "This button is currently disabled")
    }
}

// MARK: - Tertiary Button View

/// A standalone tertiary (text-only) button view.
///
/// Usage:
/// ```swift
/// TertiaryButton("Resend code") { ... }
/// TertiaryButton("Back", icon: "arrow.backward") { ... }
/// ```
struct TertiaryButton: View {
    var _title: String
    var icon: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .decorative()
                }
                Text(_title)
                    .scalableText()
            }
        }
        .tertiaryButton()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
        .accessibilityLabel(_title)
        .accessibilityHint(isEnabled ? "" : "This button is currently disabled")
    }
}

// MARK: - Icon Button View

/// A standalone circular icon button view.
///
/// Usage:
/// ```swift
/// IconButton(icon: "xmark") { ... }
/// IconButton(icon: "bookmark.fill", tint: .brand) { ... }
/// ```
struct IconButton: View {
    let icon: String
    var tint: Color = .softInk
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .decorative()
        }
        .iconButton()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
        .accessibilityLabel(iconAccessibilityLabel)
        .accessibilityHint(isEnabled ? "" : "This button is currently disabled")
    }

    private var iconAccessibilityLabel: String {
        // Map common SF Symbols to meaningful labels
        switch icon {
        case "xmark": return "Close"
        case "bookmark.fill", "bookmark": return "Save"
        case "trash.fill", "trash": return "Delete"
        case "pencil": return "Edit"
        case "arrow.backward": return "Go back"
        case "arrow.right": return "Continue"
        case "checkmark": return "Confirm"
        case "plus": return "Add"
        case "minus": return "Remove"
        case "flame.fill": return "Cooking mode"
        case "arrow.up.forward.app": return "Open in app"
        case "arrow.clockwise": return "Restore"
        default: return icon.replacingOccurrences(of: ".", with: " ").replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Preview

#Preview("Button Gallery") {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                PrimaryButton("Continue", icon: "arrow.right") {}
                PrimaryButton("Saving...", isLoading: true) {}
                PrimaryButton("Disabled", isEnabled: false) {}
            }

            Divider()

            Group {
                SecondaryButton("Cancel") {}
                SecondaryButton("Skip", icon: "xmark") {}
                SecondaryButton("Disabled", isEnabled: false) {}
            }

            Divider()

            Group {
                TertiaryButton("Resend code") {}
                TertiaryButton("Back", icon: "arrow.backward") {}
                TertiaryButton("Disabled", isEnabled: false) {}
            }

            Divider()

            Group {
                IconButton(icon: "xmark") {}
                IconButton(icon: "bookmark.fill", tint: .brand) {}
            }
        }
        .padding()
        .background(Color.cooksBackground)
    }
}
