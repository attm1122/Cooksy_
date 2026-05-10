import Foundation
import CryptoKit
import CommonCrypto

// MARK: - BundleIntegrityVerifier

/// Verifies the integrity of the app bundle at runtime.
///
/// Computes a hash of the main executable and compares it against a known
/// value. If the binary has been modified (patched, injected, re-signed),
/// the verification will fail.
///
/// ## Usage
/// Call `BundleIntegrityVerifier.verify()` early in app launch. If it returns
/// false, the app binary has been tampered with.
enum BundleIntegrityVerifier {

    /// The UserDefaults key for storing the bundle hash.
    private static let defaultsKey = "com.cooksy.bundle_hash"

    // MARK: - Hash Computation

    /// Computes a hash of the main executable file.
    /// - Returns: The SHA-256 hash of the main executable, or nil if unavailable.
    static func computeExecutableHash() -> String? {
        guard let executablePath = Bundle.main.executablePath else {
            return nil
        }

        guard let fileHandle = FileHandle(forReadingAtPath: executablePath) else {
            return nil
        }

        defer { fileHandle.closeFile() }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        // Read file in chunks to avoid loading entire binary into memory
        let chunkSize = 65536 // 64KB
        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: chunkSize)
            guard !data.isEmpty else { return false }
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress {
                    _ = CC_SHA256_Update(&context, baseAddress, CC_LONG(buffer.count))
                }
            }
            return true
        }) {}

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)

        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Verification

    /// Verifies the executable hash against a known value.
    ///
    /// The expected hash should be set during the build process (CI/CD).
    /// For the first run, this always returns true and caches the computed hash.
    ///
    /// - Returns: `true` if the binary matches the expected hash or no hash is set yet.
    static func verify() -> Bool {
        guard let currentHash = computeExecutableHash() else { return false }

        let storedHash = UserDefaults.standard.string(forKey: defaultsKey)

        if let stored = storedHash {
            // Compare against previously stored hash
            return currentHash == stored
        } else {
            // First run — store the hash for future verification
            UserDefaults.standard.set(currentHash, forKey: defaultsKey)
            return true
        }
    }

    // MARK: - Reset

    /// Resets the stored hash (e.g., after a legitimate app update).
    static func reset() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    // MARK: - Explicit Expected Hash

    /// Verifies the executable hash against an explicitly provided expected hash.
    ///
    /// Use this when the expected hash is embedded at build time or fetched
    /// from a secure server. This method does not cache the hash — it performs
    /// a direct comparison every time.
    ///
    /// - Parameter expectedHash: The expected SHA-256 hash of the main executable.
    /// - Returns: `true` if the current executable matches the expected hash.
    static func verify(against expectedHash: String) -> Bool {
        guard let currentHash = computeExecutableHash() else { return false }
        return currentHash == expectedHash
    }
}
