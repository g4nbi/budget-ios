import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var settingsRows: [FinanceSettings]
    @Query private var budgets: [BudgetPlan]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    private var period: FinancePeriod {
        FinanceMonth.period(containing: .now, startDay: settingsRows.first?.financeMonthStartDay ?? 1)
    }

    private var periodTransactions: [MoneyTransaction] {
        transactions.filter { period.contains($0.date) }
    }

    private var expenses: [MoneyTransaction] {
        periodTransactions.filter { $0.kind == .expense }
    }

    private var incomes: [MoneyTransaction] {
        periodTransactions.filter { $0.kind == .income }
    }

    var body: some View {
        List {
            if transactions.isEmpty {
                EmptyStateView(
                    title: "Belum cukup data",
                    message: "Analitik hanya tampil setelah ada transaksi nyata. Tidak ada grafik kosong.",
                    systemImage: "chart.xyaxis.line"
                )
            } else if expenses.isEmpty && incomes.isEmpty {
                EmptyStateView(
                    title: "Belum cukup data untuk periode ini",
                    message: "Ada transaksi di bulan lain, tetapi belum ada pemasukan atau pengeluaran pada \(DateFormatting.string(period.start))–\(DateFormatting.string(period.end)).",
                    systemImage: "chart.bar"
                )
            } else {
                if !expenses.isEmpty || !incomes.isEmpty {
                    Section("Periode ini") {
                        if !incomes.isEmpty {
                            labeled("Pemasukan", incomes.reduce(0) { $0 + $1.amount })
                        }
                        if !expenses.isEmpty {
                            labeled("Pengeluaran", expenses.reduce(0) { $0 + $1.amount })
                        }
                    }
                }

                if !expenses.isEmpty {
                    Section("Pengeluaran per kategori") {
                        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "Tanpa kategori" }
                            .map { key, value in (key, value.reduce(Decimal(0)) { $0 + $1.amount }) }
                            .sorted { $0.1 > $1.1 }
                        Chart(grouped, id: \.0) { item in
                            BarMark(
                                x: .value("Jumlah", NSDecimalNumber(decimal: item.1).doubleValue),
                                y: .value("Kategori", item.0)
                            )
                        }
                        .frame(height: CGFloat(max(160, grouped.count * 36)))
                        .accessibilityLabel("Pengeluaran per kategori")
                        ForEach(grouped, id: \.0) { item in
                            HStack {
                                Text(item.0)
                                Spacer()
                                Text(CurrencyFormatter.string(from: item.1)).monospacedDigit()
                            }
                        }
                    }
                }

                let monthly = monthlyTrend()
                if monthly.count >= 2 {
                    Section("Tren bulanan") {
                        Chart(monthly, id: \.label) { item in
                            LineMark(
                                x: .value("Bulan", item.label),
                                y: .value("Pengeluaran", NSDecimalNumber(decimal: item.expense).doubleValue)
                            )
                            if item.income > 0 {
                                LineMark(
                                    x: .value("Bulan", item.label),
                                    y: .value("Pemasukan", NSDecimalNumber(decimal: item.income).doubleValue)
                                )
                                .foregroundStyle(BudgetColor.incomeFallback)
                            }
                        }
                        .frame(height: 180)
                    }
                }

                if !budgets.isEmpty {
                    Section("Progres anggaran") {
                        ForEach(budgets) { budget in
                            BudgetRow(
                                budget: budget,
                                transactions: transactions,
                                fallbackPeriod: period
                            )
                        }
                    }
                }

                if !accounts.filter({ !$0.isArchived }).isEmpty {
                    Section("Saldo rekening") {
                        ForEach(accounts.filter { !$0.isArchived }) { account in
                            let value = MoneyCalculator.balance(
                                account: SnapshotFactory.accounts([account])[0],
                                transactions: SnapshotFactory.transactions(transactions)
                            )
                            HStack {
                                Text(account.name)
                                Spacer()
                                Text(CurrencyFormatter.string(from: value)).monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Analitik")
    }

    private func labeled(_ title: String, _ value: Decimal) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(CurrencyFormatter.string(from: value)).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private struct MonthPoint {
        var label: String
        var expense: Decimal
        var income: Decimal
    }

    private func monthlyTrend() -> [MonthPoint] {
        let calendar = Calendar.current
        var buckets: [String: (Decimal, Decimal)] = [:]
        for item in transactions {
            let comps = calendar.dateComponents([.year, .month], from: item.date)
            guard let year = comps.year, let month = comps.month else { continue }
            let label = String(format: "%04d-%02d", year, month)
            var current = buckets[label] ?? (0, 0)
            if item.kind == .expense { current.0 += item.amount }
            if item.kind == .income { current.1 += item.amount }
            buckets[label] = current
        }
        return buckets.keys.sorted().suffix(6).map { key in
            let pair = buckets[key] ?? (0, 0)
            return MonthPoint(label: key, expense: pair.0, income: pair.1)
        }
    }
}
