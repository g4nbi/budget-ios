import Foundation
import SwiftData

@Model
final class MoneyTransaction {
    var id: UUID
    var kindRaw: String
    var amount: Decimal
    var date: Date
    var payee: String
    var note: String
    var adjustmentIncrease: Bool
    var createdAt: Date
    var recurringSourceID: UUID?

    var account: Account?
    var destinationAccount: Account?
    var category: CategoryItem?

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amount: Decimal,
        date: Date = .now,
        payee: String = "",
        note: String = "",
        adjustmentIncrease: Bool = true,
        createdAt: Date = .now,
        recurringSourceID: UUID? = nil,
        account: Account? = nil,
        destinationAccount: Account? = nil,
        category: CategoryItem? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.date = date
        self.payee = payee
        self.note = note
        self.adjustmentIncrease = adjustmentIncrease
        self.createdAt = createdAt
        self.recurringSourceID = recurringSourceID
        self.account = account
        self.destinationAccount = destinationAccount
        self.category = category
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
}
