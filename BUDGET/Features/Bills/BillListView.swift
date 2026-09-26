import SwiftUI
import SwiftData

struct BillListView: View {
    @Query(sort: \UpcomingBill.dueDate) private var bills: [UpcomingBill]
    @State private var showEditor = false
    @State private var editing: UpcomingBill?

    var body: some View {
        List {
            if bills.isEmpty {
                EmptyStateView(
                    title: "Belum ada pengeluaran wajib",
                    message: "Tambahkan tagihan atau pembayaran yang harus disiapkan. Aplikasi tidak mengarang tagihan.",
                    systemImage: "doc.text",
                    actionTitle: "Tambah",
                    action: { showEditor = true }
                )
            } else {
                ForEach(bills) { bill in
                    Button {
                        editing = bill
                        showEditor = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bill.name).foregroundStyle(.primary)
                                Text(DateFormatting.string(bill.dueDate))
                                    .font(BudgetFont.caption())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(CurrencyFormatter.string(from: bill.amount))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                                if bill.isSettled {
                                    StatusPill(text: "Selesai", tone: .success)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Pengeluaran wajib")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Tambah pengeluaran wajib")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { BillEditorView(existing: editing) }
        }
    }
}

struct BillEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    var existing: UpcomingBill?

    @State private var name = ""
    @State private var amountText = ""
    @State private var dueDate = Date()
    @State private var note = ""
    @State private var isSettled = false
    @State private var accountID: UUID?
    @State private var categoryID: UUID?
    @State private var showDelete = false

    var body: some View {
        Form {
            Section {
                TextField("Nama", text: $name)
                AmountField(title: "Jumlah", text: $amountText)
                DatePicker("Jatuh tempo", selection: $dueDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "id_ID"))
                Picker("Rekening (opsional)", selection: $accountID) {
                    Text("Tidak dipilih").tag(Optional<UUID>.none)
                    ForEach(accounts.filter { !$0.isArchived }) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                Picker("Kategori (opsional)", selection: $categoryID) {
                    Text("Tidak dipilih").tag(Optional<UUID>.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                Toggle("Sudah diselesaikan", isOn: $isSettled)
                TextField("Catatan", text: $note)
            } footer: {
                Text("Item ini hanya rencana. Ia tidak menjadi transaksi sebelum kamu mencatatnya sendiri.")
            }
            if existing != nil {
                Button("Hapus", role: .destructive) { showDelete = true }
            }
        }
        .navigationTitle(existing == nil ? "Pengeluaran wajib" : "Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Batal") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Simpan", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || CurrencyFormatter.parse(amountText) == nil)
            }
        }
        .onAppear(perform: populate)
        .alert("Hapus item ini?", isPresented: $showDelete) {
            Button("Hapus", role: .destructive, action: delete)
            Button("Batal", role: .cancel) {}
        }
    }

    private func populate() {
        guard let existing else { return }
        name = existing.name
        amountText = NSDecimalNumber(decimal: existing.amount).stringValue
        dueDate = existing.dueDate
        note = existing.note
        isSettled = existing.isSettled
        accountID = existing.account?.id
        categoryID = existing.category?.id
    }

    private func save() {
        guard let amount = CurrencyFormatter.parse(amountText) else { return }
        let account = accounts.first(where: { $0.id == accountID })
        let category = categories.first(where: { $0.id == categoryID })
        if let existing {
            existing.name = name
            existing.amount = amount
            existing.dueDate = dueDate
            existing.note = note
            existing.isSettled = isSettled
            existing.account = account
            existing.category = category
        } else {
            context.insert(
                UpcomingBill(
                    name: name, amount: amount, dueDate: dueDate, note: note,
                    isSettled: isSettled, account: account, category: category
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

struct ExpectedIncomeListView: View {
    @Query(sort: \ExpectedIncome.expectedDate) private var items: [ExpectedIncome]
    @State private var showEditor = false
    @State private var editing: ExpectedIncome?

    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateView(
                    title: "Belum ada pemasukan diharapkan",
                    message: "Tambahkan gaji atau pemasukan lain yang masih kamu nantikan pada periode ini.",
                    systemImage: "arrow.down.left",
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
                                Text(DateFormatting.string(item.expectedDate))
                                    .font(BudgetFont.caption())
                                    .foregroundStyle(.secondary)
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
        .navigationTitle("Pemasukan diharapkan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Tambah pemasukan diharapkan")
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { ExpectedIncomeEditorView(existing: editing) }
        }
    }
}

struct ExpectedIncomeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    var existing: ExpectedIncome?

    @State private var name = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var isReceived = false
    @State private var accountID: UUID?
    @State private var showDelete = false

    var body: some View {
        Form {
            TextField("Nama", text: $name)
            AmountField(title: "Jumlah", text: $amountText)
            DatePicker("Perkiraan tanggal", selection: $date, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "id_ID"))
            Picker("Rekening (opsional)", selection: $accountID) {
                Text("Tidak dipilih").tag(Optional<UUID>.none)
                ForEach(accounts.filter { !$0.isArchived }) { account in
                    Text(account.name).tag(Optional(account.id))
                }
            }
            Toggle("Sudah diterima", isOn: $isReceived)
            TextField("Catatan", text: $note)
            if existing != nil {
                Button("Hapus", role: .destructive) { showDelete = true }
            }
        }
        .navigationTitle("Pemasukan diharapkan")
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
            date = existing.expectedDate
            note = existing.note
            isReceived = existing.isReceived
            accountID = existing.account?.id
        }
        .alert("Hapus item ini?", isPresented: $showDelete) {
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
            existing.expectedDate = date
            existing.note = note
            existing.isReceived = isReceived
            existing.account = account
        } else {
            context.insert(
                ExpectedIncome(
                    name: name, amount: amount, expectedDate: date,
                    note: note, isReceived: isReceived, account: account
                )
            )
        }
        try? context.save()
        dismiss()
    }
}
