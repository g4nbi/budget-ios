import SwiftUI
import SwiftData

struct RecurringListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RecurringRule.nextDate) private var rules: [RecurringRule]
    @State private var showEditor = false
    @State private var editing: RecurringRule?
    @State private var postedMessage: String?

    var body: some View {
        List {
            if rules.isEmpty {
                EmptyStateView(
                    title: "Belum ada transaksi berulang",
                    message: "Aturan berulang tidak otomatis menjadi transaksi. Gunakan \u201cCatat sekarang\u201d jika item ini benar-benar terjadi.",
                    systemImage: "repeat",
                    actionTitle: "Tambah aturan",
                    action: { showEditor = true }
                )
            } else {
                ForEach(rules) { rule in
                    VStack(alignment: .leading, spacing: BudgetSpacing.xs) {
                        Button {
                            editing = rule
                            showEditor = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.title).foregroundStyle(.primary)
                                    Text("\(rule.kind.title) \u00b7 \(rule.frequency.title) \u00b7 berikutnya \(DateFormatting.string(rule.nextDate))")
                                        .font(BudgetFont.caption())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(CurrencyFormatter.string(from: rule.amount))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                            }
                        }
                        if rule.isActive {
                            Button("Catat sekarang") {
                                record(rule)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityHint("Membuat transaksi nyata dari aturan ini")
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Berulang")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Tambah aturan berulang")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { RecurringEditorView(existing: editing) }
        }
        .alert("Transaksi dicatat", isPresented: Binding(
            get: { postedMessage != nil },
            set: { if !$0 { postedMessage = nil } }
        )) {
            Button("OK", role: .cancel) { postedMessage = nil }
        } message: {
            Text(postedMessage ?? "")
        }
    }

    private func record(_ rule: RecurringRule) {
        let transaction = MoneyTransaction(
            kind: rule.kind,
            amount: rule.amount,
            date: Date(),
            payee: rule.payee,
            note: rule.note,
            recurringSourceID: rule.id,
            account: rule.account,
            destinationAccount: rule.destinationAccount,
            category: rule.category
        )
        context.insert(transaction)
        rule.nextDate = MoneyCalculator.incrementRecurrence(from: rule.nextDate, frequency: rule.frequency)
        try? context.save()
        postedMessage = "\(rule.title) sebesar \(CurrencyFormatter.string(from: rule.amount)) sudah dicatat."
    }
}

struct RecurringEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    var existing: RecurringRule?

    @State private var title = ""
    @State private var kind: TransactionKind = .expense
    @State private var amountText = ""
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var nextDate = Date()
    @State private var payee = ""
    @State private var note = ""
    @State private var isActive = true
    @State private var accountID: UUID?
    @State private var destinationID: UUID?
    @State private var categoryID: UUID?
    @State private var showDelete = false

    var body: some View {
        Form {
            Section {
                TextField("Nama", text: $title)
                Picker("Jenis", selection: $kind) {
                    ForEach(TransactionKind.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                AmountField(title: "Jumlah", text: $amountText)
                Picker("Frekuensi", selection: $frequency) {
                    ForEach(RecurrenceFrequency.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                DatePicker("Tanggal berikutnya", selection: $nextDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "id_ID"))
                Toggle("Aktif", isOn: $isActive)
            } footer: {
                Text("Aturan ini tidak mencatat uang sampai kamu menekan \u201cCatat sekarang\u201d.")
            }
            Section("Rekening") {
                Picker("Rekening", selection: $accountID) {
                    Text("Pilih").tag(Optional<UUID>.none)
                    ForEach(accounts.filter { !$0.isArchived }) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                if kind == .transfer {
                    Picker("Tujuan", selection: $destinationID) {
                        Text("Pilih").tag(Optional<UUID>.none)
                        ForEach(accounts.filter { !$0.isArchived }) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                }
                if kind != .transfer {
                    Picker("Kategori", selection: $categoryID) {
                        Text("Tidak dipilih").tag(Optional<UUID>.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                }
            }
            Section {
                TextField("Penerima", text: $payee)
                TextField("Catatan", text: $note)
            }
            if existing != nil {
                Button("Hapus aturan", role: .destructive) { showDelete = true }
            }
        }
        .navigationTitle("Aturan berulang")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || CurrencyFormatter.parse(amountText) == nil || accountID == nil)
            }
        }
        .onAppear(perform: populate)
        .alert("Hapus aturan?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive, action: delete)
            Button("Batal", role: .cancel) {}
        }
    }

    private func populate() {
        guard let existing else { return }
        title = existing.title
        kind = existing.kind
        amountText = NSDecimalNumber(decimal: existing.amount).stringValue
        frequency = existing.frequency
        nextDate = existing.nextDate
        payee = existing.payee
        note = existing.note
        isActive = existing.isActive
        accountID = existing.account?.id
        destinationID = existing.destinationAccount?.id
        categoryID = existing.category?.id
    }

    private func save() {
        guard let amount = CurrencyFormatter.parse(amountText) else { return }
        let account = accounts.first(where: { $0.id == accountID })
        let destination = accounts.first(where: { $0.id == destinationID })
        let category = categories.first(where: { $0.id == categoryID })
        if let existing {
            existing.title = title
            existing.kind = kind
            existing.amount = amount
            existing.frequency = frequency
            existing.nextDate = nextDate
            existing.payee = payee
            existing.note = note
            existing.isActive = isActive
            existing.account = account
            existing.destinationAccount = kind == .transfer ? destination : nil
            existing.category = category
        } else {
            context.insert(
                RecurringRule(
                    title: title, kind: kind, amount: amount, frequency: frequency,
                    nextDate: nextDate, payee: payee, note: note, isActive: isActive,
                    account: account, destinationAccount: kind == .transfer ? destination : nil,
                    category: category
                )
            )
        }
        try? context.save()
        dismiss()
    }

    private func delete() {
        if let existing { context.delete(existing); try? context.save() }
        dismiss()
    }
}
