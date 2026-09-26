import SwiftUI
import SwiftData

struct HomeView: View {
    var onAddTransaction: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @Query private var settingsRows: [FinanceSettings]
    @Query(filter: #Predicate<UpcomingBill> { !$0.isSettled }) private var openBills: [UpcomingBill]
    @Query(filter: #Predicate<ExpectedIncome> { !$0.isReceived }) private var openIncome: [ExpectedIncome]
    @Query private var reservations: [ReservedMoney]
    @Query private var goals: [FinancialGoal]

    @State private var showAddAccount = false
    @State private var showAccounts = false
    @State private var showBills = false
    @State private var showIncome = false
    @State private var showReservations = false
    @State private var showRecurring = false
    @State private var showAnalytics = false

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }
    private var settings: FinanceSettings? { settingsRows.first }
    private var period: FinancePeriod {
        FinanceMonth.period(
            containing: .now,
            startDay: settings?.financeMonthStartDay ?? 1
        )
    }

    var body: some View {
        NavigationStack {
            List {
                periodSection
                statusSection
                spendableSection
                if !activeAccounts.isEmpty {
                    accountsSection
                }
                shortcutsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ringkasan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onAddTransaction) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Tambah transaksi")
                    .disabled(activeAccounts.isEmpty)
                }
            }
            .sheet(isPresented: $showAddAccount) {
                NavigationStack { AccountEditorView(existing: nil) }
            }
            .sheet(isPresented: $showAccounts) {
                NavigationStack { AccountListView() }
            }
            .sheet(isPresented: $showBills) {
                NavigationStack { BillListView() }
            }
            .sheet(isPresented: $showIncome) {
                NavigationStack { ExpectedIncomeListView() }
            }
            .sheet(isPresented: $showReservations) {
                NavigationStack { ReservationListView() }
            }
            .sheet(isPresented: $showRecurring) {
                NavigationStack { RecurringListView() }
            }
            .sheet(isPresented: $showAnalytics) {
                NavigationStack { AnalyticsView() }
            }
        }
    }

    private var periodSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text(DateFormatting.monthYear.string(from: period.start))
                    .font(BudgetFont.headline())
                Text("\(DateFormatting.string(period.start)) – \(DateFormatting.string(period.end))")
                    .font(BudgetFont.footnote())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section {
            if activeAccounts.isEmpty {
                EmptyStateView(
                    title: "Belum cukup data",
                    message: "Tambahkan rekening atau dompet untuk mulai mencatat uangmu.",
                    systemImage: "wallet.pass",
                    actionTitle: "Tambah rekening",
                    action: { showAddAccount = true }
                )
            } else if transactions.isEmpty {
                EmptyStateView(
                    title: "Rekening sudah siap.",
                    message: "Catat transaksi pertama untuk mulai melihat arus uangmu.",
                    systemImage: "square.and.pencil",
                    actionTitle: "Tambah transaksi",
                    action: onAddTransaction
                )
            } else {
                let periodTransactions = transactions.filter { period.contains($0.date) }
                let expenses = periodTransactions.filter { $0.kind == .expense }
                let incomes = periodTransactions.filter { $0.kind == .income }
                if expenses.isEmpty && incomes.isEmpty {
                    Text("Belum ada pemasukan atau pengeluaran pada bulan keuangan ini.")
                        .foregroundStyle(.secondary)
                } else {
                    if !incomes.isEmpty {
                        labeledRow(
                            "Pemasukan bulan ini",
                            CurrencyFormatter.string(from: incomes.reduce(0) { $0 + $1.amount })
                        )
                    }
                    if !expenses.isEmpty {
                        labeledRow(
                            "Pengeluaran bulan ini",
                            CurrencyFormatter.string(from: expenses.reduce(0) { $0 + $1.amount })
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var spendableSection: some View {
        Section {
            if activeAccounts.isEmpty {
                Text("Estimasi \u201cAman dibelanjakan\u201d muncul setelah ada rekening.")
                    .foregroundStyle(.secondary)
            } else if openIncome.isEmpty && openBills.isEmpty {
                EmptyStateView(
                    title: "Belum cukup data",
                    message: "Tambahkan pemasukan berikutnya dan pengeluaran wajib untuk menghitung estimasi.",
                    systemImage: "questionmark.circle",
                    actionTitle: "Tambah pemasukan diharapkan",
                    action: { showIncome = true }
                )
                Button("Tambah pengeluaran wajib") { showBills = true }
            } else {
                let estimate = currentEstimate
                if let daily = estimate.dailyEstimate {
                    VStack(alignment: .leading, spacing: BudgetSpacing.xs) {
                        Text("Aman dibelanjakan")
                            .font(BudgetFont.headline())
                        Text(CurrencyFormatter.string(from: daily) + " / hari")
                            .font(BudgetFont.moneyLarge())
                            .accessibilityLabel("Estimasi \(CurrencyFormatter.string(from: daily)) per hari")
                        Text("Dana fleksibel \(CurrencyFormatter.string(from: estimate.flexibleMoney)) untuk \(estimate.daysRemaining) hari tersisa.")
                            .font(BudgetFont.footnote())
                            .foregroundStyle(.secondary)
                        EstimateDisclaimer()
                    }
                    .padding(.vertical, 4)
                } else {
                    Text(estimate.missing.first ?? "Belum cukup data")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Estimasi")
        }
    }

    private var accountsSection: some View {
        Section("Rekening") {
            ForEach(activeAccounts) { account in
                let value = MoneyCalculator.balance(
                    account: SnapshotFactory.accounts([account])[0],
                    transactions: SnapshotFactory.transactions(transactions)
                )
                HStack(spacing: BudgetSpacing.sm) {
                    AccountGlyph(systemImage: account.iconName, hex: account.colorHex)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                        Text(account.isSavings ? "Tabungan" : account.kind.title)
                            .font(BudgetFont.caption())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(CurrencyFormatter.string(from: value))
                        .font(BudgetFont.callout())
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(account.name), \(CurrencyFormatter.string(from: value))")
            }
            Button("Kelola rekening") { showAccounts = true }
        }
    }

    private var shortcutsSection: some View {
        Section("Catatan terencana") {
            Button("Pengeluaran wajib") { showBills = true }
            Button("Pemasukan diharapkan") { showIncome = true }
            Button("Uang disisihkan") { showReservations = true }
            Button("Transaksi berulang") { showRecurring = true }
            Button("Analitik") { showAnalytics = true }
        }
    }

    private var currentEstimate: SpendableEstimate {
        let snapshotAccounts = SnapshotFactory.accounts(activeAccounts)
        let snapshotTransactions = SnapshotFactory.transactions(transactions)
        let expected = openIncome
            .filter { period.contains($0.expectedDate) || $0.expectedDate >= period.start }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let bills = openBills
            .filter { period.contains($0.dueDate) || $0.dueDate >= Date() }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let reserved = reservations.reduce(Decimal(0)) { $0 + $1.amount }
        let savingsTargets = goals.reduce(Decimal(0)) { partial, goal in
            let current: Decimal
            if let linked = goal.linkedAccount {
                current = MoneyCalculator.balance(
                    account: SnapshotFactory.accounts([linked])[0],
                    transactions: snapshotTransactions
                )
            } else {
                current = goal.currentAmount
            }
            return partial + max(goal.targetAmount - current, 0)
        }
        return MoneyCalculator.spendable(
            accounts: snapshotAccounts,
            transactions: snapshotTransactions,
            expectedIncomeRemaining: expected,
            upcomingBillsRemaining: bills,
            savingsStillToSetAside: savingsTargets,
            reserved: reserved,
            period: period,
            hasAnyAccount: !activeAccounts.isEmpty
        )
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
