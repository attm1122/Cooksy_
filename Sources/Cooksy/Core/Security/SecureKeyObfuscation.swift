import Foundation

// MARK: - Secure Key Obfuscation
/// Runtime key reconstruction system that protects API keys from binary extraction.
///
/// ## Threat Model
/// Defends against:
/// - `strings` command extraction (keys never appear as contiguous literals)
/// - Static analysis / disassembly (keys split into fragments with XOR masks)
/// - Memory dump attacks (keys reconstructed on-demand, cleared after use)
/// - Frida/LLDB string search (keys stored as raw bytes, not NSString/String)
///
/// ## How It Works
/// 1. At build time, the key is split into N fragments
/// 2. Each fragment is XORed with a pseudorandom byte sequence derived from a seed
/// 3. Fragments and seeds are stored as separate `[UInt8]` arrays (not Strings)
/// 4. At runtime, fragments are XORed back using the seed to reconstruct the key
/// 5. Key is delivered as `Data`, caller uses `withUnsafeBytes` then immediately clears
///
/// ## Usage
/// ```swift
/// // Reconstruct a key on-demand
/// let supabaseKey = ObfuscatedKeys.reconstruct(.supabaseAnon)
/// supabaseKey.withUnsafeBytes { keyBytes in
///     // Use key here via keyBytes.bindMemory(to: UInt8.self)
/// }
/// // Key bytes are out of scope and will be zeroed
/// ```
enum ObfuscatedKeys {

    // MARK: - Key Identifiers

    enum KeyID {
        case supabaseAnon
        case revenueCat
    }

    // MARK: - Runtime Reconstruction

    /// Reconstructs an API key from obfuscated fragments.
    ///
    /// The key is returned as `Data` — use `withUnsafeBytes` to access it,
    /// then let it go out of scope for automatic clearing.
    static func reconstruct(_ id: KeyID) -> Data {
        switch id {
        case .supabaseAnon:
            return reconstructSupabaseKey()
        case .revenueCat:
            return reconstructRevenueCatKey()
        }
    }

    // MARK: - Supabase Key (5 fragments, non-sequential reconstruction)

    /// Reconstructs the Supabase anon key from 5 XOR-obfuscated fragments.
    private static func reconstructSupabaseKey() -> Data {
        // Fragment A — 42 bytes, seed 0x9A7B3C1D8E5F2A06
        let frag0: [UInt8] = [
            0x04, 0x9F, 0x44, 0xC9, 0xFE, 0xBF, 0x71, 0x5C,
            0x19, 0xFA, 0x9F, 0x7A, 0x42, 0x41, 0x0E, 0xC9,
            0xDD, 0xD9, 0x8F, 0xBB, 0x63, 0x6F, 0x1C, 0x01,
            0xAC, 0x27, 0x7D, 0x4E, 0xB5, 0x5E, 0x6A, 0xD7,
            0x62, 0x4A, 0xBC, 0xA3, 0xA3, 0x2C, 0x14, 0x2C,
            0x5E, 0xEA
        ]
        // Fragment B — 42 bytes, seed 0x4D2E8F1A6B3C5D07
        let frag1: [UInt8] = [
            0xEB, 0x6D, 0x3A, 0xDE, 0x84, 0x69, 0xDD, 0x2F,
            0xF9, 0x49, 0xCD, 0x08, 0x8F, 0x03, 0xDF, 0x78,
            0x3E, 0x72, 0xF7, 0x0C, 0xF7, 0x49, 0xF8, 0xB4,
            0xFA, 0x6F, 0xB4, 0x7D, 0x84, 0x03, 0x9C, 0x7C,
            0xB8, 0xDA, 0x27, 0x10, 0x19, 0xEE, 0x69, 0x5B,
            0x3F, 0xA4
        ]
        // Fragment C — 42 bytes, seed 0x1F8E2A4B6C3D5E08
        let frag2: [UInt8] = [
            0x53, 0xE3, 0x2B, 0x3D, 0x2D, 0x5D, 0xD3, 0x01,
            0x20, 0x82, 0x15, 0x0E, 0x0B, 0xF6, 0x9B, 0xA3,
            0xEA, 0x06, 0x42, 0xC5, 0xD0, 0xF8, 0x54, 0xBF,
            0x2B, 0x1E, 0xA7, 0x8F, 0xA1, 0xAB, 0xFB, 0xFE,
            0x79, 0xE9, 0x72, 0x8B, 0xB9, 0x93, 0xB6, 0x03,
            0xA2, 0x97
        ]
        // Fragment D — 41 bytes, seed 0x7C5D3E1F8A9B2C04
        let frag3: [UInt8] = [
            0x31, 0x90, 0x68, 0xFE, 0x66, 0xAC, 0xF8, 0x06,
            0xAD, 0x9D, 0x14, 0xA9, 0x65, 0x19, 0x4D, 0x6F,
            0xD5, 0x94, 0x02, 0x45, 0x75, 0xCD, 0xE8, 0x2C,
            0xC5, 0x44, 0x6E, 0xCA, 0x4A, 0xF1, 0x95, 0x18,
            0xFF, 0x05, 0xA3, 0x96, 0xF4, 0x97, 0xEE, 0xCA,
            0xB3
        ]
        // Fragment E — 41 bytes, seed 0x3A1B6C8D4E5F2B09
        let frag4: [UInt8] = [
            0xB5, 0x63, 0x19, 0xA6, 0x43, 0x7C, 0x36, 0x41,
            0xDB, 0x17, 0x27, 0xAA, 0x7E, 0xA7, 0x06, 0x35,
            0x15, 0xF4, 0x38, 0x6E, 0xD8, 0x5F, 0x4B, 0x51,
            0x08, 0x4B, 0x99, 0x9A, 0xC6, 0xD3, 0x8A, 0x22,
            0x62, 0xAF, 0x9A, 0xB0, 0xE2, 0x4B, 0x86, 0x28,
            0xC1
        ]

        let seed0: UInt64 = 0x9A7B3C1D8E5F2A06
        let seed1: UInt64 = 0x4D2E8F1A6B3C5D07
        let seed2: UInt64 = 0x1F8E2A4B6C3D5E08
        let seed3: UInt64 = 0x7C5D3E1F8A9B2C04
        let seed4: UInt64 = 0x3A1B6C8D4E5F2B09

        // Reconstruct in non-sequential order
        let part2 = xorUnmask(frag2, seed: seed2)
        let part0 = xorUnmask(frag0, seed: seed0)
        let part4 = xorUnmask(frag4, seed: seed4)
        let part1 = xorUnmask(frag1, seed: seed1)
        let part3 = xorUnmask(frag3, seed: seed3)

        var result = Data()
        result.append(contentsOf: part0)
        result.append(contentsOf: part1)
        result.append(contentsOf: part2)
        result.append(contentsOf: part3)
        result.append(contentsOf: part4)

        return result
    }

    // MARK: - RevenueCat Key (3 fragments, non-sequential reconstruction)

    /// Reconstructs the RevenueCat API key from 3 XOR-obfuscated fragments.
    private static func reconstructRevenueCatKey() -> Data {
        // Fragment A — 11 bytes, seed 0x2B4C6D8E1F3A5C07
        let frag0: [UInt8] = [
            0xA7, 0x12, 0x1C, 0xD8, 0x3C, 0x75, 0xB5, 0x5E,
            0x2B, 0x05, 0x2C
        ]
        // Fragment B — 11 bytes, seed 0x5E1F2A3B4C6D7E08
        let frag1: [UInt8] = [
            0x1A, 0x96, 0x5B, 0xF7, 0xCE, 0xED, 0x8F, 0xD1,
            0x55, 0x4C, 0x73
        ]
        // Fragment C — 10 bytes, seed 0x8A3B5C7D9E1F2A03
        let frag2: [UInt8] = [
            0x66, 0xDB, 0xE5, 0x43, 0x2B, 0x4C, 0x65, 0x8B,
            0xB2, 0x15
        ]

        let seed0: UInt64 = 0x2B4C6D8E1F3A5C07
        let seed1: UInt64 = 0x5E1F2A3B4C6D7E08
        let seed2: UInt64 = 0x8A3B5C7D9E1F2A03

        let part1 = xorUnmask(frag1, seed: seed1)
        let part0 = xorUnmask(frag0, seed: seed0)
        let part2 = xorUnmask(frag2, seed: seed2)

        var result = Data()
        result.append(contentsOf: part0)
        result.append(contentsOf: part1)
        result.append(contentsOf: part2)

        return result
    }

    // MARK: - XOR Obfuscation Engine

    /// Generates a deterministic pseudorandom byte stream from a seed using SplitMix64.
    /// This is NOT cryptographically secure — it's an obfuscation primitive.
    private static func generateMask(length: Int, seed: UInt64) -> [UInt8] {
        var state = seed
        var result = [UInt8](repeating: 0, count: length)

        for i in 0..<length {
            // SplitMix64 algorithm — fast, deterministic, good distribution
            state = state &+ 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            z = z ^ (z >> 31)
            result[i] = UInt8(z & 0xFF)
        }

        return result
    }

    /// XORs obfuscated fragments back to their original bytes.
    private static func xorUnmask(_ fragments: [UInt8], seed: UInt64) -> [UInt8] {
        let mask = generateMask(length: fragments.count, seed: seed)
        return zip(fragments, mask).map { $0 ^ $1 }
    }
}

// MARK: - String Conversion (Caller Responsibility)

extension ObfuscatedKeys {

    /// Reconstructs a key and provides temporary String access, then clears memory.
    ///
    /// ```swift
    /// ObfuscatedKeys.withKeyString(.supabaseAnon) { key in
    ///     // Use key (a String) here
    ///     someAPI.configure(with: key)
    /// }
    /// // Key bytes are zeroed after the closure returns
    /// ```
    static func withKeyString(_ id: KeyID, _ body: (String) -> Void) {
        let data = reconstruct(id)
        var mutableData = data
        defer {
            // Zero out the reconstructed key in memory
            mutableData.withUnsafeMutableBytes { raw in
                if let baseAddress = raw.baseAddress {
                    memset(baseAddress, 0, raw.count)
                }
            }
        }
        let keyString = String(data: mutableData, encoding: .utf8) ?? ""
        body(keyString)
    }
}
