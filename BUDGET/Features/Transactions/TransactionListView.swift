import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @State private var showEditor = false
    @State private var editing: MoneyTransaction?
    @State private var kindFilter: TransactionKind?

    private var visible: [MoneyTransaction] {
        if let kindFilter {
            return transactions.filter { $0.kind == kindFilter }
        }
        return transactions
    }

    var body: some View {
        NavigationStack {
            List {
                if accounts.filter({ !$0.isArchived }).isEmpty {
                    EmptyStateView(
                        title: "Belum cukup data",
                        message: "Tambahkan rekening terlebih dahulu sebelum mencatat transaksi.",
                        systemImage: "wallet.pass"
                    )
                } else if transactions.isEmpty {
                    EmptyStateView(
                        title: "Belum ada transaksi",
                        message: "Catat pemasukan, pengeluaran, transfer, pengembalian, atau penyesuaian.",
                        systemImage: "list.bullet",
                        actionTitle: "Tambah transaksi",
                        action: { showEditor = true }
                    )
                } else {
                    Section {
                        Picker("Jenis", selection: $kindFilter) {
                            Text("Semua").tag(Optional<TransactionKind>.none)
                            ForEach(TransactionKind.allCases) { kind in
                                Text(kind.title).tag(Optional(kind))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    ForEach(visible) { item in
                        Button {
                            editing = item
                            showEditor = true
                        } label: {
                            TransactionRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Transaksi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Tambah transaksi")
                    .disabled(accounts.filter { !$0.isArchived }.isEmpty)
                }
            }
            .sheet(isPresented: $showEditor) {
                NavigationStack {
                    TransactionEditorView(existing: editing)
                }
            }
        }
    }
}

struct TransactionRow: View {
    @Environment(\.colorScheme) private var scheme
    var item: MoneyTransaction

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: BudgetSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(primaryTitle)
                    .foregroundStyle(.primary)
                Text(secondaryTitle)
                    .font(BudgetFont.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountText)
                .foregroundStyle(amountColor)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.kind.title), \(primaryTitle), \(amountText), \(DateFormatting.string(item.date))")
    }

    private var primaryTitle: String {
        if !item.payee.isEmpty { return item.payee }
        if let category = item.category { return category.name }
        return item.kind.title
    }

    private var secondaryTitle: String {
        var parts: [String] = [item.kind.title, DateFormatting.string(item.date)]
        if let account = item.account { parts.append(account.name) }
        return parts.joined(separator: " · ")
    }

    private var amountText: String {
        let prefix: String
        switch item.kind {
        case .income, .refund: prefix = "+"
        case .expense: prefix = "\u2212"
        case .transfer: prefix = "\u2192"
        case .adjustment: prefix = item.adjustmentIncrease ? "+" : "\u2212"
        }
        if item.kind == .transfer {
            return CurrencyFormatter.string(from: item.amount)
        }
        return prefix + CurrencyFormatter.string(from: item.amount)
    }

    private var amountColor: Color {
        switch item.kind {
        case .income, .refund: Color.budgetIncome(scheme)
        case .expense: Color.budgetExpense(scheme)
        case .transfer: Color.budgetTransfer(scheme)
        case .adjustment: item.adjustmentIncrease ? Color.budgetIncome(scheme) : Color.budgetExpense(scheme)
        }
    }
}
