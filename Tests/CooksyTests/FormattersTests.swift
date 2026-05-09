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
}
