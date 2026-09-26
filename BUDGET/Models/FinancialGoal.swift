import Foundation
import SwiftData

@Model
final class FinancialGoal {
    var id: UUID
    var name: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var deadline: Date?
    var note: String
    var createdAt: Date
    var linkedAccount: Account?

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        deadline: Date? = nil,
        note: String = "",
        createdAt: Date = .now,
        linkedAccount: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.note = note
        self.createdAt = createdAt
        self.linkedAccount = linkedAccount
    }
}
