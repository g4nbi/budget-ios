import SwiftUI
import SwiftData

struct DeleteAllDataView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query private var categories: [CategoryItem]
    @Query private var transactions: [MoneyTransaction]
    @Query private var budgets: [BudgetPlan]
    @Query private var goals: [FinancialGoal]
    @Query private var recurring: [RecurringRule]
    @Query private var reservations: [ReservedMoney]
    @Query private var bills: [UpcomingBill]
    @Query private var expected: [ExpectedIncome]
    @Query private var settingsRows: [FinanceSettings]

    @State private var typed = ""
    @State private var alsoRemoveKey = false
    @State private var doneMessage: String?

    var body: some View {
        Form {
            Section {
                Text("Ini menghapus rekening, transaksi, anggaran, tujuan, aturan berulang, uang disisihkan, tagihan, pemasukan diharapkan, dan pengaturan keuangan di perangkat ini. Tidak dapat dibatalkan.")
                    .foregroundStyle(.primary)
            }
            Section {
                TextField("Ketik HAPUS", text: $typed)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Ketik HAPUS untuk mengonfirmasi")
                Toggle("Hapus juga kunci API Gemini", isOn: $alsoRemoveKey)
                Button("Hapus semua data", role: .destructive, action: wipe)
                    .disabled(typed != "HAPUS")
            } footer: {
                Text("Kunci API Gemini tersimpan di Keychain, terpisah dari SwiftData. Ia tidak ikut terhapus kecuali kamu mengaktifkan opsi di atas.")
            }
            if let doneMessage {
                Section {
                    Text(doneMessage)
                }
            }
        }
        .navigationTitle("Hapus data")
    }

    private func wipe() {
        guard typed == "HAPUS" else { return }
        delete(accounts)
        delete(transactions)
        delete(budgets)
        delete(goals)
        delete(recurring)
        delete(reservations)
        delete(bills)
        delete(expected)
        for category in categories where !category.isSystem {
            context.delete(category)
        }
        if let settings = settingsRows.first {
            settings.financeMonthStartDay = 1
            settings.hasCompletedOnboarding = true
        }
        if alsoRemoveKey {
            KeychainService.deleteGeminiKey()
        }
        try? context.save()
        CategoryCatalog.seedIfNeeded(context: context)
        typed = ""
        doneMessage = alsoRemoveKey
            ? "Data keuangan dan kunci API sudah dihapus."
            : "Data keuangan sudah dihapus. Kunci API Gemini tetap disimpan."
    }

    private func delete<T: PersistentModel>(_ items: [T]) {
        for item in items {
            context.delete(item)
        }
    }
}
