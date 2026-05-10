import Foundation
import Network

// MARK: - Network Monitor

/// Monitors network reachability and provides reactive state for UI.
///
/// Uses `NWPathMonitor` from the Network framework to track connectivity changes
/// in real-time. The `@Observable` macro makes this compatible with SwiftUI's
/// observation system, so views automatically update when connectivity changes.
///
/// ## Usage
/// ```swift
/// @State private var networkMonitor = NetworkMonitor.shared
///
/// if !networkMonitor.isConnected {
///     OfflineBanner()
/// }
/// ```
///
/// ## Thread Safety
/// All state updates are dispatched to `@MainActor` so they can safely drive UI.
@Observable
@MainActor
final class NetworkMonitor {
    /// The shared singleton instance. Use this for app-wide reachability monitoring.
    static let shared = NetworkMonitor()

    /// Whether the device currently has an active network connection.
    private(set) var isConnected = true

    /// The type of the active connection (wifi, cellular, ethernet, or unknown).
    private(set) var connectionType: ConnectionType = .unknown

    /// Whether the current connection is considered expensive (e.g., cellular roaming).
    /// Use this to decide whether to auto-play videos or download large assets.
    private(set) var isExpensive = false

    /// The possible types of network connections.
    enum ConnectionType: Sendable {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.cooksy.network", qos: .utility)

    /// Creates and starts the network monitor.
    /// Use `NetworkMonitor.shared` instead of instantiating directly.
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.update(path: path)
            }
        }
        monitor.start(queue: queue)
    }

    /// Updates the observable state from a new network path.
    private func update(path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive

        switch path.usesInterfaceType {
        case .wifi: connectionType = .wifi
        case .cellular: connectionType = .cellular
        case .wiredEthernet: connectionType = .ethernet
        default: connectionType = .unknown
        }

        // Announce connectivity changes to VoiceOver
        if wasConnected && !isConnected {
            announceToVoiceOver("No internet connection. Some features may be unavailable.")
        } else if !wasConnected && isConnected {
            announceToVoiceOver("Internet connection restored.")
        }
    }

    deinit {
        monitor.cancel()
    }
}
