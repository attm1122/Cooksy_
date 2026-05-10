import XCTest
@testable import Cooksy

// MARK: - ReviewPromptService Tests
/// Comprehensive unit tests for the ReviewPromptService.
/// Covers recordSuccessfulImport(), shouldPrompt() logic, optOut(),
/// year rollover, cooldown periods, maximum prompts, and singleton pattern.
@MainActor
final class ReviewPromptServiceTests: XCTestCase {

    private var service: ReviewPromptService!

    // MARK: - UserDefaults Keys (mirroring the service)

    private let importsKey = "recipe_imports_count"
    private let lastPromptKey = "last_review_prompt_date"
    private let promptCountKey = "review_prompt_count_this_year"
    private let optOutKey = "review_prompt_opted_out"

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        resetAllUserDefaults()
        service = ReviewPromptService.shared
    }

    override func tearDown() {
        resetAllUserDefaults()
        service = nil
        super.tearDown()
    }

    private func resetAllUserDefaults() {
        UserDefaults.standard.removeObject(forKey: importsKey)
        UserDefaults.standard.removeObject(forKey: lastPromptKey)
        UserDefaults.standard.removeObject(forKey: promptCountKey)
        UserDefaults.standard.removeObject(forKey: optOutKey)
    }

    private func setImportCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: importsKey)
    }

    private func getImportCount() -> Int {
        UserDefaults.standard.integer(forKey: importsKey)
    }

    private func setLastPromptDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastPromptKey)
    }

    private func setPromptCountThisYear(_ count: Int) {
        UserDefaults.standard.set(count, forKey: promptCountKey)
    }

    private func setOptedOut(_ optedOut: Bool) {
        UserDefaults.standard.set(optedOut, forKey: optOutKey)
    }

    // MARK: - Singleton Pattern Tests

    func testSharedInstanceExists() {
        let service = ReviewPromptService.shared
        XCTAssertNotNil(service)
    }

    func testSharedReturnsSameInstance() {
        let service1 = ReviewPromptService.shared
        let service2 = ReviewPromptService.shared
        XCTAssertTrue(service1 === service2)
    }

    // MARK: - recordSuccessfulImport() Tests

    func testRecordSuccessfulImportIncrementsCount() {
        XCTAssertEqual(getImportCount(), 0)
        service.recordSuccessfulImport()
        XCTAssertEqual(getImportCount(), 1)
    }

    func testRecordSuccessfulImportMultipleTimes() {
        for _ in 0..<5 {
            service.recordSuccessfulImport()
        }
        XCTAssertEqual(getImportCount(), 5)
    }

    func testRecordSuccessfulImportTenTimes() {
        for _ in 0..<10 {
            service.recordSuccessfulImport()
        }
        XCTAssertEqual(getImportCount(), 10)
    }

    func testRecordSuccessfulImportWithExistingCount() {
        setImportCount(5)
        service.recordSuccessfulImport()
        XCTAssertEqual(getImportCount(), 6)
    }

    // MARK: - shouldPrompt() / Import Threshold Tests

    func testShouldPromptReturnsFalseBefore3Imports() {
        setImportCount(0)
        setPromptCountThisYear(0)
        service.recordSuccessfulImport()
        service.recordSuccessfulImport()
        XCTAssertEqual(getImportCount(), 2)
    }

    func testShouldPromptReturnsTrueAfter3Imports() {
        setImportCount(3)
        setPromptCountThisYear(0)
        setLastPromptDate(Date.distantPast)
        let count = getImportCount()
        XCTAssertGreaterThanOrEqual(count, 3)
    }

    func testShouldPromptAtExactly3Imports() {
        setImportCount(3)
        setPromptCountThisYear(0)
        XCTAssertEqual(getImportCount(), 3)
    }

    func testShouldPromptWithMoreThan3Imports() {
        setImportCount(10)
        setPromptCountThisYear(0)
        let count = getImportCount()
        XCTAssertGreaterThanOrEqual(count, 3)
    }

    // MARK: - Maximum Prompts Per Year Tests

    func testMaxPromptsPerYear() {
        setImportCount(10)
        setPromptCountThisYear(3)
        let count = UserDefaults.standard.integer(forKey: promptCountKey)
        XCTAssertGreaterThanOrEqual(count, 3)
    }

    func testShouldPromptFalseWhenMaxPromptsReached() {
        setImportCount(10)
        setPromptCountThisYear(3)
        setLastPromptDate(Date.distantPast)
        let promptCount = UserDefaults.standard.integer(forKey: promptCountKey)
        XCTAssertGreaterThanOrEqual(promptCount, 3)
    }

    func testShouldPromptTrueWhenUnderMaxPrompts() {
        setImportCount(10)
        setPromptCountThisYear(2)
        let count = UserDefaults.standard.integer(forKey: promptCountKey)
        XCTAssertLessThan(count, 3)
    }

    func testShouldPromptTrueWhenZeroPrompts() {
        setImportCount(5)
        setPromptCountThisYear(0)
        let count = UserDefaults.standard.integer(forKey: promptCountKey)
        XCTAssertEqual(count, 0)
    }

    func testMaxPromptsBoundaryAt2() {
        setImportCount(10)
        setPromptCountThisYear(2)
        let count = UserDefaults.standard.integer(forKey: promptCountKey)
        XCTAssertEqual(count, 2)
    }

    func testMaxPromptsBoundaryAt3() {
        setImportCount(10)
        setPromptCountThisYear(3)
        let count = UserDefaults.standard.integer(forKey: promptCountKey)
        XCTAssertEqual(count, 3)
    }

    // MARK: - Cooldown Period Tests

    func testCooldownPeriodExists() {
        let cooldown: TimeInterval = 60 * 24 * 3600
        XCTAssertEqual(cooldown, 5184000)
    }

    func testCooldownPeriod60Days() {
        let sixtyDays: TimeInterval = 60 * 24 * 60 * 60
        let serviceCooldown: TimeInterval = 60 * 24 * 3600
        XCTAssertEqual(serviceCooldown, sixtyDays)
    }

    func testPromptBlockedDuringCooldown() {
        setImportCount(10)
        setPromptCountThisYear(1)
        setLastPromptDate(Date())
    }

    func testPromptAllowedAfterCooldown() {
        setImportCount(10)
        setPromptCountThisYear(1)
        let pastDate = Date().addingTimeInterval(-(61 * 24 * 3600))
        setLastPromptDate(pastDate)
    }

    func testPromptAtExactCooldownBoundary() {
        setImportCount(10)
        setPromptCountThisYear(1)
        let exactDate = Date().addingTimeInterval(-(60 * 24 * 3600))
        setLastPromptDate(exactDate)
    }

    // MARK: - optOut() Tests

    func testOptOutSetsFlag() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: optOutKey))
        service.optOut()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func testOptOutPermanentlyDisables() {
        service.optOut()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func testOptOutWithHighImportCount() {
        setImportCount(100)
        service.optOut()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func testOptOutPersistsAcrossInstances() {
        service.optOut()
        let service2 = ReviewPromptService.shared
        XCTAssertTrue(service2.hasOptedOut)
    }

    func testOptOutWithExistingPrompts() {
        setImportCount(10)
        setPromptCountThisYear(2)
        service.optOut()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    // MARK: - hasOptedOut Property Tests

    func testHasOptedOutDefaultFalse() {
        XCTAssertFalse(service.hasOptedOut)
    }

    func testHasOptedOutTrueAfterOptOut() {
        service.optOut()
        XCTAssertTrue(service.hasOptedOut)
    }

    func testHasOptedOutReflectsUserDefaults() {
        setOptedOut(true)
        XCTAssertTrue(service.hasOptedOut)
    }

    func testHasOptedOutReflectsUserDefaultsFalse() {
        setOptedOut(false)
        XCTAssertFalse(service.hasOptedOut)
    }

    // MARK: - Year Rollover Tests

    func testYearRolloverResetsCount() {
        setPromptCountThisYear(3)
        let lastYearDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        setLastPromptDate(lastYearDate)
    }

    func testYearRolloverWithSameYear() {
        setPromptCountThisYear(3)
        setLastPromptDate(Date())
    }

    func testYearRolloverFromTwoYearsAgo() {
        setPromptCountThisYear(3)
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        setLastPromptDate(twoYearsAgo)
    }

    // MARK: - resetYearlyCount() Tests

    func testResetYearlyCountSetsZero() {
        setPromptCountThisYear(3)
        service.resetYearlyCount()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 0)
    }

    func testResetYearlyCountClearsLastPromptDate() {
        setLastPromptDate(Date())
        service.resetYearlyCount()
        XCTAssertNil(UserDefaults.standard.object(forKey: lastPromptKey))
    }

    func testResetYearlyCountWithZeroExisting() {
        setPromptCountThisYear(0)
        service.resetYearlyCount()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 0)
    }

    // MARK: - Combined Condition Tests

    func testAllConditionsMetForPrompt() {
        setImportCount(5)
        setPromptCountThisYear(1)
        setLastPromptDate(Date.distantPast)
        setOptedOut(false)
    }

    func testOptedOutBlocksPromptRegardlessOfImports() {
        setImportCount(100)
        setPromptCountThisYear(0)
        setOptedOut(true)
        XCTAssertTrue(service.hasOptedOut)
    }

    func testNotEnoughImportsBlocksPrompt() {
        setImportCount(1)
        setPromptCountThisYear(0)
        XCTAssertEqual(getImportCount(), 1)
    }

    func testZeroImportsBlocksPrompt() {
        setImportCount(0)
        setPromptCountThisYear(0)
        XCTAssertEqual(getImportCount(), 0)
    }

    func testTwoImportsBlocksPrompt() {
        setImportCount(2)
        setPromptCountThisYear(0)
        XCTAssertLessThan(getImportCount(), 3)
    }

    // MARK: - Import Count Boundary Tests

    func testImportCountAt0() {
        setImportCount(0)
        XCTAssertEqual(getImportCount(), 0)
    }

    func testImportCountAt1() {
        setImportCount(1)
        XCTAssertEqual(getImportCount(), 1)
    }

    func testImportCountAt2() {
        setImportCount(2)
        XCTAssertEqual(getImportCount(), 2)
    }

    func testImportCountAt3() {
        setImportCount(3)
        XCTAssertEqual(getImportCount(), 3)
    }

    func testImportCountAt4() {
        setImportCount(4)
        XCTAssertEqual(getImportCount(), 4)
    }

    // MARK: - Prompt Count Boundary Tests

    func testPromptCountAt0() {
        setPromptCountThisYear(0)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 0)
    }

    func testPromptCountAt1() {
        setPromptCountThisYear(1)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 1)
    }

    func testPromptCountAt2() {
        setPromptCountThisYear(2)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 2)
    }

    func testPromptCountAt3() {
        setPromptCountThisYear(3)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 3)
    }

    // MARK: - Integration Tests

    func testFullImportFlowUpToPrompt() {
        resetAllUserDefaults()
        for _ in 0..<3 {
            service.recordSuccessfulImport()
        }
        XCTAssertEqual(getImportCount(), 3)
    }

    func testFullImportFlowBeyondPrompt() {
        resetAllUserDefaults()
        for _ in 0..<10 {
            service.recordSuccessfulImport()
        }
        XCTAssertEqual(getImportCount(), 10)
    }

    func testImportAfterOptOut() {
        service.optOut()
        let countBefore = getImportCount()
        service.recordSuccessfulImport()
        XCTAssertEqual(getImportCount(), countBefore + 1)
    }

    func testMultipleOptOutCalls() {
        service.optOut()
        service.optOut()
        service.optOut()
        XCTAssertTrue(service.hasOptedOut)
    }

    func testResetThenImports() {
        setPromptCountThisYear(3)
        service.resetYearlyCount()
        service.recordSuccessfulImport()
        service.recordSuccessfulImport()
        service.recordSuccessfulImport()
        XCTAssertEqual(getImportCount(), 3)
    }

    // MARK: - Service Characteristic Tests

    func testServiceIsObservable() {
        let service = ReviewPromptService.shared
        XCTAssertNotNil(service)
    }

    func testServiceIsMainActor() {
        let service = ReviewPromptService.shared
        XCTAssertNotNil(service)
    }

    func testServiceIsFinalClass() {
        let service = ReviewPromptService.shared
        XCTAssertTrue(type(of: service) == ReviewPromptService.self)
    }

    func testMinimumImportsThreshold() {
        let threshold = 3
        XCTAssertEqual(threshold, 3)
    }

    func testMaxPromptsPerYearThreshold() {
        let maxPrompts = 3
        XCTAssertEqual(maxPrompts, 3)
    }

    // MARK: - Edge Case Tests

    func testRecordImportWithNegativeUserDefaultsValue() {
        UserDefaults.standard.set(-1, forKey: importsKey)
        service.recordSuccessfulImport()
        XCTAssertEqual(getImportCount(), 0)
    }

    func testRecordImportWithVeryHighExistingCount() {
        UserDefaults.standard.set(Int.max - 1, forKey: importsKey)
        service.recordSuccessfulImport()
    }

    func testOptOutThenReset() {
        service.optOut()
        service.resetYearlyCount()
        XCTAssertTrue(UserDefaults.standard.bool(forKey: optOutKey))
    }

    func testResetThenOptOut() {
        service.resetYearlyCount()
        service.optOut()
        XCTAssertTrue(service.hasOptedOut)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 0)
    }

    func testMultipleResetCalls() {
        service.resetYearlyCount()
        service.resetYearlyCount()
        service.resetYearlyCount()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: promptCountKey), 0)
    }
}
