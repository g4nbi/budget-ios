import Foundation
import SwiftData

@Model
final class ReservedMoney {
    var id: UUID
    var name: String
    var amount: Decimal
    var note: String
    var createdAt: Date
    var account: Account?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        note: String = "",
        createdAt: Date = .now,
        account: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.note = note
        self.createdAt = createdAt
        self.account = account
    }
}
