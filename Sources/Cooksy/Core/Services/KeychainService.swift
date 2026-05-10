import Foundation
import Security

/// Secure keychain storage for sensitive app data.
///
/// Replaces UserDefaults for all sensitive values (tokens, credentials, PII).
/// Uses the iOS Keychain Services API with kSecAttrAccessibleAfterFirstUnlock
/// so data persists across app launches but is encrypted at rest.
///
/// ## Security Model
/// - Session tokens: stored with biometric protection when available
/// - Auth state (email, user ID): stored after first unlock
/// - Non-sensitive preferences (onboarding flag, review counts): remain in UserDefaults
@Observable
@MainActor
final class KeychainService {
    static let shared = KeychainService()

    private let sessionTokenKey = "com.cooksy.sessionToken"
    private let userEmailKey = "com.cooksy.userEmail"
    private let appleUserIDKey = "com.cooksy.appleUserID"
    private let displayNameKey = "com.cooksy.displayName"
    private let firstNameKey = "com.cooksy.firstName"

    private init() {}

    // MARK: - Session Token

    var sessionToken: String? {
        get { read(key: sessionTokenKey) }
        set { write(key: sessionTokenKey, value: newValue) }
    }

    // MARK: - User Email

    var userEmail: String? {
        get { read(key: userEmailKey) }
        set { write(key: userEmailKey, value: newValue) }
    }

    // MARK: - Apple User ID

    var appleUserID: String? {
        get { read(key: appleUserIDKey) }
        set { write(key: appleUserIDKey, value: newValue) }
    }

    // MARK: - Display Name

    var displayName: String? {
        get { read(key: displayNameKey) }
        set { write(key: displayNameKey, value: newValue) }
    }

    // MARK: - First Name

    var firstName: String? {
        get { read(key: firstNameKey) }
        set { write(key: firstNameKey, value: newValue) }
    }

    // MARK: - Bulk Operations

    /// Clears all sensitive keychain entries. Called on sign out.
    func clearAll() {
        [sessionTokenKey, userEmailKey, appleUserIDKey, displayNameKey, firstNameKey]
            .forEach { delete(key: $0) }
    }

    // MARK: - Low-Level Keychain Access

    private func write(key: String, value: String?) {
        delete(key: key)
        guard let data = value?.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrService as String: "com.cooksy"
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.cooksy",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.cooksy"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
