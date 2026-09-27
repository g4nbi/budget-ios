import Foundation

enum CurrencyFormatter {
    static let rupiah: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .currency
        formatter.currencyCode = "IDR"
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.currencyGroupingSeparator = "."
        return formatter
    }()

    static let grouping: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = "."
        return formatter
    }()

    static func string(from value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        if let formatted = rupiah.string(from: number) {
            return formatted.replacingOccurrences(of: "\u{00a0}", with: "")
                .replacingOccurrences(of: " ", with: "")
        }
        return "Rp\(grouping.string(from: number) ?? "0")"
    }

    static func compact(from value: Decimal) -> String {
        string(from: value)
    }

    static func parse(_ raw: String) -> Decimal? {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Decimal(string: digits)
    }
}

enum DateFormatting {
    static let indonesian: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let indonesianLong: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    static let weekdayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "EEEE, d MMM"
        return formatter
    }()

    static func string(_ date: Date) -> String {
        indonesian.string(from: date)
    }

    static func long(_ date: Date) -> String {
        indonesianLong.string(from: date)
    }
}
