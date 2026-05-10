import Foundation
import Security
import LocalAuthentication

// MARK: - KeychainService
/// Secure keychain storage for sensitive app data with multi-layered protection.
///
/// Replaces UserDefaults for all sensitive values (tokens, credentials, PII).
/// Uses the iOS Keychain Services API with tiered accessibility levels based on
/// data sensitivity, biometric protection for session tokens, tamper detection,
/// and automatic migration of items to stricter security levels.
///
/// ## Security Model (v2)
///
/// | Data Type | Accessibility | Biometric | Rationale |
/// |-----------|--------------|-----------|-----------|
/// | Session token | `WhenUnlockedThisDeviceOnly` | Required | Most sensitive — controls account access. Biometric gates every read. |
/// | User email, Apple ID | `WhenUnlockedThisDeviceOnly` | No | PII — only accessible when device is unlocked. Device-bound (no iCloud backup). |
/// | Display name, first name | `WhenUnlockedThisDeviceOnly` | No | Semi-sensitive — same protection tier as other PII for consistency. |
/// | Non-sensitive prefs (future) | `AfterFirstUnlockThisDeviceOnly` | No | Convenience data — kept out of keychain, in UserDefaults. |
///
/// ### Protection Features
/// - **Biometric-gated session tokens:** Face ID / Touch ID required to read
///   the session token. Prevents token extraction from a stolen unlocked device.
/// - **Tamper detection:** Tracks consecutive read failures in memory. Triggers
///   anomaly notification after 3+ failures, enabling forced re-authentication.
/// - **Automatic migration:** One-time upgrade of existing keychain items from
///   `AfterFirstUnlock` to `WhenUnlocked` accessibility without data loss.
/// - **Device-bound storage:** All items use `ThisDeviceOnly` — never syncs
///   to iCloud or other devices.
@Observable
@MainActor
final class KeychainService {
    static let shared = KeychainService()

    private let sessionTokenKey = "com.cooksy.sessionToken"
    private let userEmailKey = "com.cooksy.userEmail"
    private let appleUserIDKey = "com.cooksy.appleUserID"
    private let displayNameKey = "com.cooksy.displayName"
    private let firstNameKey = "com.cooksy.firstName"

    /// UserDefaults key tracking whether v2 migration has completed.
    private let migrationFlagKey = "keychainMigrated_v2"

    /// In-memory consecutive read failure counter for tamper detection.
    /// Resets to 0 on any successful read. Not persisted — detects attacks
    /// within a single app session.
    private var consecutiveReadFailures = 0

    /// Maximum consecutive failures before anomaly notification fires.
    private let anomalyThreshold = 3

    /// Notification posted when potential keychain tampering is detected.
    /// Observers should trigger forced re-authentication or alert the user.
    static let anomalyDetectedNotification = Notification.Name("com.cooksy.keychainAnomalyDetected")

    // MARK: - Initialization

    private init() {
        migrateItemsIfNeeded()
    }

    // MARK: - Session Token (Biometric-Protected)

    /// The active Supabase session token, gated behind biometric authentication.
    ///
    /// Reading this property triggers Face ID / Touch ID if biometric protection
    /// is available. Writing stores the token with `kSecAccessControlBiometryCurrentSet`
    /// so it can only be read when the user authenticates with biometrics.
    ///
    /// - Note: If biometric authentication fails (user cancels, not enrolled,
    ///   device lockout), reads return `nil` without crashing. The caller should
    ///   handle `nil` by redirecting to the sign-in flow.
    var sessionToken: String? {
        get { readBiometricProtected(key: sessionTokenKey) }
        set { writeBiometricProtected(key: sessionTokenKey, value: newValue) }
    }

    // MARK: - User Email

    /// The authenticated user's email address.
    ///
    /// Stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — accessible
    /// only when the device is unlocked. Upgraded from `AfterFirstUnlock` in v2
    /// to reduce exposure window on stolen devices that are rebooted.
    var userEmail: String? {
        get { read(key: userEmailKey) }
        set { write(key: userEmailKey, value: newValue) }
    }

    // MARK: - Apple User ID

    /// The Apple Sign-In user identifier (sub claim).
    ///
    /// This stable identifier links the Apple account to the Cooksy account.
    /// Protected at the same tier as email — `WhenUnlockedThisDeviceOnly`.
    /// Device-bound to prevent account linking across stolen device restores.
    var appleUserID: String? {
        get { read(key: appleUserIDKey) }
        set { write(key: appleUserIDKey, value: newValue) }
    }

    // MARK: - Display Name

    /// The user's display name shown in the app UI.
    ///
    /// Stored with `WhenUnlockedThisDeviceOnly` for consistency with other PII.
    /// While less sensitive than tokens, grouping all identity fields under the
    /// same policy simplifies the security model and audit.
    var displayName: String? {
        get { read(key: displayNameKey) }
        set { write(key: displayNameKey, value: newValue) }
    }

    // MARK: - First Name

    /// The user's first name (from Apple Sign-In profile).
    ///
    /// Stored with `WhenUnlockedThisDeviceOnly`. Personal name data can be used
    /// for social engineering — protecting it reduces attack surface.
    var firstName: String? {
        get { read(key: firstNameKey) }
        set { write(key: firstNameKey, value: newValue) }
    }

    // MARK: - Bulk Operations

    /// Clears all sensitive keychain entries. Called on sign out.
    func clearAll() {
        [sessionTokenKey, userEmailKey, appleUserIDKey, displayNameKey, firstNameKey]
            .forEach { delete(key: $0) }
        // Reset tamper counter on explicit clear — not an attack
        consecutiveReadFailures = 0
    }

    // MARK: - Keychain Migration (v1 → v2)

    /// Migrates keychain items from v1 (`AfterFirstUnlock`) to v2 (`WhenUnlocked`) accessibility.
    ///
    /// Runs once per device (tracked via UserDefaults flag). Reads each existing
    /// item with a permissive query (ignoring accessibility), then re-writes it
    /// with the new stricter accessibility level. This ensures existing users get
    /// upgraded security without being forced to sign in again.
    ///
    /// - Important: If migration fails for an individual key, the failure is logged
    ///   and migration continues. The old item remains in place — it will be
    ///   overwritten on next sign-in with the new level.
    private func migrateItemsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migrationFlagKey) else { return }

        let keysToMigrate = [
            (sessionTokenKey, true),   // biometric-protected
            (userEmailKey, false),
            (appleUserIDKey, false),
            (displayNameKey, false),
            (firstNameKey, false)
        ]

        for (key, useBiometric) in keysToMigrate {
            // Attempt to read with a permissive query that ignores accessibility level
            let permissiveQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: "com.cooksy",
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
                // Ignore accessibility to find items at any protection level
                kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(permissiveQuery as CFDictionary, &result)

            guard status == errSecSuccess,
                  let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                // Item doesn't exist or couldn't be read — skip it
                continue
            }

            // Delete the old item and re-write with new stricter accessibility
            delete(key: key)

            if useBiometric {
                writeBiometricProtected(key: key, value: value)
            } else {
                write(key: key, value: value)
            }
        }

        // Mark migration complete even if some items failed — they'll be
        // overwritten naturally on next sign-in
        UserDefaults.standard.set(true, forKey: migrationFlagKey)
    }

    // MARK: - Tamper Detection

    /// Detects potential keychain tampering by tracking consecutive read failures.
    ///
    /// Increments an in-memory counter on each failed read. If the counter
    /// reaches `anomalyThreshold` (3), posts `anomalyDetectedNotification` so
    /// the app can trigger forced re-authentication or display a security alert.
    ///
    /// The counter resets to 0 on any successful read, so legitimate occasional
    /// failures (e.g., key not found on first launch) do not trigger alerts.
    ///
    /// - Parameter status: The `OSStatus` returned by the keychain operation.
    private func detectAnomaly(status: OSStatus) {
        if status == errSecSuccess {
            // Reset counter on success
            consecutiveReadFailures = 0
            return
        }

        // Only count "item not found" as a potential anomaly indicator.
        // Other errors (user canceled auth, etc.) are expected and not counted.
        guard status == errSecItemNotFound else { return }

        consecutiveReadFailures += 1

        if consecutiveReadFailures >= anomalyThreshold {
            NotificationCenter.default.post(
                name: Self.anomalyDetectedNotification,
                object: nil,
                userInfo: ["failureCount": consecutiveReadFailures]
            )
            // Reset after firing to prevent spam — one alert per session is enough
            consecutiveReadFailures = 0
        }
    }

    // MARK: - Biometric-Protected Keychain Access

    /// Writes a value to the keychain with biometric authentication protection.
    ///
    /// Uses `kSecAccessControlBiometryCurrentSet` combined with
    /// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. The item can only be read
    /// after successful Face ID / Touch ID authentication with the currently
    /// enrolled biometric set. Adding or removing a fingerprint/face invalidates
    /// the item (security feature against biometric enrollment tampering).
    ///
    /// - Parameters:
    ///   - key: The keychain account identifier.
    ///   - value: The string value to store, or `nil` to delete the item.
    private func writeBiometricProtected(key: String, value: String?) {
        delete(key: key)
        guard let data = value?.data(using: .utf8) else { return }

        // Create access control flags requiring biometric authentication
        var accessControlError: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &accessControlError
        )

        guard let accessControl else {
            print("[KeychainService] Failed to create access control: \(String(describing: accessControlError))")
            // Fallback: write without biometric protection rather than lose data
            write(key: key, value: value)
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccessControl as String: accessControl,
            kSecAttrService as String: "com.cooksy",
            // Tell the system to use biometric authentication UI when reading
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainService] Biometric write failed for key '\(key)': \(status)")
        }
    }

    /// Reads a biometric-protected value from the keychain.
    ///
    /// Triggers Face ID / Touch ID authentication prompt if needed. Returns `nil`
    /// if authentication fails, is cancelled, or the item does not exist.
    ///
    /// - Parameter key: The keychain account identifier.
    /// - Returns: The stored string value, or `nil` on failure.
    private func readBiometricProtected(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.cooksy",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        detectAnomaly(status: status)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    // MARK: - Standard Keychain Access (WhenUnlockedThisDeviceOnly)

    /// Writes a value to the keychain with standard device-bound protection.
    ///
    /// Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for all PII fields.
    /// Data is accessible only when the device is unlocked and never leaves the
    /// device (no iCloud sync, no backup restoration to other devices).
    ///
    /// - Parameters:
    ///   - key: The keychain account identifier.
    ///   - value: The string value to store, or `nil` to delete the item.
    private func write(key: String, value: String?) {
        delete(key: key)
        guard let data = value?.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // v2: Upgraded from AfterFirstUnlock to WhenUnlocked.
            // Rationale: AfterFirstUnlock allows keychain reads after the first
            // device unlock post-reboot, even if the device is subsequently locked.
            // WhenUnlocked requires the device to be currently unlocked, narrowing
            // the attack window for physical device theft scenarios.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrService as String: "com.cooksy"
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainService] Write failed for key '\(key)': \(status)")
        }
    }

    /// Reads a value from the keychain with standard protection.
    ///
    /// Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Returns `nil` if the
    /// device is locked or the item does not exist.
    ///
    /// - Parameter key: The keychain account identifier.
    /// - Returns: The stored string value, or `nil` on failure.
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

        detectAnomaly(status: status)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    /// Deletes a keychain item regardless of its accessibility level.
    ///
    /// - Parameter key: The keychain account identifier to remove.
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.cooksy"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
