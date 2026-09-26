import SwiftUI
import SwiftData

struct GoalListView: View {
    @Query(sort: \FinancialGoal.createdAt, order: .reverse) private var goals: [FinancialGoal]
    @Query private var transactions: [MoneyTransaction]
    @State private var showEditor = false
    @State private var editing: FinancialGoal?

    var body: some View {
        NavigationStack {
            List {
                if goals.isEmpty {
                    EmptyStateView(
                        title: "Belum ada tujuan",
                        message: "Tujuan keuangan hanya muncul jika kamu membuatnya sendiri.",
                        systemImage: "flag",
                        actionTitle: "Tambah tujuan",
                        action: { showEditor = true }
                    )
                } else {
                    ForEach(goals) { goal in
                        Button {
                            editing = goal
                            showEditor = true
                        } label: {
                            GoalRow(goal: goal, transactions: transactions)
                        }
                    }
                }
            }
            .navigationTitle("Tujuan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Tambah tujuan")
                }
            }
            .sheet(isPresented: $showEditor) {
                NavigationStack { GoalEditorView(existing: editing) }
            }
        }
    }
}

struct GoalRow: View {
    var goal: FinancialGoal
    var transactions: [MoneyTransaction]

    var body: some View {
        let current = currentAmount
        let progress = MoneyCalculator.budgetProgress(limit: goal.targetAmount, spent: current)
        VStack(alignment: .leading, spacing: BudgetSpacing.xs) {
            HStack {
                Text(goal.name)
                    .foregroundStyle(.primary)
                Spacer()
                Text(CurrencyFormatter.string(from: goal.targetAmount))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            ProgressView(value: min(progress, 1))
            Text("Terkumpul \(CurrencyFormatter.string(from: current))")
                .font(BudgetFont.caption())
                .foregroundStyle(.secondary)
            if let deadline = goal.deadline {
                Text("Target \(DateFormatting.long(deadline))")
                    .font(BudgetFont.caption())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var currentAmount: Decimal {
        if let linked = goal.linkedAccount {
            return MoneyCalculator.balance(
                account: SnapshotFactory.accounts([linked])[0],
                transactions: SnapshotFactory.transactions(transactions)
            )
        }
        return goal.currentAmount
    }
}

struct GoalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    var existing: FinancialGoal?

    @State private var name = ""
    @State private var targetText = ""
    @State private var currentText = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var note = ""
    @State private var linkedID: UUID?
    @State private var showDelete = false

    var body: some View {
        Form {
            Section {
                TextField("Nama tujuan", text: $name)
                AmountField(title: "Target", text: $targetText)
                if linkedID == nil {
                    AmountField(title: "Jumlah saat ini", text: $currentText)
                }
                Picker("Rekening tabungan (opsional)", selection: $linkedID) {
                    Text("Tidak tertaut").tag(Optional<UUID>.none)
                    ForEach(accounts.filter { !$0.isArchived }) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                Toggle("Pakai tenggat", isOn: $hasDeadline)
                if hasDeadline {
                    DatePicker("Tenggat", selection: $deadline, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "id_ID"))
                }
                TextField("Catatan", text: $note)
            }
            if existing != nil {
                Section {
                    Button("Hapus tujuan", role: .destructive) { showDelete = true }
                }
            }
        }
        .navigationTitle(existing == nil ? "Tujuan baru" : "Edit tujuan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || CurrencyFormatter.parse(targetText) == nil)
            }
        }
        .onAppear(perform: populate)
        .alert("Hapus tujuan?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive, action: delete)
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Tindakan ini tidak dapat dibatalkan.")
        }
    }

    private func populate() {
        guard let existing else { return }
        name = existing.name
        targetText = NSDecimalNumber(decimal: existing.targetAmount).stringValue
        currentText = NSDecimalNumber(decimal: existing.currentAmount).stringValue
        note = existing.note
        linkedID = existing.linkedAccount?.id
        if let deadline = existing.deadline {
            hasDeadline = true
            self.deadline = deadline
        }
    }

    private func save() {
        guard let target = CurrencyFormatter.parse(targetText) else { return }
        let current = CurrencyFormatter.parse(currentText) ?? 0
        let linked = accounts.first(where: { $0.id == linkedID })
        if let existing {
            existing.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.targetAmount = target
            existing.currentAmount = current
            existing.deadline = hasDeadline ? deadline : nil
            existing.note = note
            existing.linkedAccount = linked
        } else {
            context.insert(
                FinancialGoal(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    targetAmount: target,
                    currentAmount: current,
                    deadline: hasDeadline ? deadline : nil,
                    note: note,
                    linkedAccount: linked
                )
            )
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
