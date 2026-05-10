import Foundation
import Security
import CryptoKit

// MARK: - SSLPinningError

/// Errors thrown during SSL certificate pinning validation.
enum SSLPinningError: LocalizedError {
    case pinValidationFailed(host: String)
    case invalidCertificateChain
    case publicKeyExtractionFailed
    case spkiSerializationFailed

    var errorDescription: String? {
        switch self {
        case .pinValidationFailed(let host):
            return "SSL pinning validation failed for \(host). The server's certificate does not match any pinned hash."
        case .invalidCertificateChain:
            return "Could not extract a valid certificate chain from the server trust."
        case .publicKeyExtractionFailed:
            return "Could not extract the public key from the server's certificate."
        case .spkiSerializationFailed:
            return "Failed to serialize the Subject Public Key Info (SPKI) for hashing."
        }
    }
}

// MARK: - SSLPinningService

/// SSL certificate pinning for Supabase API connections.
///
/// Embeds the expected public key hashes of Supabase's TLS certificate chain
/// and validates them during every HTTPS connection. If the server's
/// certificate doesn't match a pinned hash, the connection is rejected.
///
/// ## How It Works
/// 1. Extract Supabase's public key from their TLS certificate at connection time.
/// 2. Compute the SHA-256 hash of the Subject Public Key Info (SPKI).
/// 3. Compare the computed SPKI hash against the list of pinned hashes.
/// 4. If none match, reject the connection (MITM protection).
///
/// ## How to Get the Pin Hash
/// ```bash
/// # Primary pin (leaf certificate)
/// echo | openssl s_client -connect qirjjbmrgtailifhmakp.supabase.co:443 -servername qirjjbmrgtailifhmakp.supabase.co 2>/dev/null | \
///   openssl x509 -pubkey -noout | \
///   openssl pkey -pubin -outform der | \
///   openssl dgst -sha256 -binary | \
///   openssl enc -base64
///
/// # Backup pin (root CA — prevents lockout on cert rotation)
/// # Download the root CA cert and run:
/// openssl x509 -in gts_root_r4.der -inform DER -pubkey -noout | \
///   openssl pkey -pubin -outform der | \
///   openssl dgst -sha256 -binary | \
///   openssl enc -base64
/// ```
///
/// ## OWASP M3 Compliance
/// This implementation follows the OWASP Mobile Security Testing Guide
/// (MSTG-NETWORK-4): "Verify that the app performs certificate pinning
/// on all HTTPS connections."
final class SSLPinningService: NSObject {

    // MARK: - Pinned Hashes

    /// The pinned SPKI SHA-256 hashes for Supabase's certificate chain.
    ///
    /// **Primary pin**: The leaf certificate's SPKI hash. This pins the exact
    /// certificate Supabase currently uses. Must be updated if Supabase rotates
    /// their certificate.
    ///
    /// **Backup pin**: The root CA's SPKI hash (Google Trust Services Root R4).
    /// This prevents total lockout if Supabase rotates their leaf certificate,
    /// as long as the new cert is issued by the same CA.
    ///
    /// > Important: Always maintain at least one backup pin from a different
    /// > CA to avoid complete lockout during certificate rotation.
    private static let pinnedHashes: [String] = [
        // Primary pin: Supabase leaf certificate SPKI hash (EC P-256)
        // Cert: CN=supabase.co, issued by Google Trust Services WE1
        // Computed: 2025-07-09
        "p51goejPCgGH+Oog/MU2k6PObcEfTrrr73jUcuWJ7w0=",

        // Backup pin: Google Trust Services Root R4 (the root CA)
        // This prevents lockout if Supabase rotates their leaf cert
        // as long as the new cert chains up to the same root.
        "mEflZT5enoR1FuXLgYYGqnVEoZvmf9c2bVBpiOjYQ0c="
    ]

    /// Supabase domain to enforce certificate pinning for.
    private static let pinnedDomain = "qirjjbmrgtailifhmakp.supabase.co"

    /// A secondary pinned domain (Supabase sometimes uses the base domain).
    private static let pinnedDomains = [
        "qirjjbmrgtailifhmakp.supabase.co",
        "supabase.co"
    ]

    // MARK: - URLSession

    /// URLSession delegate that enforces certificate pinning for Supabase.
    ///
    /// Use this session for all HTTPS requests to Supabase endpoints.
    /// Connections to other hosts use default system validation.
    ///
    /// - Note: URLSession strongly retains its delegate (this service).
    ///   Since `SSLPinningService` is a long-lived singleton, this retain
    ///   cycle is acceptable. Call `invalidate()` if you need to tear down.
    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        // Disable caching for security-sensitive requests
        config.urlCache = nil
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    // MARK: - Lifecycle

    /// Invalidates the pinned URLSession and releases resources.
    /// Call this only if you need to explicitly tear down the service.
    func invalidate() {
        urlSession.invalidateAndCancel()
    }

    // MARK: - Pin Validation

    /// Validates that a server trust contains a certificate matching a pinned SPKI hash.
    ///
    /// - Parameter serverTrust: The `SecTrust` object from the URL authentication challenge.
    /// - Returns: `true` if the certificate chain contains a match for at least one pinned hash.
    func validatePin(serverTrust: SecTrust) -> Bool {
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
              !certificateChain.isEmpty else {
            print("[SSLPinning] No certificates found in server trust chain")
            return false
        }

        // Evaluate each certificate in the chain against our pinned hashes.
        // We check the full chain (not just the leaf) to support backup pins.
        for certificate in certificateChain {
            guard let publicKey = extractPublicKey(from: certificate),
                  let publicKeyData = serializePublicKey(publicKey) else {
                continue
            }

            let spkiHash = computeSPKIHash(publicKeyData)

            if Self.pinnedHashes.contains(spkiHash) {
                #if DEBUG
                print("[SSLPinning] Pin matched: \(spkiHash)")
                #endif
                return true
            }
        }

        // No match found — log the computed hashes for debugging
        #if DEBUG
        print("[SSLPinning] No pin matched. Chain hashes:")
        for (index, certificate) in certificateChain.enumerated() {
            guard let publicKey = extractPublicKey(from: certificate),
                  let publicKeyData = serializePublicKey(publicKey) else {
                print("[SSLPinning]   [\(index)]: failed to extract public key")
                continue
            }
            print("[SSLPinning]   [\(index)]: \(computeSPKIHash(publicKeyData))")
        }
        print("[SSLPinning] Expected one of: \(Self.pinnedHashes)")
        #endif

        return false
    }

    // MARK: - Private Helpers

    /// Extracts the `SecKey` public key from a certificate.
    ///
    /// Creates a temporary trust object to extract the public key from the certificate.
    private func extractPublicKey(from certificate: SecCertificate) -> SecKey? {
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        guard SecTrustCreateWithCertificates(certificate, policy, &trust) == errSecSuccess,
              let trust = trust else {
            return nil
        }
        return SecTrustCopyKey(trust)
    }

    /// Serializes a `SecKey` to DER-encoded raw key data.
    ///
    /// Uses `SecKeyCopyExternalRepresentation` to get the raw key bytes
    /// suitable for SPKI hash computation.
    private func serializePublicKey(_ key: SecKey) -> Data? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(key, &error) else {
            if let error = error?.takeRetainedValue() {
                print("[SSLPinning] Key serialization error: \(error)")
            }
            return nil
        }
        return data as Data
    }

    /// Computes the Base64-encoded SHA-256 hash of the Subject Public Key Info (SPKI).
    ///
    /// Constructs the ASN.1 DER-encoded SPKI structure from the raw public key data,
    /// then computes its SHA-256 digest. The SPKI structure includes the algorithm
    /// identifier (EC P-256) and the public key bit string.
    ///
    /// - Parameter keyData: The raw public key bytes from `SecKeyCopyExternalRepresentation`.
    /// - Returns: Base64-encoded SHA-256 hash of the SPKI structure.
    private func computeSPKIHash(_ keyData: Data) -> String {
        // ASN.1 DER structure for SubjectPublicKeyInfo (EC P-256):
        //
        // SubjectPublicKeyInfo  ::=  SEQUENCE  {
        //     algorithm         AlgorithmIdentifier,
        //     subjectPublicKey  BIT STRING  }
        //
        // AlgorithmIdentifier  ::=  SEQUENCE  {
        //     algorithm   OBJECT IDENTIFIER (id-ecPublicKey: 1.2.840.10045.2.1),
        //     parameters  OBJECT IDENTIFIER (prime256v1: 1.2.840.10045.3.1.7)  }
        //
        // For Supabase (Google Trust Services): EC P-256 keys.

        var spkiData = Data()

        // SEQUENCE header (long form: 0x82 = 2 length bytes)
        spkiData.append(contentsOf: [0x30, 0x82])
        let contentLength = keyData.count + 15 // algorithm identifier (19) + bit string wrapper (3) - overhead adjustment
        spkiData.append(UInt8(contentLength >> 8))
        spkiData.append(UInt8(contentLength & 0xFF))

        // AlgorithmIdentifier SEQUENCE for EC P-256
        spkiData.append(contentsOf: [
            0x30, 0x13, // SEQUENCE, length 19
            // OID ecPublicKey (1.2.840.10045.2.1)
            0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01,
            // OID prime256v1 (1.2.840.10045.3.1.7)
            0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07
        ])

        // BIT STRING containing the raw public key (0x03 = BIT STRING, 0x42 = length 66, 0x00 = unused bits)
        spkiData.append(contentsOf: [0x03, 0x42, 0x00])
        spkiData.append(keyData)

        let digest = SHA256.hash(data: spkiData)
        return Data(digest).base64EncodedString()
    }
}

// MARK: - URLSessionDelegate

extension SSLPinningService: URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only enforce pinning for our Supabase domain(s).
        // All other connections fall back to default system validation.
        guard Self.pinnedDomains.contains(challenge.protectionSpace.host),
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate the certificate chain against our pinned hashes
        guard validatePin(serverTrust: serverTrust) else {
            print("[SSLPinning] PIN VALIDATION FAILED for \(challenge.protectionSpace.host)")
            print("[SSLPinning] Rejecting connection to prevent potential MITM attack.")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Pin matches — accept the certificate and establish the connection
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}
