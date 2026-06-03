import Foundation

// MARK: - Formatters

/// Centralized formatting utilities for displaying recipe data.
enum Formatters {

    /// Formats a duration in minutes into a human-readable string.
    /// - 5   -> "5 min"
    /// - 60  -> "1 hr"
    /// - 90  -> "1 hr 30 min"
    /// - 0   -> "—"
    static func formatTime(_ minutes: Int) -> String {
        guard minutes > 0 else { return "\u{2014}" }
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hrs = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return hrs == 1 ? "1 hr" : "\(hrs) hrs"
        }
        return "\(hrs) hr \(mins) min"
    }

    /// Formats a serving count with proper pluralization.
    static func formatServings(_ count: Int) -> String {
        "\(count) serving\(count == 1 ? "" : "s")"
    }

    /// Formats a confidence score as "92/100".
    static func formatConfidence(_ score: Int) -> String {
        "\(score)/100"
    }

    /// Returns a relative time string (e.g., "2 hours ago", "yesterday").
    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Formats a date into a short readable format (e.g., "Jan 15, 2025").
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
