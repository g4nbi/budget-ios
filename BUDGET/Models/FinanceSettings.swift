import Foundation
import SwiftData

@Model
final class FinanceSettings {
    var id: UUID
    var financeMonthStartDay: Int
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        financeMonthStartDay: Int = 1,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.financeMonthStartDay = min(max(financeMonthStartDay, 1), 31)
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
    }
}
