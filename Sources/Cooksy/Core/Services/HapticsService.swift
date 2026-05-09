import Foundation
import SwiftUI

/// Unified haptic feedback style for the app.
enum HapticStyle {
    case light, medium, heavy, success, error, warning
}

/// Lightweight service for playing haptic feedback.
/// Wraps UIKit feedback generators with a no-op fallback for non-UIKit environments.
struct HapticsService {

    static func play(_ style: HapticStyle) {
        #if canImport(UIKit)
        let generator: Any? = {
            switch style {
            case .light:  return UIImpactFeedbackGenerator(style: .light)
            case .medium: return UIImpactFeedbackGenerator(style: .medium)
            case .heavy:  return UIImpactFeedbackGenerator(style: .heavy)
            case .success, .error, .warning:
                return UINotificationFeedbackGenerator()
            }
        }()

        if let impact = generator as? UIImpactFeedbackGenerator {
            impact.impactOccurred()
        } else if let notification = generator as? UINotificationFeedbackGenerator {
            switch style {
            case .success:  notification.notificationOccurred(.success)
            case .error:    notification.notificationOccurred(.error)
            case .warning:  notification.notificationOccurred(.warning)
            default: break
            }
        }
        #endif
    }

    // Convenience shorthands
    static func light()   { play(.light) }
    static func medium()  { play(.medium) }
    static func heavy()   { play(.heavy) }
    static func success() { play(.success) }
    static func error()   { play(.error) }
    static func warning() { play(.warning) }
}
