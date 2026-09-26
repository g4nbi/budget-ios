import SwiftUI

enum BudgetColor {
    static let incomeFallback = Color(red: 0.18, green: 0.52, blue: 0.38)
    static let expenseFallback = Color(red: 0.72, green: 0.24, blue: 0.22)
    static let warningFallback = Color(red: 0.72, green: 0.48, blue: 0.10)
    static let successFallback = Color(red: 0.20, green: 0.50, blue: 0.36)
    static let transferFallback = Color(red: 0.22, green: 0.40, blue: 0.62)
}

enum BudgetSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum BudgetRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

enum BudgetIcon {
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
}

enum BudgetFont {
    static func largeTitle() -> Font { .largeTitle.weight(.semibold) }
    static func title() -> Font { .title2.weight(.semibold) }
    static func headline() -> Font { .headline }
    static func body() -> Font { .body }
    static func callout() -> Font { .callout }
    static func footnote() -> Font { .footnote }
    static func caption() -> Font { .caption }
    static func money() -> Font { .system(.title2, design: .rounded).weight(.semibold) }
    static func moneyLarge() -> Font { .system(.title, design: .rounded).weight(.semibold) }
}

extension Color {
    static func budgetIncome(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.46, green: 0.78, blue: 0.62)
            : BudgetColor.incomeFallback
    }

    static func budgetExpense(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.92, green: 0.48, blue: 0.44)
            : BudgetColor.expenseFallback
    }

    static func budgetWarning(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.94, green: 0.72, blue: 0.32)
            : BudgetColor.warningFallback
    }

    static func budgetTransfer(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.52, green: 0.68, blue: 0.90)
            : BudgetColor.transferFallback
    }

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 120, 120, 120)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
