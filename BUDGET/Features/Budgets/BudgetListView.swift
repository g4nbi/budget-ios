import SwiftUI
import SwiftData

struct BudgetListView: View {
    @Query(sort: \BudgetPlan.periodStart, order: .reverse) private var budgets: [BudgetPlan]
    @Query private var transactions: [MoneyTransaction]
    @Query private var settingsRows: [FinanceSettings]
    @State private var showEditor = false
    @State private var editing: BudgetPlan?

    private var period: FinancePeriod {
        FinanceMonth.period(containing: .now, startDay: settingsRows.first?.financeMonthStartDay ?? 1)
    }

    var body: some View {
        NavigationStack {
            List {
                if budgets.isEmpty {
                    EmptyStateView(
                        title: "Belum ada anggaran",
                        message: "Anggaran hanya dibuat jika kamu menentukannya. Tidak ada batas otomatis.",
                        systemImage: "chart.bar",
                        actionTitle: "Tambah anggaran",
                        action: { showEditor = true }
                    )
                } else {
                    ForEach(budgets) { budget in
                        Button {
                            editing = budget
                            showEditor = true
                        } label: {
                            BudgetRow(budget: budget, transactions: transactions, fallbackPeriod: period)
                        }
                    }
                }
            }
            .navigationTitle("Anggaran")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Tambah anggaran")
                }
            }
            .sheet(isPresented: $showEditor) {
                NavigationStack { BudgetEditorView(existing: editing) }
            }
        }
    }
}

struct BudgetRow: View {
    var budget: BudgetPlan
    var transactions: [MoneyTransaction]
    var fallbackPeriod: FinancePeriod

    var body: some View {
        let period = FinancePeriod(
            start: budget.periodStart,
            end: FinanceMonth.period(containing: budget.periodStart, startDay: Calendar.current.component(.day, from: budget.periodStart)).end
        )
        let spent = budget.category.map {
            MoneyCalculator.budgetSpent(
                categoryID: $0.id,
                transactions: SnapshotFactory.transactions(transactions),
                period: period
            )
        } ?? 0
        let remaining = MoneyCalculator.budgetRemaining(limit: budget.monthlyLimit, spent: spent)
        let progress = MoneyCalculator.budgetProgress(limit: budget.monthlyLimit, spent: spent)

        VStack(alignment: .leading, spacing: BudgetSpacing.xs) {
            HStack {
                Text(budget.category?.name ?? "Tanpa kategori")
                    .foregroundStyle(.primary)
                Spacer()
                Text(CurrencyFormatter.string(from: budget.monthlyLimit))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            ProgressView(value: min(progress, 1))
                .tint(progress > 1 ? BudgetColor.expenseFallback : BudgetColor.successFallback)
            HStack {
                Text("Terpakai \(CurrencyFormatter.string(from: spent))")
                Spacer()
                Text(remaining >= 0 ? "Sisa \(CurrencyFormatter.string(from: remaining))" : "Lebih \(CurrencyFormatter.string(from: -remaining))")
            }
            .font(BudgetFont.caption())
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct BudgetEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Query private var settingsRows: [FinanceSettings]

    var existing: BudgetPlan?

    @State private var categoryID: UUID?
    @State private var limitText = ""
    @State private var periodStart = Date()
    @State private var note = ""
    @State private var showDelete = false

    var body: some View {
        Form {
            Section {
                Picker("Kategori", selection: $categoryID) {
                    Text("Pilih kategori").tag(Optional<UUID>.none)
                    ForEach(categories.filter { $0.kind != .income }) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                AmountField(title: "Batas bulanan", text: $limitText)
                DatePicker("Awal periode", selection: $periodStart, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "id_ID"))
                TextField("Catatan", text: $note)
            } footer: {
                Text("Periode mengikuti tanggal yang kamu pilih, bukan angka contoh.")
            }
            if existing != nil {
                Section {
                    Button("Hapus anggaran", role: .destructive) { showDelete = true }
                }
            }
        }
        .navigationTitle(existing == nil ? "Anggaran baru" : "Edit anggaran")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(categoryID == nil || CurrencyFormatter.parse(limitText) == nil)
            }
        }
        .onAppear(perform: populate)
        .alert("Hapus anggaran?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive, action: delete)
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Tindakan ini tidak dapat dibatalkan.")
        }
    }

    private func populate() {
        if let existing {
            categoryID = existing.category?.id
            limitText = NSDecimalNumber(decimal: existing.monthlyLimit).stringValue
            periodStart = existing.periodStart
            note = existing.note
        } else {
            let startDay = settingsRows.first?.financeMonthStartDay ?? 1
            periodStart = FinanceMonth.period(containing: .now, startDay: startDay).start
        }
    }

    private func save() {
        guard let amount = CurrencyFormatter.parse(limitText) else { return }
        let category = categories.first(where: { $0.id == categoryID })
        if let existing {
            existing.monthlyLimit = amount
            existing.periodStart = periodStart
            existing.note = note
            existing.category = category
        } else {
            context.insert(BudgetPlan(monthlyLimit: amount, periodStart: periodStart, note: note, category: category))
        }
        try? context.save()
        dismiss()
    }

    private func delete() {
        if let existing {
            context.delete(existing)
            try? context.save()
        }
        dismiss()
    }
}
