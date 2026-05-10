# App Transport Security (ATS) Configuration Reference

> **For:** Cooksy iOS App (iOS 17+)
> **Location:** Add to `Info.plist` of the Xcode project when building
> **Last Updated:** January 2025

---

## Overview

App Transport Security (ATS) enforces secure network connections between the app
and backend services. Cooksy uses **strict ATS mode** with a single, carefully
reviewed exception for the Supabase API. This document provides the exact
configuration to copy into the app's `Info.plist`.

## Why Strict ATS Matters for Cooksy

Recipe apps handle sensitive user data — personal recipes, dietary preferences,
account credentials, and payment information. ATS prevents:

- **Credential theft:** Blocking plaintext HTTP stops credentials from leaking
  over unencrypted Wi-Fi (coffee shop, airport networks).
- **Recipe tampering:** Ensures recipes fetched from Supabase cannot be
  modified in transit by a network attacker.
- **Fingerprinting:** TLS 1.3 reduces metadata exposure compared to older
  versions.
- **Man-in-the-middle attacks:** Certificate transparency logs prevent
  attackers from using fraudulently issued certificates.

## Full Info.plist Configuration

Add the following dictionary as a top-level key in `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- Strict ATS: Block ALL non-HTTPS traffic by default -->
    <key>NSAllowsArbitraryLoads</key>
    <false/>

    <!-- Block non-HTTPS media loading (images, videos) -->
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <false/>

    <!--
        Block non-HTTPS in web content.
        Cooksy opens YouTube/TikTok/Instagram links in Safari,
        NOT in an in-app WKWebView. Therefore no web content
        exception is needed — the external browser handles its
        own security.
    -->
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <false/>

    <!-- Require TLS 1.3 minimum for all connections -->
    <key>NSExceptionMinimumTLSVersion</key>
    <string>TLSv1.3</string>

    <!-- Require certificate transparency for all certificates -->
    <key>NSRequiresCertificateTransparency</key>
    <true/>

    <!--
        ============================================
        SUPABASE API EXCEPTION — ONLY ALLOWED EXCEPTION
        ============================================

        The Supabase API (qirjjbmrgtailifhmakp.supabase.co) is the
        sole backend service. This exception maintains full security
        while allowing the connection:
    -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>qirjjbmrgtailifhmakp.supabase.co</key>
        <dict>
            <!-- Apply to subdomains (*.supabase.co) -->
            <key>NSIncludesSubdomains</key>
            <true/>

            <!-- Require forward secrecy (ephemeral key exchange) -->
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>

            <!-- Minimum TLS 1.3 for the exception as well -->
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.3</string>
        </dict>
    </dict>
</dict>
```

---

## Setting-by-Setting Reference

| Key | Value | Rationale |
|-----|-------|-----------|
| `NSAllowsArbitraryLoads` | `false` | Blocks all non-HTTPS traffic globally. This is the foundation of ATS security. |
| `NSAllowsArbitraryLoadsForMedia` | `false` | Prevents HTTP image/video loading. Recipe images are loaded via HTTPS from Supabase Storage only. |
| `NSAllowsArbitraryLoadsInWebContent` | `false` | Since Cooksy opens external links (YouTube/TikTok recipe sources) in Safari — not an in-app web view — no web content exception is needed. The Safari app is responsible for its own transport security. |
| `NSExceptionMinimumTLSVersion` | `TLSv1.3` | TLS 1.3 provides improved handshake speed, removes obsolete cipher suites, and reduces metadata leakage compared to TLS 1.2. |
| `NSRequiresCertificateTransparency` | `true` | Requires all TLS certificates to appear in public Certificate Transparency logs. Prevents attackers from using secretly-issued fraudulent certificates for MITM attacks. |

### Supabase Exception Domain

| Key | Value | Rationale |
|-----|-------|-----------|
| `NSIncludesSubdomains` | `true` | Covers all Supabase subdomains (API, auth, storage, edge functions) under one entry. |
| `NSExceptionRequiresForwardSecrecy` | `true` | Enforces ephemeral Diffie-Hellman key exchange. Even if the server's long-term private key is compromised later, past session data cannot be decrypted. |
| `NSExceptionMinimumTLSVersion` | `TLSv1.3` | Same TLS requirement applies to the exception domain — no downgrade. |

---

## External Links Policy

Cooksy does **not** use in-app web views for third-party content.

| Content Type | Handler | ATS Impact |
|-------------|---------|------------|
| YouTube recipe source | `UIApplication.shared.open()` → Safari | No ATS exception needed |
| TikTok recipe source | `UIApplication.shared.open()` → Safari | No ATS exception needed |
| Instagram recipe source | `UIApplication.shared.open()` → Safari | No ATS exception needed |
| Recipe images | Supabase Storage (HTTPS) | Covered by Supabase exception |
| Auth/ API calls | Supabase API (HTTPS) | Covered by Supabase exception |

---

## Verification

After adding to `Info.plist`, verify the configuration:

1. **Build-time check:** The app should compile without ATS warnings.
2. **Runtime check:** Monitor `URLSession` delegate for ATS blocking errors.
3. **Network debugging:** Use Instruments with Network template — all Cooksy traffic
   should appear as TLS 1.3 connections to `*.supabase.co`.

## Compliance Note

This ATS configuration satisfies Apple's App Store Review Guidelines Section 5.6
(Network Security). The single exception domain is justified as it is the app's
legitimate backend API provider (Supabase). No broad exceptions are granted.
