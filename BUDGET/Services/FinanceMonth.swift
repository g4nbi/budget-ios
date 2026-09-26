import Foundation

struct FinancePeriod: Equatable {
    let start: Date
    let end: Date

    var daysRemaining: Int {
        daysRemaining(from: Date())
    }

    func daysRemaining(from now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        let lastDay = calendar.startOfDay(for: end)
        if today > lastDay { return 0 }
        let components = calendar.dateComponents([.day], from: today, to: lastDay)
        return max((components.day ?? 0) + 1, 0)
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: start) && day <= calendar.startOfDay(for: end)
    }
}

enum FinanceMonth {
    static func period(
        containing referenceDate: Date,
        startDay: Int,
        calendar: Calendar = .current
    ) -> FinancePeriod {
        let day = clampedStartDay(startDay)
        let ref = calendar.dateComponents([.year, .month, .day], from: referenceDate)

        guard let year = ref.year, let month = ref.month, let currentDay = ref.day else {
            let start = calendar.startOfDay(for: referenceDate)
            return FinancePeriod(start: start, end: start)
        }

        let startThisMonth = date(year: year, month: month, startDay: day, calendar: calendar)

        let periodStart: Date
        if currentDay >= calendar.component(.day, from: startThisMonth) &&
            monthEquals(startThisMonth, year: year, month: month, calendar: calendar) &&
            referenceDate >= calendar.startOfDay(for: startThisMonth) {
            periodStart = calendar.startOfDay(for: startThisMonth)
        } else if calendar.startOfDay(for: referenceDate) >= calendar.startOfDay(for: startThisMonth) {
            periodStart = calendar.startOfDay(for: startThisMonth)
        } else {
            let prev = previousMonth(year: year, month: month)
            periodStart = calendar.startOfDay(for: date(year: prev.year, month: prev.month, startDay: day, calendar: calendar))
        }

        let startComponents = calendar.dateComponents([.year, .month], from: periodStart)
        let next = nextMonth(year: startComponents.year ?? year, month: startComponents.month ?? month)
        let nextStart = date(year: next.year, month: next.month, startDay: day, calendar: calendar)
        let end = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: nextStart)) ?? periodStart

        return FinancePeriod(start: periodStart, end: calendar.startOfDay(for: end))
    }

    static func nextPeriod(after period: FinancePeriod, startDay: Int, calendar: Calendar = .current) -> FinancePeriod {
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: period.end) ?? period.end
        return self.period(containing: dayAfter, startDay: startDay, calendar: calendar)
    }

    static func clampedStartDay(_ day: Int) -> Int {
        min(max(day, 1), 31)
    }

    static func date(year: Int, month: Int, startDay: Int, calendar: Calendar) -> Date {
        let safeDay = min(startDay, daysInMonth(year: year, month: month, calendar: calendar))
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = safeDay
        return calendar.date(from: components) ?? Date()
    }

    static func daysInMonth(year: Int, month: Int, calendar: Calendar) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }

    static func previousMonth(year: Int, month: Int) -> (year: Int, month: Int) {
        if month == 1 { return (year - 1, 12) }
        return (year, month - 1)
    }

    static func nextMonth(year: Int, month: Int) -> (year: Int, month: Int) {
        if month == 12 { return (year + 1, 1) }
        return (year, month + 1)
    }

    private static func monthEquals(_ date: Date, year: Int, month: Int, calendar: Calendar) -> Bool {
        let c = calendar.dateComponents([.year, .month], from: date)
        return c.year == year && c.month == month
    }
}
