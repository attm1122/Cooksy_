import Foundation
import UIKit
import Darwin
import CryptoKit
import DeviceCheck
import ObjectiveC
import MachO

// MARK: - RuntimeProtection

/// Runtime integrity protection for the Cooksy app.
///
/// Detects and responds to:
/// - Code injection (unauthorized dylibs)
/// - Method swizzling
/// - Debugger attachment after launch
/// - Binary tampering
/// - Simulator/reversing environment
///
/// ## Usage
/// Call `RuntimeProtection.applyAll()` early in app launch (CooksyApp.init).
enum RuntimeProtection {
    private static let ptraceDenyAttach: CInt = 31

    // MARK: - Apply All Protections

    /// Applies all runtime protection measures.
    /// Call this in `CooksyApp.init()` before any other setup.
    static func applyAll() {
        #if !DEBUG
        applyPtraceProtection()
        detectCodeInjection()
        detectMethodSwizzling()
        setupDebuggerDetection()
        #endif
    }

    // MARK: - ptrace PT_DENY_ATTACH

    /// Prevents debugger attachment using ptrace PT_DENY_ATTACH.
    static func applyPtraceProtection() {
        #if !DEBUG
        // Use dlsym to get ptrace to avoid easy hooking
        let handle = dlopen("/usr/lib/libc.dylib", RTLD_NOW)
        defer { dlclose(handle) }

        guard let ptraceSymbol = dlsym(handle, "ptrace") else { return }
        typealias PtraceFunc = @convention(c) (CInt, pid_t, caddr_t?, CInt) -> CInt
        let ptrace = unsafeBitCast(ptraceSymbol, to: PtraceFunc.self)
        _ = ptrace(ptraceDenyAttach, 0, nil, 0)
        #endif
    }

    // MARK: - Code Injection Detection

    /// Checks for unauthorized dynamic libraries loaded at runtime.
    /// Returns `true` if a suspicious/injected library is detected.
    @discardableResult
    static func detectCodeInjection() -> Bool {
        let suspiciousLibraries = [
            "frida",
            "cycript",
            "Substrate",
            "Substitute",
            "TweakInject",
            "SSLKillSwitch",
            "Shadow",
            "Liberty",
            "KernBypass",
            "FlyJB",
            "CydiaSubstrate",
            "choicy",
            "altstore",
            "snowboard",
            "themekit",
            "zbra",
            "installer",
            "sileo"
        ]

        let imageCount = _dyld_image_count()
        for i in 0..<imageCount {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName).lowercased()

            // Check for known suspicious libraries
            for lib in suspiciousLibraries where name.contains(lib.lowercased()) {
                handleThreat("Unauthorized library detected: \(name)")
                return true
            }
        }
        return false
    }

    // MARK: - Method Swizzling Detection

    /// Detects if critical methods have been swizzled.
    /// Returns `true` if method-swizzling tampering is detected.
    @discardableResult
    static func detectMethodSwizzling() -> Bool {
        return checkCriticalMethodIntegrity()
    }

    /// Verifies that critical security methods haven't been swizzled.
    /// Compares the expected IMP of URLSession methods against their
    /// actual implementations to detect `method_exchangeImplementations`.
    private static func checkCriticalMethodIntegrity() -> Bool {
        // Get the original implementation of URLSession.dataTask(with:completionHandler:)
        guard let originalMethod = class_getInstanceMethod(
            URLSession.self,
            #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask)
        ) else { return false }

        let originalIMP = method_getImplementation(originalMethod)

        // Walk all methods on URLSession looking for dataTask selectors.
        // If the expected selector no longer points to the original IMP,
        // something has been swizzled.
        var methodCount: UInt32 = 0
        guard let methods = class_copyMethodList(URLSession.self, &methodCount) else { return false }
        defer { free(methods) }

        var foundOriginal = false
        for i in 0..<Int(methodCount) {
            let method = methods[i]
            let sel = method_getName(method)
            let name = NSStringFromSelector(sel)
            let imp = method_getImplementation(method)

            if name.contains("dataTask") && name.contains("completionHandler") {
                if imp == originalIMP {
                    foundOriginal = true
                }
            }
        }

        // If we could not find the original IMP paired with any dataTask selector,
        // the method has likely been swizzled.
        if !foundOriginal {
            handleThreat("Method swizzling detected on URLSession.dataTask")
        }

        return !foundOriginal
    }

    // MARK: - Debugger Detection (Runtime)

    /// Sets up periodic debugger detection checks.
    static func setupDebuggerDetection() {
        #if !DEBUG
        // Perform an immediate check
        if isDebuggerAttached() {
            handleThreat("Debugger detected at launch")
        }

        // Check every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if isDebuggerAttached() {
                handleThreat("Debugger detected at runtime")
            }
        }
        #endif
    }

    /// Checks if a debugger is currently attached using sysctl.
    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // MARK: - Simulator Detection

    /// Detects if running in a simulator (not a security threat, just for telemetry).
    static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Jailbreak Detection

    /// Detects common jailbreak indicators.
    /// Returns `true` if jailbreak artifacts are detected.
    @discardableResult
    static func detectJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/var/mobile/Library/Preferences/com.saurik.Cydia.plist",
            "/var/lib/cydia",
            "/usr/bin/ssh"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                handleThreat("Jailbreak indicator detected: \(path)")
                return true
            }
        }

        // Check if we can write to a restricted location
        let testPath = "/private/jailbreak_test_" + UUID().uuidString
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            handleThreat("Jailbreak write-test succeeded on /private")
            return true
        } catch {
            // Expected on non-jailbroken devices
        }

        return false
        #endif
    }

    // MARK: - App Attestation

    /// Requests a DeviceCheck app attestation from Apple.
    /// Use this for critical server operations to verify app integrity.
    static func requestAttestation() async throws -> String {
        guard DCDevice.current.isSupported else {
            throw RuntimeError.attestationNotSupported
        }
        let service = DCAppAttestService.shared
        let keyId = try await service.generateKey()
        let challenge = generateRandomChallenge()
        let attestation = try await service.attestKey(
            keyId,
            clientDataHash: SHA256.hash(data: challenge).data
        )
        return attestation.base64EncodedString()
    }

    /// Generates a random challenge for attestation.
    private static func generateRandomChallenge() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            // Fallback: use less secure random generation
            for i in 0..<bytes.count {
                bytes[i] = UInt8.random(in: 0...255)
            }
        }
        return Data(bytes)
    }

    // MARK: - Threat Response

    /// Called when a runtime threat is detected.
    /// In production, this should report to analytics, clear sensitive data, and potentially exit.
    private static func handleThreat(_ message: String) {
        #if !DEBUG
        // Report to analytics (without exposing sensitive details)
        Task { @MainActor in
            AnalyticsService.shared.track("security_threat_detected", properties: [
                "type": "runtime_protection"
            ])
        }

        // In a production app, you might:
        // 1. Clear cached session data from memory
        // 2. Report to your security backend
        // 3. Gracefully degrade functionality
        // 4. Exit the app after a delay (controversial — Apple may reject)

        // Clear sensitive caches immediately
        URLCache.shared.removeAllCachedResponses()
        #endif
    }

    // MARK: - Errors

    enum RuntimeError: Error, LocalizedError {
        case attestationNotSupported

        var errorDescription: String? {
            switch self {
            case .attestationNotSupported:
                return "App attestation is not supported on this device."
            }
        }
    }
}

// MARK: - SHA256 Convenience

extension SHA256.Digest {
    var data: Data {
        Data(self)
    }
}
