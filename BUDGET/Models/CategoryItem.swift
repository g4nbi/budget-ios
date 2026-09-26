import Foundation
import SwiftData

@Model
final class CategoryItem {
    var id: UUID
    var name: String
    var iconName: String
    var kindRaw: String
    var isSystem: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \MoneyTransaction.category)
    var transactions: [MoneyTransaction]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        kind: CategoryKind = .expense,
        isSystem: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.kindRaw = kind.rawValue
        self.isSystem = isSystem
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.transactions = []
    }

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
}
