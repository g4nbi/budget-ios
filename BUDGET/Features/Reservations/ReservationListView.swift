import SwiftUI
import SwiftData

struct ReservationListView: View {
    @Query(sort: \ReservedMoney.createdAt, order: .reverse) private var items: [ReservedMoney]
    @State private var showEditor = false
    @State private var editing: ReservedMoney?

    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateView(
                    title: "Belum ada uang disisihkan",
                    message: "Sisihkan sebagian uang untuk keperluan tertentu. Jumlah ini mengurangi estimasi dana fleksibel.",
                    systemImage: "bookmark",
                    actionTitle: "Tambah",
                    action: { showEditor = true }
                )
            } else {
                ForEach(items) { item in
                    Button {
                        editing = item
                        showEditor = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).foregroundStyle(.primary)
                                if let account = item.account {
                                    Text(account.name)
                                        .font(BudgetFont.caption())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(CurrencyFormatter.string(from: item.amount))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Uang disisihkan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Sisihkan uang")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { ReservationEditorView(existing: editing) }
        }
    }
}

struct ReservationEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    var existing: ReservedMoney?

    @State private var name = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var accountID: UUID?
    @State private var showDelete = false

    var body: some View {
        Form {
            TextField("Untuk apa", text: $name)
            AmountField(title: "Jumlah", text: $amountText)
            Picker("Rekening (opsional)", selection: $accountID) {
                Text("Tidak dipilih").tag(Optional<UUID>.none)
                ForEach(accounts.filter { !$0.isArchived }) { account in
                    Text(account.name).tag(Optional(account.id))
                }
            }
            TextField("Catatan", text: $note)
            if existing != nil {
                Button("Hapus", role: .destructive) { showDelete = true }
            }
        }
        .navigationTitle("Uang disisihkan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || CurrencyFormatter.parse(amountText) == nil)
            }
        }
        .onAppear {
            guard let existing else { return }
            name = existing.name
            amountText = NSDecimalNumber(decimal: existing.amount).stringValue
            note = existing.note
            accountID = existing.account?.id
        }
        .alert("Hapus?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive) {
                if let existing { context.delete(existing); try? context.save() }
                dismiss()
            }
            Button("Batal", role: .cancel) {}
        }
    }

    private func save() {
        guard let amount = CurrencyFormatter.parse(amountText) else { return }
        let account = accounts.first(where: { $0.id == accountID })
        if let existing {
            existing.name = name
            existing.amount = amount
            existing.note = note
            existing.account = account
        } else {
            context.insert(ReservedMoney(name: name, amount: amount, note: note, account: account))
        }
        try? context.save()
        dismiss()
    }
}
