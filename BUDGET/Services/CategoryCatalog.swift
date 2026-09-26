import Foundation
import SwiftData

enum CategoryCatalog {
    struct Seed {
        var name: String
        var icon: String
        var kind: CategoryKind
        var order: Int
    }

    static let defaults: [Seed] = [
        .init(name: "Makan", icon: "fork.knife", kind: .expense, order: 0),
        .init(name: "Transportasi", icon: "bus", kind: .expense, order: 1),
        .init(name: "Belanja", icon: "bag", kind: .expense, order: 2),
        .init(name: "Tagihan", icon: "doc.text", kind: .expense, order: 3),
        .init(name: "Hiburan", icon: "theatermasks", kind: .expense, order: 4),
        .init(name: "Kesehatan", icon: "cross.case", kind: .expense, order: 5),
        .init(name: "Pendidikan", icon: "book", kind: .expense, order: 6),
        .init(name: "Rumah", icon: "house", kind: .expense, order: 7),
        .init(name: "Langganan", icon: "repeat", kind: .expense, order: 8),
        .init(name: "Gaji", icon: "banknote", kind: .income, order: 9),
        .init(name: "Lainnya", icon: "ellipsis.circle", kind: .both, order: 10)
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<CategoryItem>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if !existing.isEmpty { return }
        for item in defaults {
            context.insert(
                CategoryItem(
                    name: item.name,
                    iconName: item.icon,
                    kind: item.kind,
                    isSystem: true,
                    sortOrder: item.order
                )
            )
        }
        let settingsDescriptor = FetchDescriptor<FinanceSettings>()
        let settings = (try? context.fetch(settingsDescriptor)) ?? []
        if settings.isEmpty {
            context.insert(FinanceSettings())
        }
        try? context.save()
    }
}
