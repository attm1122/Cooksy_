import XCTest
@testable import Cooksy

// MARK: - Formatters Tests
/// Comprehensive unit tests for the Formatters utility.
/// Covers time formatting, servings formatting, and confidence score formatting.
final class FormattersTests: XCTestCase {

    // MARK: - Time Formatting Tests

    func testFormatTime_ZeroMinutes() {
        XCTAssertEqual(Formatters.formatTime(0), "\u{2014}")
    }

    func testFormatTime_NegativeMinutes() {
        XCTAssertEqual(Formatters.formatTime(-5), "\u{2014}")
    }

    func testFormatTime_UnderOneHour() {
        XCTAssertEqual(Formatters.formatTime(5), "5 min")
        XCTAssertEqual(Formatters.formatTime(30), "30 min")
        XCTAssertEqual(Formatters.formatTime(59), "59 min")
        XCTAssertEqual(Formatters.formatTime(1), "1 min")
    }

    func testFormatTime_ExactlyOneHour() {
        XCTAssertEqual(Formatters.formatTime(60), "1 hr")
    }

    func testFormatTime_MultipleHoursExact() {
        XCTAssertEqual(Formatters.formatTime(120), "2 hrs")
        XCTAssertEqual(Formatters.formatTime(180), "3 hrs")
    }

    func testFormatTime_HoursAndMinutes() {
        XCTAssertEqual(Formatters.formatTime(90), "1 hr 30 min")
        XCTAssertEqual(Formatters.formatTime(75), "1 hr 15 min")
        XCTAssertEqual(Formatters.formatTime(150), "2 hr 30 min")
        XCTAssertEqual(Formatters.formatTime(61), "1 hr 1 min")
    }

    func testFormatTime_LargeValues() {
        XCTAssertEqual(Formatters.formatTime(1440), "24 hrs")     // 24 hours
        XCTAssertEqual(Formatters.formatTime(1505), "25 hr 5 min") // 25 hours 5 min
    }

    // MARK: - Servings Formatting Tests

    func testFormatServings_Singular() {
        XCTAssertEqual(Formatters.formatServings(1), "1 serving")
    }

    func testFormatServings_Plural() {
        XCTAssertEqual(Formatters.formatServings(2), "2 servings")
        XCTAssertEqual(Formatters.formatServings(4), "4 servings")
        XCTAssertEqual(Formatters.formatServings(10), "10 servings")
        XCTAssertEqual(Formatters.formatServings(100), "100 servings")
    }

    func testFormatServings_Zero() {
        XCTAssertEqual(Formatters.formatServings(0), "0 servings")
    }

    // MARK: - Confidence Formatting Tests

    func testFormatConfidence_PerfectScore() {
        XCTAssertEqual(Formatters.formatConfidence(100), "100/100")
    }

    func testFormatConfidence_HighScore() {
        XCTAssertEqual(Formatters.formatConfidence(92), "92/100")
    }

    func testFormatConfidence_MediumScore() {
        XCTAssertEqual(Formatters.formatConfidence(50), "50/100")
    }

    func testFormatConfidence_ZeroScore() {
        XCTAssertEqual(Formatters.formatConfidence(0), "0/100")
    }

    // MARK: - Relative Date Tests

    func testRelativeDate_Recent() {
        let recentDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let result = Formatters.relativeDate(recentDate)
        // Result should contain time-related text
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, "\u{2014}")
    }

    func testRelativeDate_Future() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let result = Formatters.relativeDate(futureDate)
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Short Date Tests

    func testShortDate_Format() {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15

        let date = Calendar.current.date(from: components)!
        let result = Formatters.shortDate(date)

        // Should contain month name and day
        XCTAssertTrue(result.contains("15"))
        XCTAssertTrue(result.contains("2025"))
    }

    // MARK: - Consistency Tests

    func testTimeFormattingConsistency() {
        // Same input should always produce same output
        for minutes in [0, 5, 30, 60, 90, 120, 150] {
            let first = Formatters.formatTime(minutes)
            let second = Formatters.formatTime(minutes)
            XCTAssertEqual(first, second, "Time formatting should be deterministic")
        }
    }

    func testServingsFormattingConsistency() {
        for servings in [0, 1, 2, 4, 8, 12] {
            let first = Formatters.formatServings(servings)
            let second = Formatters.formatServings(servings)
            XCTAssertEqual(first, second, "Servings formatting should be deterministic")
        }
    }

    // MARK: - Extended Time Formatting Edge Cases

    func testFormatTime_NegativeInput_ReturnsDash() {
        XCTAssertEqual(Formatters.formatTime(-1), "\u{2014}")
        XCTAssertEqual(Formatters.formatTime(-60), "\u{2014}")
        XCTAssertEqual(Formatters.formatTime(-1440), "\u{2014}")
        XCTAssertEqual(Formatters.formatTime(-10000), "\u{2014}")
    }

    func testFormatTime_VeryLargeValue_24Hours() {
        XCTAssertEqual(Formatters.formatTime(1440), "24 hrs")
    }

    func testFormatTime_ExactHourBoundaries() {
        XCTAssertEqual(Formatters.formatTime(60), "1 hr")
        XCTAssertEqual(Formatters.formatTime(120), "2 hrs")
        XCTAssertEqual(Formatters.formatTime(180), "3 hrs")
        XCTAssertEqual(Formatters.formatTime(240), "4 hrs")
        XCTAssertEqual(Formatters.formatTime(300), "5 hrs")
    }

    func testFormatTime_OneMinute() {
        XCTAssertEqual(Formatters.formatTime(1), "1 min")
    }

    func testFormatTime_59Minutes() {
        XCTAssertEqual(Formatters.formatTime(59), "59 min")
    }

    func testFormatTime_61Minutes() {
        XCTAssertEqual(Formatters.formatTime(61), "1 hr 1 min")
    }

    func testFormatTime_119Minutes() {
        XCTAssertEqual(Formatters.formatTime(119), "1 hr 59 min")
    }

    func testFormatTime_121Minutes() {
        XCTAssertEqual(Formatters.formatTime(121), "2 hr 1 min")
    }

    func testFormatTime_1000Minutes() {
        XCTAssertEqual(Formatters.formatTime(1000), "16 hr 40 min")
    }

    func testFormatTime_10000Minutes() {
        XCTAssertEqual(Formatters.formatTime(10000), "166 hr 40 min")
    }

    // MARK: - Extended Servings Edge Cases

    func testFormatServings_ZeroServings() {
        XCTAssertEqual(Formatters.formatServings(0), "0 servings")
    }

    func testFormatServings_OneServing() {
        XCTAssertEqual(Formatters.formatServings(1), "1 serving")
    }

    func testFormatServings_TwoServings() {
        XCTAssertEqual(Formatters.formatServings(2), "2 servings")
    }

    func testFormatServings_100Servings() {
        XCTAssertEqual(Formatters.formatServings(100), "100 servings")
    }

    func testFormatServings_1000Servings() {
        XCTAssertEqual(Formatters.formatServings(1000), "1000 servings")
    }

    func testFormatServings_NegativeServings() {
        XCTAssertEqual(Formatters.formatServings(-1), "-1 servings")
        XCTAssertEqual(Formatters.formatServings(-5), "-5 servings")
    }

    func testFormatServings_LargeNumber() {
        XCTAssertEqual(Formatters.formatServings(999999), "999999 servings")
    }

    // MARK: - Extended Confidence Score Edge Cases

    func testFormatConfidence_Zero() {
        XCTAssertEqual(Formatters.formatConfidence(0), "0/100")
    }

    func testFormatConfidence_50() {
        XCTAssertEqual(Formatters.formatConfidence(50), "50/100")
    }

    func testFormatConfidence_75() {
        XCTAssertEqual(Formatters.formatConfidence(75), "75/100")
    }

    func testFormatConfidence_90() {
        XCTAssertEqual(Formatters.formatConfidence(90), "90/100")
    }

    func testFormatConfidence_95() {
        XCTAssertEqual(Formatters.formatConfidence(95), "95/100")
    }

    func testFormatConfidence_100() {
        XCTAssertEqual(Formatters.formatConfidence(100), "100/100")
    }

    func testFormatConfidence_Negative() {
        XCTAssertEqual(Formatters.formatConfidence(-10), "-10/100")
    }

    func testFormatConfidence_Above100() {
        XCTAssertEqual(Formatters.formatConfidence(150), "150/100")
    }

    func testFormatConfidence_Boundary_99() {
        XCTAssertEqual(Formatters.formatConfidence(99), "99/100")
    }

    func testFormatConfidence_Boundary_1() {
        XCTAssertEqual(Formatters.formatConfidence(1), "1/100")
    }

    // MARK: - Confidence Formatting Determinism Tests

    func testFormatConfidence_IsDeterministic() {
        for score in [0, 1, 50, 75, 90, 95, 99, 100, -10, 150] {
            let first = Formatters.formatConfidence(score)
            let second = Formatters.formatConfidence(score)
            XCTAssertEqual(first, second, "Confidence formatting should be deterministic for score \(score)")
        }
    }

    // MARK: - Short Date Extended Tests

    func testShortDate_DifferentDates() {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 25

        let christmas = Calendar.current.date(from: components)!
        let result = Formatters.shortDate(christmas)

        XCTAssertTrue(result.contains("2024"), "Short date should include the year")
        XCTAssertTrue(result.contains("25"), "Short date should include the day")
    }

    func testShortDate_CurrentDate() {
        let now = Date()
        let result = Formatters.shortDate(now)
        XCTAssertFalse(result.isEmpty, "Short date for current date should not be empty")
    }

    func testShortDate_DoesNotIncludeTime() {
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.hour = 14
        components.minute = 30
        components.second = 45

        let date = Calendar.current.date(from: components)!
        let result = Formatters.shortDate(date)

        XCTAssertFalse(result.contains(":"), "Short date should not contain time separator")
    }

    // MARK: - Relative Date Extended Tests

    func testRelativeDate_Now() {
        let now = Date()
        let result = Formatters.relativeDate(now)
        XCTAssertFalse(result.isEmpty, "Relative date for 'now' should not be empty")
    }

    func testRelativeDate_Yesterday() {
        let yesterday = Date().addingTimeInterval(-86400)
        let result = Formatters.relativeDate(yesterday)
        XCTAssertFalse(result.isEmpty, "Relative date for yesterday should not be empty")
    }

    func testRelativeDate_IsDeterministic() {
        let date = Date().addingTimeInterval(-7200) // 2 hours ago
        let first = Formatters.relativeDate(date)
        let second = Formatters.relativeDate(date)
        XCTAssertEqual(first, second, "Relative date formatting should be deterministic for the same input")
    }

    // MARK: - All Public Functions Coverage

    func testAllFormatters_AreCallable() {
        let date = Date()
        _ = Formatters.formatTime(30)
        _ = Formatters.formatServings(4)
        _ = Formatters.formatConfidence(85)
        _ = Formatters.relativeDate(date)
        _ = Formatters.shortDate(date)
    }
}
