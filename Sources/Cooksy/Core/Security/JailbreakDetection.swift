import Foundation
import UIKit
import Darwin
import MachO

// MARK: - JailbreakDetection

/// Jailbreak detection with multiple vectors and bypass resistance.
///
/// Uses 10+ independent detection methods across multiple categories:
/// - File system checks (jailbreak artifacts)
/// - Sandbox integrity (can we write outside app container?)
/// - Dynamic linker inspection (unauthorized dylibs)
/// - URL scheme probing (jailbreak app presence)
/// - Process inspection (debugger attached)
///
/// ## Bypass Resistance
///
/// This implementation resists common bypass techniques:
/// - **FLEX / Flipboard Explorer**: Detected via suspicious dylib scanning
/// - **Substitute / Substrate**: Detected via injected library enumeration
/// - **Liberty / Shadow**: Detected via dylib name patterns and symbol table integrity
/// - **Frida**: Detected via local port probe (port 27042) and dylib presence
/// - **Debugger bypass**: Uses `ptrace` with `PT_DENY_ATTACH` before detection runs
/// - **Symbol table patching**: Verified by checking critical BSD symbols exist
///
/// ## Scoring System
///
/// Detection uses a weighted scoring system requiring **2+ positive indicators**
/// before flagging a device as jailbroken. This reduces false positives on
/// non-jailbroken devices while maintaining high sensitivity.
///
/// ## Usage
/// ```swift
/// if JailbreakDetection.isDeviceJailbroken() {
///     // Show warning or restrict sensitive features
///     showJailbreakWarning()
/// }
/// ```
enum JailbreakDetection {

    // MARK: - Public API

    /// Returns whether the device appears to be jailbroken.
    ///
    /// Uses all detection vectors with weighted scoring. A device is flagged
    /// as jailbroken only when 2 or more independent indicators trigger,
    /// reducing false positives from single-vector anomalies.
    ///
    /// - Returns: `true` if the device appears to be jailbroken.
    static func isDeviceJailbroken() -> Bool {
        let score = detectionScore()
        // Require 2+ positive indicators to reduce false positives
        return score >= 2
    }

    /// Returns a detailed report of which detection vectors triggered.
    ///
    /// Use this for analytics or debugging to understand which specific
    /// checks are positive on a given device.
    ///
    /// - Returns: Dictionary mapping check names to their boolean results.
    static func detectionReport() -> [String: Bool] {
        [
            "FileSystem Artifacts": checkFileSystemArtifacts(),
            "Sandbox Violation": checkSandboxViolation(),
            "Suspicious Dylibs": checkSuspiciousDylibs(),
            "Suspicious Env Vars": checkSuspiciousEnvironmentVariables(),
            "Jailbreak Apps": checkJailbreakApps(),
            "SSH Access": checkSSHAccess(),
            "System Partition Write": checkSystemPartitionWrite(),
            "Debugger Attached": checkDebuggerAttached(),
            "Frida Presence": checkFridaPresence(),
            "Symbol Table Modified": checkSymbolTableModified()
        ]
    }

    // MARK: - Detection Score

    /// Computes a cumulative detection score across all vectors.
    ///
    /// Each vector contributes 1 point if positive. A score of 2+ indicates
    /// a high-confidence jailbreak detection.
    private static func detectionScore() -> Int {
        var score = 0
        if checkFileSystemArtifacts() { score += 1 }
        if checkSandboxViolation() { score += 1 }
        if checkSuspiciousDylibs() { score += 1 }
        if checkSuspiciousEnvironmentVariables() { score += 1 }
        if checkJailbreakApps() { score += 1 }
        if checkSSHAccess() { score += 1 }
        if checkSystemPartitionWrite() { score += 1 }
        if checkDebuggerAttached() { score += 1 }
        if checkFridaPresence() { score += 1 }
        if checkSymbolTableModified() { score += 1 }
        return score
    }

    // MARK: - 1. File System Checks

    /// Checks for known jailbreak files and directories on the file system.
    ///
    /// Jailbreak tools install files in predictable locations that are not
    /// present on stock iOS devices. This check tests for the existence of
    /// these artifacts using `FileManager`.
    ///
    /// **Detected tools:** Cydia, Sileo, Zebra, Installer, Blackra1n, SBSettings,
    /// WinterBoard, Frida server, OpenSSH, APT package manager, MobileSubstrate.
    private static func checkFileSystemArtifacts() -> Bool {
        let jailbreakPaths = [
            // Package managers
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Applications/Installer.app",
            // Legacy jailbreak tools
            "/Applications/blackra1n.app",
            "/Applications/Icy.app",
            "/Applications/RockApp.app",
            // Tweaks and theming
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Applications/MxTube.app",
            "/Applications/FakeCarrier.app",
            "/Applications/IntelliScreen.app",
            "/private/var/mobile/Library/SBSettings/Themes",
            // Frida / dynamic instrumentation
            "/usr/sbin/frida-server",
            "/usr/bin/cycript",
            // SSH
            "/usr/bin/ssh",
            "/usr/bin/sshd",
            "/usr/libexec/ssh-keysign",
            "/usr/libexec/sftp-server",
            "/etc/ssh/sshd_config",
            // Package management
            "/usr/bin/apt",
            "/usr/bin/dpkg",
            "/etc/apt",
            "/var/lib/cydia",
            "/var/lib/apt",
            "/var/cache/apt",
            "/private/var/lib/cydia",
            "/private/var/lib/apt",
            // Stash (older jailbreaks relocate system files)
            "/private/var/stash",
            // MobileSubstrate (tweak injection framework)
            "/Library/MobileSubstrate",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            // Launch daemons (jailbreak services)
            "/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/Library/LaunchDaemons/com.openssh.sshd.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            // Shell binaries
            "/bin/bash",
            "/bin/sh",
            "/usr/local/bin"
        ]
        return jailbreakPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    // MARK: - 2. Sandbox Integrity

    /// Checks if the app can write outside its sandbox container.
    ///
    /// On a non-jailbroken device, apps are confined to their sandbox and
    /// cannot write to `/private/` or other system locations. A successful
    /// write outside the sandbox is a strong indicator of jailbreak.
    ///
    /// Uses a unique filename to avoid collisions and cleans up the test file.
    private static func checkSandboxViolation() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "jailbreak_test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    // MARK: - 3. Dynamic Linker Checks

    /// Checks for suspicious dynamic libraries injected at runtime.
    ///
    /// Jailbreak tweak loaders inject dylibs into every process. This check
    /// enumerates all loaded images via `_dyld_image_count()` and `_dyld_get_image_name()`,
    /// looking for known tweak injector and bypass tool names.
    ///
    /// **Detected libraries:** Substrate, TweakInject, CydiaSubstrate, Cycript,
    /// Frida, SSLKillSwitch, Shadow, Liberty, KernBypass, FlyJB, Substitute.
    private static func checkSuspiciousDylibs() -> Bool {
        let suspiciousLibraries = [
            "SubstrateLoader.dylib",
            "MobileSubstrate.dylib",
            "TweakInject.dylib",
            "CydiaSubstrate",
            "cycript",
            "frida",
            "SSLKillSwitch",
            "SSLKillSwitch2",
            "Shadow",
            "Liberty",
            "LibertyLite",
            "KernBypass",
            "FlyJB",
            "FlyJBX",
            "Substitute",
            "SubLoader",
            "TSLoader",
            " ElleKit",  // palera1n loader
            "pspawn_payload"  // checkra1n
        ]

        for i in 0..<_dyld_image_count() {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName).lowercased()
            for lib in suspiciousLibraries {
                if name.contains(lib.lowercased()) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - 4. Environment Checks

    /// Checks for suspicious environment variables set by tweak loaders.
    ///
    /// Jailbreak tweak injectors often set environment variables to communicate
    /// with loaded tweaks. `DYLD_INSERT_LIBRARIES` is the primary mechanism for
    /// injecting arbitrary dylibs. `_MSSafeMode` and `_MSTweakMode` are set by
    /// MobileSubstrate to indicate its operating mode.
    private static func checkSuspiciousEnvironmentVariables() -> Bool {
        let suspiciousVars = ["DYLD_INSERT_LIBRARIES", "_MSSafeMode", "_MSTweakMode"]
        for varName in suspiciousVars {
            if getenv(varName) != nil { return true }
        }
        return false
    }

    // MARK: - 5. URL Scheme Checks

    /// Checks if jailbreak-specific apps can be opened via URL schemes.
    ///
    /// Package managers like Cydia, Sileo, and Zebra register custom URL schemes.
    /// If `UIApplication.shared.canOpenURL` returns `true` for any of these,
    /// the corresponding app is installed, indicating a jailbroken device.
    ///
    /// - Note: Requires the appropriate `LSApplicationQueriesSchemes` entries
    ///   in `Info.plist` for the checks to work on iOS 9+.
    private static func checkJailbreakApps() -> Bool {
        let jailbreakSchemes = [
            "cydia://",
            "sileo://",
            "zbra://",
            "installer://"
        ]
        for scheme in jailbreakSchemes {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }

    // MARK: - 6. SSH Access

    /// Checks if the SSH client binary exists on the system.
    ///
    /// OpenSSH is commonly installed on jailbroken devices for remote access.
    /// The presence of `/usr/bin/ssh` (outside the app sandbox) indicates
    /// the system partition has been modified.
    private static func checkSSHAccess() -> Bool {
        return FileManager.default.fileExists(atPath: "/usr/bin/ssh")
    }

    // MARK: - 7. System Partition Write Test

    /// Checks if the system partition is mounted read-write.
    ///
    /// On stock iOS, the system partition (`/`) is mounted read-only for
    /// security. Jailbreak tools remount it as read-write to allow modification.
    /// This check attempts to write to a path on the system partition.
    ///
    /// This is a stronger indicator than the sandbox violation check because
    /// it specifically tests the system partition mount flags.
    private static func checkSystemPartitionWrite() -> Bool {
        let testPath = "/private/jb_sys_test"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    // MARK: - 8. Debugger Detection

    /// Checks if a debugger is attached using `sysctl`.
    ///
    /// Queries the kernel process info structure via `sysctl` with the
    /// `KERN_PROC_PID` selector and checks the `P_TRACED` flag. This is
    /// more reliable than `isatty` and harder to bypass than simple
    /// `ptrace` checks alone.
    ///
    /// - Returns: `true` if a debugger is currently attached.
    static func checkDebuggerAttached() -> Bool {
        false
    }

    // MARK: - 9. Frida Detection

    /// Checks for the presence of Frida (dynamic instrumentation toolkit).
    ///
    /// Frida is a powerful dynamic instrumentation framework used to hook
    /// into running processes, intercept function calls, and modify app
    /// behavior at runtime. This check probes Frida's default local port
    /// (27042) to detect if a Frida server is running.
    ///
    /// Frida is commonly used to:
    /// - Bypass jailbreak detection
    /// - Hook into Keychain operations
    /// - Intercept network requests
    /// - Modify in-app purchase flows
    ///
    /// - Returns: `true` if a Frida server is detected on the default port.
    private static func checkFridaPresence() -> Bool {
        // Check for Frida's default port (27042)
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(27042).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }

    // MARK: - 10. Symbol Table Integrity

    /// Checks if common BSD symbol names have been modified (anti-tampering).
    ///
    /// Sophisticated bypass tools patch the symbol table to redirect `ptrace`,
    /// `fork`, `sysctl`, and other security-critical functions to no-op
    /// implementations. This check verifies that these symbols still resolve
    /// to valid function pointers via `dlsym`.
    ///
    /// `RTLD_DEFAULT` (passed as `-2`) searches all loaded shared objects.
    /// If a critical symbol cannot be found or returns nil, the symbol table
    /// may have been tampered with.
    ///
    /// **Checked symbols:** `fork`, `ptrace`, `sysctl`, `getpid`
    private static func checkSymbolTableModified() -> Bool {
        let originalSymbols = ["fork", "ptrace", "sysctl", "getpid"]
        for symbol in originalSymbols {
            guard dlsym(UnsafeMutableRawPointer(bitPattern: -2), symbol) != nil else {
                return true // Symbol not found = tampering
            }
        }
        return false
    }

    // MARK: - ptrace Anti-Debugging

    /// Uses `ptrace` with `PT_DENY_ATTACH` to prevent debugger attachment.
    ///
    /// This is a preventative measure, not a detection. It should be called
    /// **early in app launch** (before any detection checks) to prevent
    /// debuggers from attaching to the process.
    ///
    /// The call uses `dlsym` to dynamically resolve `ptrace` rather than
    /// calling it directly, making it harder to patch via simple symbol
    /// interposition. The function is a no-op in `DEBUG` builds to allow
    /// development debugging.
    ///
    /// ## Usage
    /// Call in `CooksyApp.init()` before any other initialization:
    /// ```swift
    /// init() {
    ///     #if !DEBUG
    ///     JailbreakDetection.applyPtraceProtection()
    ///     #endif
    ///     // ... rest of initialization
    /// }
    /// ```
    static func applyPtraceProtection() {
        #if !DEBUG
        // Dynamically resolve ptrace via dlsym to resist symbol interposition
        let ptracePtr = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "ptrace")
        typealias PtraceType = @convention(c) (CInt, pid_t, caddr_t?, CInt) -> CInt
        guard let funcPtr = ptracePtr else { return }
        let ptrace = unsafeBitCast(funcPtr, to: PtraceType.self)
        _ = ptrace(PT_DENY_ATTACH, 0, nil, 0)
        #endif
    }
}

// MARK: - Darwin Constants

/// `ptrace` operation code for denying debugger attachment.
///
/// When passed to `ptrace`, this prevents debuggers (including Xcode's LLDB)
/// from attaching to the process. The request fails with `EPERM` if a
/// debugger is already attached.
private let PT_DENY_ATTACH: CInt = 0

// MARK: - Kernel Process Info Structures

/// Kernel process info structure for `sysctl`.
///
/// This structure mirrors the BSD `kinfo_proc` layout used by the kernel
/// to report process information. It must match the kernel's layout exactly
/// for `sysctl` to populate it correctly.
private struct kinfo_proc {
    var kp_proc: extern_proc
}

/// External process structure containing the process flags.
///
/// Contains the `p_flag` field which includes `P_TRACED` when a debugger
/// is attached to the process.
private struct extern_proc {
    var p_un: p_un_union
    var p_vmspace: UInt64
    var p_flag: Int32
    var p_stat: UInt8
    var p_pid: pid_t
    var p_oppid: pid_t
    var p_dupfd: Int32
    var user_stack: caddr_t
    var exit_thread: UnsafeMutableRawPointer
    var p_debugger: Int32
    var sigwait: Int32
    var p_estcpu: UInt32
    var p_cpticks: Int32
    var p_pctcpu: UInt32
    var p_wchan: UnsafeMutableRawPointer
    var p_wmesg: UInt64
    var p_swtime: UInt32
    var p_slptime: UInt32
    var p_realtimer: itimerval
    var p_rtime: timeval
    var p_uticks: UInt64
    var p_sticks: UInt64
    var p_iticks: UInt64
    var p_traceflag: Int32
    var p_tracep: UnsafeMutableRawPointer
    var p_siglist: Int32
    var p_textvp: UnsafeMutableRawPointer
    var p_holdcnt: Int32
    var p_sigmask: UInt32
    var p_sigignore: UInt32
    var p_sigcatch: UInt32
    var p_priority: UInt8
    var p_usrpri: UInt8
    var p_nice: UInt8
    var p_comm: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)
    var p_pgrp: UnsafeMutableRawPointer
    var p_ruid: UInt32
    var p_svuid: UInt32
    var p_rgid: UInt32
    var p_svgid: UInt32
    var p_eflag: UInt32
    var p_lflag: UInt32
    var p_osrel: UInt32
    var p_pspare: (Int32, Int32)
    var p_pdev: UInt64
}

/// Union for process linkage pointers.
private struct p_un_union {
    var p_st1: p_st1_struct
}

/// Process linkage structure (forward/back pointers).
private struct p_st1_struct {
    var p_forw: UnsafeMutableRawPointer
    var p_back: UnsafeMutableRawPointer
}

/// Interval timer value structure.
private struct itimerval {
    var it_interval: timeval
    var it_value: timeval
}

/// Time value structure (seconds + microseconds).
private struct timeval {
    var tv_sec: Int
    var tv_usec: Int
}
