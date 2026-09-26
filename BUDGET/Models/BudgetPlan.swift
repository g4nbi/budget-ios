import Foundation
import SwiftData

@Model
final class BudgetPlan {
    var id: UUID
    var monthlyLimit: Decimal
    var periodStart: Date
    var note: String
    var createdAt: Date
    var category: CategoryItem?

    init(
        id: UUID = UUID(),
        monthlyLimit: Decimal,
        periodStart: Date,
        note: String = "",
        createdAt: Date = .now,
        category: CategoryItem? = nil
    ) {
        self.id = id
        self.monthlyLimit = monthlyLimit
        self.periodStart = periodStart
        self.note = note
        self.createdAt = createdAt
        self.category = category
    }
}
