import Foundation
import SwiftData

@Model
final class UpcomingBill {
    var id: UUID
    var name: String
    var amount: Decimal
    var dueDate: Date
    var note: String
    var isSettled: Bool
    var createdAt: Date
    var account: Account?
    var category: CategoryItem?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        dueDate: Date,
        note: String = "",
        isSettled: Bool = false,
        createdAt: Date = .now,
        account: Account? = nil,
        category: CategoryItem? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.note = note
        self.isSettled = isSettled
        self.createdAt = createdAt
        self.account = account
        self.category = category
    }
}
