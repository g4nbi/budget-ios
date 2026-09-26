import Foundation

struct ExportService {
    struct BackupFile: Codable {
        var exportedAt: Date
        var financeMonthStartDay: Int
        var accounts: [AccountDTO]
        var categories: [CategoryDTO]
        var transactions: [TransactionDTO]
        var budgets: [BudgetDTO]
        var goals: [GoalDTO]
        var recurring: [RecurringDTO]
        var reservations: [ReservationDTO]
        var bills: [BillDTO]
        var expectedIncome: [ExpectedDTO]
    }

    struct AccountDTO: Codable {
        var id: UUID
        var name: String
        var kind: String
        var openingBalance: String
        var isSavings: Bool
        var colorHex: String
        var iconName: String
        var isArchived: Bool
        var note: String
        var createdAt: Date
    }

    struct CategoryDTO: Codable {
        var id: UUID
        var name: String
        var iconName: String
        var kind: String
        var isSystem: Bool
        var sortOrder: Int
    }

    struct TransactionDTO: Codable {
        var id: UUID
        var kind: String
        var amount: String
        var date: Date
        var payee: String
        var note: String
        var adjustmentIncrease: Bool
        var accountID: UUID?
        var destinationAccountID: UUID?
        var categoryID: UUID?
        var recurringSourceID: UUID?
    }

    struct BudgetDTO: Codable {
        var id: UUID
        var monthlyLimit: String
        var periodStart: Date
        var note: String
        var categoryID: UUID?
    }

    struct GoalDTO: Codable {
        var id: UUID
        var name: String
        var targetAmount: String
        var currentAmount: String
        var deadline: Date?
        var note: String
        var linkedAccountID: UUID?
    }

    struct RecurringDTO: Codable {
        var id: UUID
        var title: String
        var kind: String
        var amount: String
        var frequency: String
        var nextDate: Date
        var payee: String
        var note: String
        var isActive: Bool
        var accountID: UUID?
        var destinationAccountID: UUID?
        var categoryID: UUID?
    }

    struct ReservationDTO: Codable {
        var id: UUID
        var name: String
        var amount: String
        var note: String
        var accountID: UUID?
    }

    struct BillDTO: Codable {
        var id: UUID
        var name: String
        var amount: String
        var dueDate: Date
        var note: String
        var isSettled: Bool
        var accountID: UUID?
        var categoryID: UUID?
    }

    struct ExpectedDTO: Codable {
        var id: UUID
        var name: String
        var amount: String
        var expectedDate: Date
        var note: String
        var isReceived: Bool
        var accountID: UUID?
    }

    static func makeBackup(
        settings: FinanceSettings?,
        accounts: [Account],
        categories: [CategoryItem],
        transactions: [MoneyTransaction],
        budgets: [BudgetPlan],
        goals: [FinancialGoal],
        recurring: [RecurringRule],
        reservations: [ReservedMoney],
        bills: [UpcomingBill],
        expectedIncome: [ExpectedIncome]
    ) -> BackupFile {
        BackupFile(
            exportedAt: .now,
            financeMonthStartDay: settings?.financeMonthStartDay ?? 1,
            accounts: accounts.map {
                AccountDTO(
                    id: $0.id, name: $0.name, kind: $0.kindRaw,
                    openingBalance: "\($0.openingBalance)", isSavings: $0.isSavings,
                    colorHex: $0.colorHex, iconName: $0.iconName, isArchived: $0.isArchived,
                    note: $0.note, createdAt: $0.createdAt
                )
            },
            categories: categories.map {
                CategoryDTO(
                    id: $0.id, name: $0.name, iconName: $0.iconName,
                    kind: $0.kindRaw, isSystem: $0.isSystem, sortOrder: $0.sortOrder
                )
            },
            transactions: transactions.map {
                TransactionDTO(
                    id: $0.id, kind: $0.kindRaw, amount: "\($0.amount)", date: $0.date,
                    payee: $0.payee, note: $0.note, adjustmentIncrease: $0.adjustmentIncrease,
                    accountID: $0.account?.id, destinationAccountID: $0.destinationAccount?.id,
                    categoryID: $0.category?.id, recurringSourceID: $0.recurringSourceID
                )
            },
            budgets: budgets.map {
                BudgetDTO(
                    id: $0.id, monthlyLimit: "\($0.monthlyLimit)",
                    periodStart: $0.periodStart, note: $0.note, categoryID: $0.category?.id
                )
            },
            goals: goals.map {
                GoalDTO(
                    id: $0.id, name: $0.name, targetAmount: "\($0.targetAmount)",
                    currentAmount: "\($0.currentAmount)", deadline: $0.deadline,
                    note: $0.note, linkedAccountID: $0.linkedAccount?.id
                )
            },
            recurring: recurring.map {
                RecurringDTO(
                    id: $0.id, title: $0.title, kind: $0.kindRaw, amount: "\($0.amount)",
                    frequency: $0.frequencyRaw, nextDate: $0.nextDate, payee: $0.payee,
                    note: $0.note, isActive: $0.isActive, accountID: $0.account?.id,
                    destinationAccountID: $0.destinationAccount?.id, categoryID: $0.category?.id
                )
            },
            reservations: reservations.map {
                ReservationDTO(
                    id: $0.id, name: $0.name, amount: "\($0.amount)",
                    note: $0.note, accountID: $0.account?.id
                )
            },
            bills: bills.map {
                BillDTO(
                    id: $0.id, name: $0.name, amount: "\($0.amount)", dueDate: $0.dueDate,
                    note: $0.note, isSettled: $0.isSettled, accountID: $0.account?.id,
                    categoryID: $0.category?.id
                )
            },
            expectedIncome: expectedIncome.map {
                ExpectedDTO(
                    id: $0.id, name: $0.name, amount: "\($0.amount)",
                    expectedDate: $0.expectedDate, note: $0.note,
                    isReceived: $0.isReceived, accountID: $0.account?.id
                )
            }
        )
    }

    static func jsonData(from backup: BackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    static func csv(from transactions: [MoneyTransaction]) -> String {
        var rows = ["tanggal,jenis,jumlah,rekening,rekening_tujuan,kategori,penerima,catatan"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        for item in transactions.sorted(by: { $0.date > $1.date }) {
            let fields = [
                formatter.string(from: item.date),
                item.kind.title,
                "\(item.amount)",
                csvEscape(item.account?.name ?? ""),
                csvEscape(item.destinationAccount?.name ?? ""),
                csvEscape(item.category?.name ?? ""),
                csvEscape(item.payee),
                csvEscape(item.note)
            ]
            rows.append(fields.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
