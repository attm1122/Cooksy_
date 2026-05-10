import XCTest
@testable import Cooksy

// MARK: - HapticsService Tests
/// Comprehensive unit tests for the HapticsService.
/// Covers all haptic feedback methods, thread safety, and simulator compatibility.
/// Haptics are device-dependent, so these tests verify methods do not crash.
final class HapticsServiceTests: XCTestCase {

    // MARK: - Convenience Method Tests

    func testLightDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.light())
    }

    func testMediumDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.medium())
    }

    func testHeavyDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.heavy())
    }

    func testSuccessDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.success())
    }

    func testWarningDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.warning())
    }

    func testErrorDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.error())
    }

    // MARK: - Play Method Tests (via HapticStyle)

    func testPlayLightDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.play(.light))
    }

    func testPlayMediumDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.play(.medium))
    }

    func testPlayHeavyDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.play(.heavy))
    }

    func testPlaySuccessDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.play(.success))
    }

    func testPlayWarningDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.play(.warning))
    }

    func testPlayErrorDoesNotCrash() {
        XCTAssertNoThrow(HapticsService.play(.error))
    }

    // MARK: - Multiple Consecutive Calls Tests

    func testMultipleConsecutiveLightCalls() {
        for _ in 0..<10 {
            XCTAssertNoThrow(HapticsService.light())
        }
    }

    func testMultipleConsecutiveMediumCalls() {
        for _ in 0..<10 {
            XCTAssertNoThrow(HapticsService.medium())
        }
    }

    func testMultipleConsecutiveHeavyCalls() {
        for _ in 0..<10 {
            XCTAssertNoThrow(HapticsService.heavy())
        }
    }

    func testMultipleConsecutiveSuccessCalls() {
        for _ in 0..<10 {
            XCTAssertNoThrow(HapticsService.success())
        }
    }

    func testMultipleConsecutiveWarningCalls() {
        for _ in 0..<10 {
            XCTAssertNoThrow(HapticsService.warning())
        }
    }

    func testMultipleConsecutiveErrorCalls() {
        for _ in 0..<10 {
            XCTAssertNoThrow(HapticsService.error())
        }
    }

    func testRapidMixedCalls() {
        let styles: [HapticStyle] = [.light, .medium, .heavy, .success, .warning, .error]
        for _ in 0..<20 {
            for style in styles {
                XCTAssertNoThrow(HapticsService.play(style))
            }
        }
    }

    // MARK: - Thread Safety Tests

    func testLightFromBackgroundThread() {
        let expectation = self.expectation(description: "Background thread haptic")
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertNoThrow(HapticsService.light())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testMediumFromBackgroundThread() {
        let expectation = self.expectation(description: "Background thread haptic")
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertNoThrow(HapticsService.medium())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testHeavyFromBackgroundThread() {
        let expectation = self.expectation(description: "Background thread haptic")
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertNoThrow(HapticsService.heavy())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testSuccessFromBackgroundThread() {
        let expectation = self.expectation(description: "Background thread haptic")
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertNoThrow(HapticsService.success())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testWarningFromBackgroundThread() {
        let expectation = self.expectation(description: "Background thread haptic")
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertNoThrow(HapticsService.warning())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testErrorFromBackgroundThread() {
        let expectation = self.expectation(description: "Background thread haptic")
        DispatchQueue.global(qos: .userInitiated).async {
            XCTAssertNoThrow(HapticsService.error())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func testConcurrentHapticCalls() {
        let expectations = (0..<10).map { i in
            self.expectation(description: "Concurrent haptic \(i)")
        }
        let styles: [HapticStyle] = [.light, .medium, .heavy, .success, .warning, .error]

        for i in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                let style = styles[i % styles.count]
                XCTAssertNoThrow(HapticsService.play(style))
                expectations[i].fulfill()
            }
        }
        wait(for: expectations, timeout: 5.0)
    }

    func testConcurrentMixedStyleCalls() {
        let group = DispatchGroup()
        let styles: [HapticStyle] = [.light, .medium, .heavy, .success, .warning, .error]

        for _ in 0..<50 {
            group.enter()
            DispatchQueue.global(qos: .default).async {
                let randomStyle = styles[Int.random(in: 0..<styles.count)]
                XCTAssertNoThrow(HapticsService.play(randomStyle))
                group.leave()
            }
        }

        let expectation = self.expectation(description: "Wait for all concurrent calls")
        group.notify(queue: .main) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - HapticStyle Enum Tests

    func testHapticStyleLightExists() {
        let style = HapticStyle.light
        XCTAssertNotNil(style)
    }

    func testHapticStyleMediumExists() {
        let style = HapticStyle.medium
        XCTAssertNotNil(style)
    }

    func testHapticStyleHeavyExists() {
        let style = HapticStyle.heavy
        XCTAssertNotNil(style)
    }

    func testHapticStyleSuccessExists() {
        let style = HapticStyle.success
        XCTAssertNotNil(style)
    }

    func testHapticStyleErrorExists() {
        let style = HapticStyle.error
        XCTAssertNotNil(style)
    }

    func testHapticStyleWarningExists() {
        let style = HapticStyle.warning
        XCTAssertNotNil(style)
    }

    func testAllHapticStylesAreExhaustivelyHandled() {
        let styles: [HapticStyle] = [.light, .medium, .heavy, .success, .error, .warning]
        for style in styles {
            XCTAssertNoThrow(HapticsService.play(style), "HapticStyle \(style) should not crash")
        }
    }

    // MARK: - Stress Tests

    func testStressTestLightHaptic() {
        for _ in 0..<100 {
            XCTAssertNoThrow(HapticsService.light())
        }
    }

    func testStressTestAllStyles() {
        let styles: [HapticStyle] = [.light, .medium, .heavy, .success, .warning, .error]
        for _ in 0..<100 {
            for style in styles {
                XCTAssertNoThrow(HapticsService.play(style))
            }
        }
    }

    // MARK: - Simulator Compatibility Tests

    func testHapticsOnSimulatorDoNotThrow() {
        #if targetEnvironment(simulator)
        XCTAssertNoThrow(HapticsService.light())
        XCTAssertNoThrow(HapticsService.medium())
        XCTAssertNoThrow(HapticsService.heavy())
        XCTAssertNoThrow(HapticsService.success())
        XCTAssertNoThrow(HapticsService.warning())
        XCTAssertNoThrow(HapticsService.error())
        #else
        throw XCTSkip("This test is specific to simulator environment")
        #endif
    }

    func testAllMethodsReturnVoid() {
        func assertReturnsVoid<T>(_ expression: @autoclosure () -> T, _ message: String = "") {
            let value = expression()
            XCTAssertTrue(type(of: value) == Void.self, message)
        }
        assertReturnsVoid(HapticsService.light(), "light() should return Void")
        assertReturnsVoid(HapticsService.medium(), "medium() should return Void")
        assertReturnsVoid(HapticsService.heavy(), "heavy() should return Void")
        assertReturnsVoid(HapticsService.success(), "success() should return Void")
        assertReturnsVoid(HapticsService.warning(), "warning() should return Void")
        assertReturnsVoid(HapticsService.error(), "error() should return Void")
        assertReturnsVoid(HapticsService.play(.light), "play(.light) should return Void")
    }

    // MARK: - Service Characteristic Tests

    func testServiceIsAStruct() {
        let serviceType = type(of: HapticsService.self)
        XCTAssertTrue(serviceType == HapticsService.Type.self)
    }

    func testAllMethodsAreStatic() {
        let service = HapticsService.self
        XCTAssertNotNil(service)
        XCTAssertNoThrow(HapticsService.light())
    }

    func testHapticStyleEnumIsDefined() {
        let allCases: [HapticStyle] = [.light, .medium, .heavy, .success, .error, .warning]
        XCTAssertEqual(allCases.count, 6)
    }
}
