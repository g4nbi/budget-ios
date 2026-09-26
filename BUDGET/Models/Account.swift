import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var kindRaw: String
    var openingBalance: Decimal
    var isSavings: Bool
    var colorHex: String
    var iconName: String
    var isArchived: Bool
    var createdAt: Date
    var note: String

    @Relationship(deleteRule: .nullify, inverse: \MoneyTransaction.account)
    var outgoingTransactions: [MoneyTransaction]

    @Relationship(deleteRule: .nullify, inverse: \MoneyTransaction.destinationAccount)
    var incomingTransfers: [MoneyTransaction]

    init(
        id: UUID = UUID(),
        name: String,
        kind: AccountKind,
        openingBalance: Decimal,
        isSavings: Bool? = nil,
        colorHex: String = AccountTint.stone.hex,
        iconName: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.openingBalance = openingBalance
        self.isSavings = isSavings ?? kind.treatsAsSavingsByDefault
        self.colorHex = colorHex
        self.iconName = iconName ?? kind.systemImage
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.note = note
        self.outgoingTransactions = []
        self.incomingTransfers = []
    }

    var kind: AccountKind {
        get { AccountKind(rawValue: kindRaw) ?? .custom }
        set { kindRaw = newValue.rawValue }
    }
}
