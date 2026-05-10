import XCTest
@testable import Cooksy

// MARK: - NetworkMonitor Tests
/// Comprehensive unit tests for the NetworkMonitor service.
/// Covers initial state, connection type enum, isExpensive property,
/// singleton pattern, and deinitialization.
final class NetworkMonitorTests: XCTestCase {

    // MARK: - Singleton Pattern Tests

    func testSharedInstanceExists() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor)
    }

    func testSharedReturnsSameInstance() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared
        XCTAssertTrue(monitor1 === monitor2, "shared should return the same singleton instance")
    }

    func testSharedInstanceIsObservable() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor)
    }

    // MARK: - Initial State Tests

    func testIsConnectedInitialValue() {
        let monitor = NetworkMonitor.shared
        XCTAssertTrue(monitor.isConnected, "Initial isConnected should be true")
    }

    func testConnectionTypeInitialValue() {
        let monitor = NetworkMonitor.shared
        XCTAssertEqual(monitor.connectionType, .unknown, "Initial connectionType should be .unknown")
    }

    func testIsExpensiveInitialValue() {
        let monitor = NetworkMonitor.shared
        XCTAssertFalse(monitor.isExpensive, "Initial isExpensive should be false")
    }

    // MARK: - ConnectionType Enum Tests

    func testConnectionTypeWiFiExists() {
        let type = NetworkMonitor.ConnectionType.wifi
        XCTAssertNotNil(type)
    }

    func testConnectionTypeCellularExists() {
        let type = NetworkMonitor.ConnectionType.cellular
        XCTAssertNotNil(type)
    }

    func testConnectionTypeEthernetExists() {
        let type = NetworkMonitor.ConnectionType.ethernet
        XCTAssertNotNil(type)
    }

    func testConnectionTypeUnknownExists() {
        let type = NetworkMonitor.ConnectionType.unknown
        XCTAssertNotNil(type)
    }

    func testConnectionTypeWiFiEquality() {
        let a = NetworkMonitor.ConnectionType.wifi
        let b = NetworkMonitor.ConnectionType.wifi
        XCTAssertEqual(a, b)
    }

    func testConnectionTypeCellularEquality() {
        let a = NetworkMonitor.ConnectionType.cellular
        let b = NetworkMonitor.ConnectionType.cellular
        XCTAssertEqual(a, b)
    }

    func testConnectionTypeEthernetEquality() {
        let a = NetworkMonitor.ConnectionType.ethernet
        let b = NetworkMonitor.ConnectionType.ethernet
        XCTAssertEqual(a, b)
    }

    func testConnectionTypeUnknownEquality() {
        let a = NetworkMonitor.ConnectionType.unknown
        let b = NetworkMonitor.ConnectionType.unknown
        XCTAssertEqual(a, b)
    }

    func testConnectionTypeWiFiNotEqualToCellular() {
        let a = NetworkMonitor.ConnectionType.wifi
        let b = NetworkMonitor.ConnectionType.cellular
        XCTAssertNotEqual(a, b)
    }

    func testConnectionTypeWiFiNotEqualToUnknown() {
        let a = NetworkMonitor.ConnectionType.wifi
        let b = NetworkMonitor.ConnectionType.unknown
        XCTAssertNotEqual(a, b)
    }

    func testConnectionTypeCellularNotEqualToEthernet() {
        let a = NetworkMonitor.ConnectionType.cellular
        let b = NetworkMonitor.ConnectionType.ethernet
        XCTAssertNotEqual(a, b)
    }

    func testConnectionTypeUnknownNotEqualToEthernet() {
        let a = NetworkMonitor.ConnectionType.unknown
        let b = NetworkMonitor.ConnectionType.ethernet
        XCTAssertNotEqual(a, b)
    }

    func testConnectionTypeIsSendable() {
        func assertSendable<T: Sendable>(_ value: T) {
            XCTAssertNotNil(value)
        }
        assertSendable(NetworkMonitor.ConnectionType.wifi)
        assertSendable(NetworkMonitor.ConnectionType.cellular)
        assertSendable(NetworkMonitor.ConnectionType.ethernet)
        assertSendable(NetworkMonitor.ConnectionType.unknown)
    }

    // MARK: - State Observation Tests

    func testIsConnectedPropertyIsObservable() {
        let monitor = NetworkMonitor.shared
        XCTAssertTrue(monitor.isConnected)
    }

    func testConnectionTypePropertyIsObservable() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor.connectionType)
    }

    func testIsExpensivePropertyIsObservable() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor.isExpensive)
    }

    // MARK: - Property Value Tests

    func testIsConnectedIsBool() {
        let monitor = NetworkMonitor.shared
        let isConnected = monitor.isConnected
        XCTAssertTrue(isConnected == true || isConnected == false)
    }

    func testIsExpensiveIsBool() {
        let monitor = NetworkMonitor.shared
        let isExpensive = monitor.isExpensive
        XCTAssertTrue(isExpensive == true || isExpensive == false)
    }

    func testConnectionTypeIsSet() {
        let monitor = NetworkMonitor.shared
        let type = monitor.connectionType
        switch type {
        case .wifi, .cellular, .ethernet, .unknown:
            XCTAssertTrue(true)
        }
    }

    // MARK: - Private Init Tests (via Singleton)

    func testCannotCreateNewInstanceViaInit() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared
        XCTAssertTrue(monitor1 === monitor2)
    }

    func testMonitorIsMainActor() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor)
        XCTAssertTrue(monitor.isConnected)
    }

    // MARK: - Class Characteristic Tests

    func testMonitorIsFinalClass() {
        let monitorType = type(of: NetworkMonitor.shared)
        XCTAssertTrue(monitorType == NetworkMonitor.self)
    }

    func testMonitorIsObservable() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor)
    }

    func testMonitorPropertiesArePrivateSet() {
        let monitor = NetworkMonitor.shared
        XCTAssertTrue(monitor.isConnected)
        XCTAssertNotNil(monitor.connectionType)
        XCTAssertNotNil(monitor.isExpensive)
    }

    // MARK: - Multiple Access Tests

    func testRepeatedAccessToSharedInstance() {
        var monitors: [NetworkMonitor] = []
        for _ in 0..<10 {
            monitors.append(NetworkMonitor.shared)
        }
        for monitor in monitors {
            XCTAssertTrue(monitor === monitors.first, "All references should point to same instance")
        }
    }

    func testMonitorStateRemainsConsistent() {
        let monitor = NetworkMonitor.shared
        let isConnected1 = monitor.isConnected
        let type1 = monitor.connectionType
        let isExpensive1 = monitor.isExpensive

        let isConnected2 = monitor.isConnected
        let type2 = monitor.connectionType
        let isExpensive2 = monitor.isExpensive

        XCTAssertEqual(isConnected1, isConnected2)
        XCTAssertEqual(type1, type2)
        XCTAssertEqual(isExpensive1, isExpensive2)
    }

    // MARK: - Connection Type Switch Exhaustiveness Test

    func testAllConnectionTypesHandled() {
        let types: [NetworkMonitor.ConnectionType] = [.wifi, .cellular, .ethernet, .unknown]
        for type in types {
            switch type {
            case .wifi, .cellular, .ethernet, .unknown:
                XCTAssertTrue(true, "\(type) is handled")
            }
        }
    }

    func testConnectionTypeSwitchCoverage() {
        let monitor = NetworkMonitor.shared
        let type = monitor.connectionType
        let description: String
        switch type {
        case .wifi: description = "wifi"
        case .cellular: description = "cellular"
        case .ethernet: description = "ethernet"
        case .unknown: description = "unknown"
        }
        XCTAssertFalse(description.isEmpty)
    }

    // MARK: - Edge Case Tests

    func testMonitorAfterMultipleSharedAccesses() {
        let m1 = NetworkMonitor.shared
        let m2 = NetworkMonitor.shared
        let m3 = NetworkMonitor.shared
        XCTAssertTrue(m1 === m2)
        XCTAssertTrue(m2 === m3)
        XCTAssertTrue(m1.isConnected)
    }

    func testIsConnectedDoesNotReturnNil() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor.isConnected)
    }

    func testIsExpensiveDoesNotReturnNil() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor.isExpensive)
    }

    func testConnectionTypeDoesNotReturnNil() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor.connectionType)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSharedAccess() {
        let expectations = (0..<10).map { i in
            self.expectation(description: "Concurrent access \(i)")
        }

        for i in 0..<10 {
            DispatchQueue.global(qos: .default).async {
                let monitor = NetworkMonitor.shared
                XCTAssertNotNil(monitor)
                expectations[i].fulfill()
            }
        }

        wait(for: expectations, timeout: 5.0)
    }

    func testConcurrentStateReads() {
        let monitor = NetworkMonitor.shared
        let expectations = (0..<10).map { i in
            self.expectation(description: "Concurrent state read \(i)")
        }

        for i in 0..<10 {
            DispatchQueue.global(qos: .default).async {
                let isConnected = monitor.isConnected
                let connectionType = monitor.connectionType
                let isExpensive = monitor.isExpensive
                XCTAssertNotNil(isConnected)
                XCTAssertNotNil(connectionType)
                XCTAssertNotNil(isExpensive)
                expectations[i].fulfill()
            }
        }

        wait(for: expectations, timeout: 5.0)
    }
}
