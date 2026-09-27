import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]

    var existing: MoneyTransaction?

    @State private var kind: TransactionKind = .expense
    @State private var amountText = ""
    @State private var date = Date()
    @State private var payee = ""
    @State private var note = ""
    @State private var accountID: UUID?
    @State private var destinationID: UUID?
    @State private var categoryID: UUID?
    @State private var adjustmentIncrease = false
    @State private var showDelete = false
    @State private var showAICategory = false
    @State private var aiSuggestion = ""
    @State private var aiBusy = false
    @State private var aiError: String?
    @State private var confirmSendAI = false

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    var body: some View {
        Form {
            Section("Jenis") {
                Picker("Jenis transaksi", selection: $kind) {
                    ForEach(TransactionKind.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Jumlah") {
                AmountField(title: "Nominal", text: $amountText)
                DatePicker("Tanggal", selection: $date, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "id_ID"))
            }

            Section("Rekening") {
                Picker("Rekening", selection: $accountID) {
                    Text("Pilih rekening").tag(Optional<UUID>.none)
                    ForEach(activeAccounts) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                if kind == .transfer {
                    Picker("Tujuan", selection: $destinationID) {
                        Text("Pilih tujuan").tag(Optional<UUID>.none)
                        ForEach(activeAccounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                }
                if kind == .adjustment {
                    Picker("Arah", selection: $adjustmentIncrease) {
                        Text(AdjustmentDirection.decrease.title).tag(false)
                        Text(AdjustmentDirection.increase.title).tag(true)
                    }
                }
            }

            if kind != .transfer {
                Section("Kategori") {
                    Picker("Kategori", selection: $categoryID) {
                        Text("Tanpa kategori").tag(Optional<UUID>.none)
                        ForEach(filteredCategories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    if KeychainService.hasGeminiKey {
                        Button("Minta saran kategori AI") { confirmSendAI = true }
                    }
                    if aiBusy {
                        Text("Meminta saran…")
                            .foregroundStyle(.secondary)
                    }
                    if !aiSuggestion.isEmpty {
                        Text(aiSuggestion)
                            .font(BudgetFont.footnote())
                    }
                    if let aiError {
                        Text(aiError)
                            .font(BudgetFont.footnote())
                            .foregroundStyle(BudgetColor.expenseFallback)
                    }
                }
            }

            Section("Keterangan") {
                TextField("Merchant / penerima", text: $payee)
                TextField("Catatan", text: $note, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            if existing != nil {
                Section {
                    Button("Hapus transaksi", role: .destructive) { showDelete = true }
                }
            }
        }
        .navigationTitle(existing == nil ? "Transaksi baru" : "Edit transaksi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Batal") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(!canSave)
            }
        }
        .onAppear(perform: populate)
        .alert("Hapus transaksi?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive, action: delete)
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Tindakan ini tidak dapat dibatalkan.")
        }
        .alert("Kirim data ke Gemini?", isPresented: $confirmSendAI) {
            Button("Kirim") { Task { await suggestCategory() } }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Penerima, catatan, dan daftar kategori akan dikirim ke layanan Gemini. Saldo dan transaksi lain tidak dikirim.")
        }
    }

    private var filteredCategories: [CategoryItem] {
        categories.filter { category in
            switch kind {
            case .income: category.kind != .expense
            case .expense, .refund: category.kind != .income
            case .adjustment, .transfer: true
            }
        }
    }

    private var parsedAmount: Decimal? {
        CurrencyFormatter.parse(amountText)
    }

    private var canSave: Bool {
        guard let parsedAmount, parsedAmount > 0 else { return false }
        guard accountID != nil else { return false }
        if kind == .transfer {
            return destinationID != nil && destinationID != accountID
        }
        return true
    }

    private func populate() {
        if let existing {
            kind = existing.kind
            amountText = NSDecimalNumber(decimal: existing.amount).stringValue
            date = existing.date
            payee = existing.payee
            note = existing.note
            accountID = existing.account?.id
            destinationID = existing.destinationAccount?.id
            categoryID = existing.category?.id
            adjustmentIncrease = existing.adjustmentIncrease
        } else if accountID == nil {
            accountID = activeAccounts.first?.id
        }
    }

    private func save() {
        guard let parsedAmount else { return }
        let account = activeAccounts.first(where: { $0.id == accountID })
        let destination = activeAccounts.first(where: { $0.id == destinationID })
        let category = categories.first(where: { $0.id == categoryID })
        if let existing {
            existing.kind = kind
            existing.amount = parsedAmount
            existing.date = date
            existing.payee = payee
            existing.note = note
            existing.account = account
            existing.destinationAccount = kind == .transfer ? destination : nil
            existing.category = kind == .transfer ? nil : category
            existing.adjustmentIncrease = adjustmentIncrease
        } else {
            context.insert(
                MoneyTransaction(
                    kind: kind,
                    amount: parsedAmount,
                    date: date,
                    payee: payee,
                    note: note,
                    adjustmentIncrease: adjustmentIncrease,
                    account: account,
                    destinationAccount: kind == .transfer ? destination : nil,
                    category: kind == .transfer ? nil : category
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

    private func suggestCategory() async {
        guard let key = KeychainService.readGeminiKey() else {
            aiError = "Kunci API belum diatur."
            return
        }
        aiBusy = true
        aiError = nil
        defer { aiBusy = false }
        do {
            let names = filteredCategories.map(\.name)
            let text = try await GeminiService.shared.generate(
                apiKey: key,
                prompt: GeminiPromptBuilder.categorize(payee: payee, note: note, categories: names),
                system: GeminiPromptBuilder.system
            )
            aiSuggestion = text
            if let match = filteredCategories.first(where: { text.localizedCaseInsensitiveContains($0.name) }) {
                categoryID = match.id
            }
        } catch {
            aiError = error.localizedDescription
        }
    }
}
