import Foundation
import SwiftData

@Model
final class RecurringRule {
    var id: UUID
    var title: String
    var kindRaw: String
    var amount: Decimal
    var frequencyRaw: String
    var nextDate: Date
    var payee: String
    var note: String
    var isActive: Bool
    var createdAt: Date
    var account: Account?
    var destinationAccount: Account?
    var category: CategoryItem?

    init(
        id: UUID = UUID(),
        title: String,
        kind: TransactionKind,
        amount: Decimal,
        frequency: RecurrenceFrequency,
        nextDate: Date,
        payee: String = "",
        note: String = "",
        isActive: Bool = true,
        createdAt: Date = .now,
        account: Account? = nil,
        destinationAccount: Account? = nil,
        category: CategoryItem? = nil
    ) {
        self.id = id
        self.title = title
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.nextDate = nextDate
        self.payee = payee
        self.note = note
        self.isActive = isActive
        self.createdAt = createdAt
        self.account = account
        self.destinationAccount = destinationAccount
        self.category = category
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var frequency: RecurrenceFrequency {
        get { RecurrenceFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }
}
