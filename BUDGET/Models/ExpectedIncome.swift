import Foundation
import SwiftData

@Model
final class ExpectedIncome {
    var id: UUID
    var name: String
    var amount: Decimal
    var expectedDate: Date
    var note: String
    var isReceived: Bool
    var createdAt: Date
    var account: Account?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        expectedDate: Date,
        note: String = "",
        isReceived: Bool = false,
        createdAt: Date = .now,
        account: Account? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.expectedDate = expectedDate
        self.note = note
        self.isReceived = isReceived
        self.createdAt = createdAt
        self.account = account
    }
}
