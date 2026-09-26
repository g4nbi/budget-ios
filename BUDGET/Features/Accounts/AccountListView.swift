import SwiftUI
import SwiftData

struct AccountListView: View {
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query private var transactions: [MoneyTransaction]
    @State private var showEditor = false
    @State private var editing: Account?

    private var active: [Account] { accounts.filter { !$0.isArchived } }
    private var archived: [Account] { accounts.filter(\.isArchived) }

    var body: some View {
        List {
            if accounts.isEmpty {
                EmptyStateView(
                    title: "Belum ada rekening",
                    message: "Tambahkan tunai, bank, dompet digital, atau tabungan. Saldo awal diisi olehmu.",
                    systemImage: "wallet.pass",
                    actionTitle: "Tambah rekening",
                    action: { showEditor = true }
                )
            } else {
                Section("Aktif") {
                    ForEach(active) { account in
                        accountRow(account)
                    }
                }
                if !archived.isEmpty {
                    Section("Diarsipkan") {
                        ForEach(archived) { account in
                            accountRow(account)
                        }
                    }
                }
            }
        }
        .navigationTitle("Rekening")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Tambah rekening")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                AccountEditorView(existing: editing)
            }
        }
    }

    private func accountRow(_ account: Account) -> some View {
        let value = MoneyCalculator.balance(
            account: SnapshotFactory.accounts([account])[0],
            transactions: SnapshotFactory.transactions(transactions)
        )
        return Button {
            editing = account
            showEditor = true
        } label: {
            HStack(spacing: BudgetSpacing.sm) {
                AccountGlyph(systemImage: account.iconName, hex: account.colorHex)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .foregroundStyle(.primary)
                    Text(account.isSavings ? "Ditandai sebagai tabungan" : account.kind.title)
                        .font(BudgetFont.caption())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(CurrencyFormatter.string(from: value))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
        }
        .accessibilityLabel("\(account.name), \(CurrencyFormatter.string(from: value))")
    }
}

struct AccountEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existing: Account?

    @State private var name = ""
    @State private var kind: AccountKind = .cash
    @State private var openingText = ""
    @State private var isSavings = false
    @State private var tint: AccountTint = .stone
    @State private var note = ""
    @State private var isArchived = false
    @State private var showDelete = false

    var body: some View {
        Form {
            Section("Rekening") {
                TextField("Nama", text: $name)
                Picker("Jenis", selection: $kind) {
                    ForEach(AccountKind.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .onChange(of: kind) { _, newValue in
                    if existing == nil {
                        isSavings = newValue.treatsAsSavingsByDefault
                    }
                }
                AmountField(title: "Saldo awal", text: $openingText)
                Toggle("Tandai sebagai tabungan", isOn: $isSavings)
            }
            Section("Tampilan") {
                Picker("Warna", selection: $tint) {
                    ForEach(AccountTint.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                TextField("Catatan (opsional)", text: $note)
            }
            if existing != nil {
                Section {
                    Toggle("Arsipkan", isOn: $isArchived)
                    Button("Hapus rekening", role: .destructive) { showDelete = true }
                } footer: {
                    Text("Mengarsipkan menyembunyikan rekening dari perhitungan aktif. Menghapus tidak menghapus transaksi yang sudah tercatat, tetapi hubungan rekening akan dilepas.")
                }
            }
        }
        .navigationTitle(existing == nil ? "Rekening baru" : "Edit rekening")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Batal") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || openingAmount == nil)
            }
        }
        .onAppear(perform: populate)
        .alert("Hapus rekening?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive, action: delete)
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Tindakan ini tidak dapat dibatalkan.")
        }
    }

    private var openingAmount: Decimal? {
        if openingText.trimmingCharacters(in: .whitespaces).isEmpty { return 0 }
        return CurrencyFormatter.parse(openingText)
    }

    private func populate() {
        guard let existing else {
            isSavings = kind.treatsAsSavingsByDefault
            return
        }
        name = existing.name
        kind = existing.kind
        openingText = NSDecimalNumber(decimal: existing.openingBalance).stringValue
        isSavings = existing.isSavings
        tint = AccountTint.allCases.first(where: { $0.hex == existing.colorHex }) ?? .stone
        note = existing.note
        isArchived = existing.isArchived
    }

    private func save() {
        guard let openingAmount else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing {
            existing.name = trimmed
            existing.kind = kind
            existing.openingBalance = openingAmount
            existing.isSavings = isSavings
            existing.colorHex = tint.hex
            existing.iconName = kind.systemImage
            existing.note = note
            existing.isArchived = isArchived
        } else {
            context.insert(
                Account(
                    name: trimmed,
                    kind: kind,
                    openingBalance: openingAmount,
                    isSavings: isSavings,
                    colorHex: tint.hex,
                    iconName: kind.systemImage,
                    note: note
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
