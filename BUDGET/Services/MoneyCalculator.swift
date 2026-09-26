import Foundation

struct LedgerAccount: Equatable, Identifiable {
    var id: UUID
    var name: String
    var openingBalance: Decimal
    var isSavings: Bool
    var isArchived: Bool
}

struct LedgerTransaction: Equatable, Identifiable {
    var id: UUID
    var kind: TransactionKind
    var amount: Decimal
    var date: Date
    var accountID: UUID?
    var destinationAccountID: UUID?
    var categoryID: UUID?
    var adjustmentIncrease: Bool
}

struct SpendableEstimate: Equatable {
    var liquidBalance: Decimal
    var expectedIncome: Decimal
    var upcomingBills: Decimal
    var savingsToSetAside: Decimal
    var reserved: Decimal
    var flexibleMoney: Decimal
    var daysRemaining: Int
    var dailyEstimate: Decimal?
    var missing: [String]

    var hasEnoughData: Bool { missing.isEmpty }
}

enum MoneyCalculator {
    static func signedEffect(
        of transaction: LedgerTransaction,
        on accountID: UUID
    ) -> Decimal {
        let amount = max(transaction.amount, 0)
        switch transaction.kind {
        case .income:
            return transaction.accountID == accountID ? amount : 0
        case .expense:
            return transaction.accountID == accountID ? -amount : 0
        case .refund:
            return transaction.accountID == accountID ? amount : 0
        case .adjustment:
            guard transaction.accountID == accountID else { return 0 }
            return transaction.adjustmentIncrease ? amount : -amount
        case .transfer:
            if transaction.accountID == accountID {
                return -amount
            }
            if transaction.destinationAccountID == accountID {
                return amount
            }
            return 0
        }
    }

    static func balance(
        account: LedgerAccount,
        transactions: [LedgerTransaction]
    ) -> Decimal {
        var total = account.openingBalance
        for item in transactions {
            total += signedEffect(of: item, on: account.id)
        }
        return total
    }

    static func balances(
        accounts: [LedgerAccount],
        transactions: [LedgerTransaction]
    ) -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        for account in accounts where !account.isArchived {
            result[account.id] = balance(account: account, transactions: transactions)
        }
        return result
    }

    static func liquidMoney(
        accounts: [LedgerAccount],
        transactions: [LedgerTransaction]
    ) -> Decimal {
        accounts
            .filter { !$0.isArchived && !$0.isSavings }
            .reduce(Decimal(0)) { partial, account in
                partial + balance(account: account, transactions: transactions)
            }
    }

    static func savingsBalances(
        accounts: [LedgerAccount],
        transactions: [LedgerTransaction]
    ) -> Decimal {
        accounts
            .filter { !$0.isArchived && $0.isSavings }
            .reduce(Decimal(0)) { partial, account in
                partial + balance(account: account, transactions: transactions)
            }
    }

    static func total(
        of kind: TransactionKind,
        in transactions: [LedgerTransaction],
        period: FinancePeriod?
    ) -> Decimal {
        transactions
            .filter { $0.kind == kind }
            .filter { period == nil || period!.contains($0.date) }
            .reduce(Decimal(0)) { $0 + max($1.amount, 0) }
    }

    static func expenseByCategory(
        transactions: [LedgerTransaction],
        period: FinancePeriod?
    ) -> [UUID: Decimal] {
        var map: [UUID: Decimal] = [:]
        for item in transactions where item.kind == .expense {
            if let period, !period.contains(item.date) { continue }
            guard let categoryID = item.categoryID else { continue }
            map[categoryID, default: 0] += max(item.amount, 0)
        }
        return map
    }

    static func budgetSpent(
        categoryID: UUID,
        transactions: [LedgerTransaction],
        period: FinancePeriod
    ) -> Decimal {
        expenseByCategory(transactions: transactions, period: period)[categoryID] ?? 0
    }

    static func budgetRemaining(limit: Decimal, spent: Decimal) -> Decimal {
        limit - spent
    }

    static func budgetProgress(limit: Decimal, spent: Decimal) -> Double {
        guard limit > 0 else { return spent > 0 ? 1 : 0 }
        let ratio = NSDecimalNumber(decimal: spent).doubleValue /
            NSDecimalNumber(decimal: limit).doubleValue
        return max(0, ratio)
    }

    static func spendable(
        accounts: [LedgerAccount],
        transactions: [LedgerTransaction],
        expectedIncomeRemaining: Decimal,
        upcomingBillsRemaining: Decimal,
        savingsStillToSetAside: Decimal,
        reserved: Decimal,
        period: FinancePeriod,
        now: Date = Date(),
        calendar: Calendar = .current,
        requireExpectedIncome: Bool = false,
        requireBills: Bool = false,
        hasAnyAccount: Bool
    ) -> SpendableEstimate {
        var missing: [String] = []
        if !hasAnyAccount {
            missing.append("Tambahkan rekening atau dompet untuk mulai menghitung estimasi.")
        }

        let liquid = liquidMoney(accounts: accounts, transactions: transactions)
        let flexible = liquid
            + max(expectedIncomeRemaining, 0)
            - max(upcomingBillsRemaining, 0)
            - max(savingsStillToSetAside, 0)
            - max(reserved, 0)

        if requireExpectedIncome && expectedIncomeRemaining == 0 {
            missing.append("Tambahkan pemasukan berikutnya yang masih diharapkan.")
        }
        if requireBills && upcomingBillsRemaining == 0 {
            missing.append("Tambahkan pengeluaran wajib yang masih harus dibayar.")
        }

        let days = period.daysRemaining(from: now, calendar: calendar)
        let daily: Decimal?
        if days == 0 {
            daily = nil
            if missing.isEmpty {
                missing.append("Sisa hari pada bulan keuangan ini sudah habis.")
            }
        } else {
            daily = flexible / Decimal(days)
        }

        return SpendableEstimate(
            liquidBalance: liquid,
            expectedIncome: max(expectedIncomeRemaining, 0),
            upcomingBills: max(upcomingBillsRemaining, 0),
            savingsToSetAside: max(savingsStillToSetAside, 0),
            reserved: max(reserved, 0),
            flexibleMoney: flexible,
            daysRemaining: days,
            dailyEstimate: daily,
            missing: missing
        )
    }

    static func incrementRecurrence(from date: Date, frequency: RecurrenceFrequency, calendar: Calendar = .current) -> Date {
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

enum SnapshotFactory {
    static func accounts(_ items: [Account]) -> [LedgerAccount] {
        items.map {
            LedgerAccount(
                id: $0.id,
                name: $0.name,
                openingBalance: $0.openingBalance,
                isSavings: $0.isSavings,
                isArchived: $0.isArchived
            )
        }
    }

    static func transactions(_ items: [MoneyTransaction]) -> [LedgerTransaction] {
        items.map {
            LedgerTransaction(
                id: $0.id,
                kind: $0.kind,
                amount: $0.amount,
                date: $0.date,
                accountID: $0.account?.id,
                destinationAccountID: $0.destinationAccount?.id,
                categoryID: $0.category?.id,
                adjustmentIncrease: $0.adjustmentIncrease
            )
        }
    }
}
