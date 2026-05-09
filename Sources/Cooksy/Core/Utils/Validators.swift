import Foundation

// MARK: - Validators

/// Centralized validation logic for URLs, emails, OTP codes, and platform detection.
enum Validators {

    // MARK: - Supported URL Domains

    static let supportedDomains = [
        "youtube.com",
        "youtu.be",
        "tiktok.com",
        "vm.tiktok.com",
        "instagram.com",
        "instagr.am"
    ]

    // MARK: - URL Validation

    /// Checks whether a string is a valid URL from a supported platform.
    static func isSupportedURL(_ string: String) -> Bool {
        guard let url = URL(string: string), let host = url.host else { return false }
        let lowerHost = host.lowercased()
        return supportedDomains.contains { lowerHost.contains($0) }
    }

    /// Determines the source platform for a given URL string.
    static func platformForURL(_ string: String) -> SourcePlatform? {
        guard let url = URL(string: string),
              let host = url.host?.lowercased() else { return nil }

        if host.contains("youtube") || host.contains("youtu.be") { return .youtube }
        if host.contains("tiktok") { return .tiktok }
        if host.contains("instagram") || host.contains("instagr.am") { return .instagram }
        return nil
    }

    // MARK: - Email Validation

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - OTP Validation

    static func isValidOTP(_ code: String) -> Bool {
        code.count == 6 && code.allSatisfy { $0.isNumber }
    }
}
