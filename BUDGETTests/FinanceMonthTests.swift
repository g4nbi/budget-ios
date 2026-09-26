import XCTest
@testable import BUDGET

final class FinanceMonthTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }

    func testCalendarMonthStartingOnFirst() {
        let period = FinanceMonth.period(containing: date(2026, 3, 15), startDay: 1, calendar: calendar)
        XCTAssertEqual(calendar.startOfDay(for: period.start), date(2026, 3, 1))
        XCTAssertEqual(calendar.startOfDay(for: period.end), date(2026, 3, 31))
    }

    func testCustomCycleStartingOn25th() {
        let mid = FinanceMonth.period(containing: date(2026, 3, 26), startDay: 25, calendar: calendar)
        XCTAssertEqual(calendar.startOfDay(for: mid.start), date(2026, 3, 25))
        XCTAssertEqual(calendar.startOfDay(for: mid.end), date(2026, 4, 24))

        let before = FinanceMonth.period(containing: date(2026, 3, 10), startDay: 25, calendar: calendar)
        XCTAssertEqual(calendar.startOfDay(for: before.start), date(2026, 2, 25))
        XCTAssertEqual(calendar.startOfDay(for: before.end), date(2026, 3, 24))
    }

    func testFebruaryShortMonthUsesLastDay() {
        let period = FinanceMonth.period(containing: date(2026, 2, 28), startDay: 31, calendar: calendar)
        XCTAssertEqual(calendar.component(.month, from: period.start), 2)
        XCTAssertEqual(calendar.component(.day, from: period.start), 28)
    }

    func testLeapYearFebruary29() {
        let period = FinanceMonth.period(containing: date(2024, 2, 29), startDay: 31, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: period.start), 29)
        XCTAssertEqual(calendar.component(.month, from: period.start), 2)
    }

    func testDaysRemainingIncludesToday() {
        let period = FinancePeriod(start: date(2026, 4, 1), end: date(2026, 4, 10))
        XCTAssertEqual(period.daysRemaining(from: date(2026, 4, 1), calendar: calendar), 10)
        XCTAssertEqual(period.daysRemaining(from: date(2026, 4, 10), calendar: calendar), 1)
        XCTAssertEqual(period.daysRemaining(from: date(2026, 4, 11), calendar: calendar), 0)
    }

    func testContainsBoundaries() {
        let period = FinancePeriod(start: date(2026, 1, 1), end: date(2026, 1, 31))
        XCTAssertTrue(period.contains(date(2026, 1, 1), calendar: calendar))
        XCTAssertTrue(period.contains(date(2026, 1, 31), calendar: calendar))
        XCTAssertFalse(period.contains(date(2026, 2, 1), calendar: calendar))
    }

    func testNextPeriod() {
        let current = FinanceMonth.period(containing: date(2026, 1, 5), startDay: 1, calendar: calendar)
        let next = FinanceMonth.nextPeriod(after: current, startDay: 1, calendar: calendar)
        XCTAssertEqual(calendar.startOfDay(for: next.start), date(2026, 2, 1))
        XCTAssertEqual(calendar.startOfDay(for: next.end), date(2026, 2, 28))
    }

    func testClampedStartDay() {
        XCTAssertEqual(FinanceMonth.clampedStartDay(0), 1)
        XCTAssertEqual(FinanceMonth.clampedStartDay(32), 31)
        XCTAssertEqual(FinanceMonth.clampedStartDay(15), 15)
    }

    func testYearBoundaryCycle() {
        let period = FinanceMonth.period(containing: date(2026, 1, 2), startDay: 25, calendar: calendar)
        XCTAssertEqual(calendar.startOfDay(for: period.start), date(2025, 12, 25))
        XCTAssertEqual(calendar.startOfDay(for: period.end), date(2026, 1, 24))
    }
}

final class CurrencyFormatterTests: XCTestCase {
    func testParseDigitsOnly() {
        XCTAssertEqual(CurrencyFormatter.parse("25000"), 25_000)
        XCTAssertEqual(CurrencyFormatter.parse("25.000"), 25_000)
        XCTAssertEqual(CurrencyFormatter.parse("Rp25.000"), 25_000)
        XCTAssertNil(CurrencyFormatter.parse("abc"))
    }

    func testStringUsesRupiahPrefix() {
        let text = CurrencyFormatter.string(from: 1_250_000)
        XCTAssertTrue(text.contains("Rp"))
        XCTAssertTrue(text.contains("1.250.000") || text.contains("1250000"))
        XCTAssertFalse(text.contains("$"))
        XCTAssertFalse(text.contains(",250"))
    }
}
