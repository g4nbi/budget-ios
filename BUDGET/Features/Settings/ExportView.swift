import SwiftUI
import SwiftData

struct ExportView: View {
    @Query private var accounts: [Account]
    @Query private var categories: [CategoryItem]
    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @Query private var budgets: [BudgetPlan]
    @Query private var goals: [FinancialGoal]
    @Query private var recurring: [RecurringRule]
    @Query private var reservations: [ReservedMoney]
    @Query private var bills: [UpcomingBill]
    @Query private var expected: [ExpectedIncome]
    @Query private var settingsRows: [FinanceSettings]

    @State private var sharePayload: SharePayload?

    var body: some View {
        List {
            Section {
                Button("Ekspor cadangan JSON") { exportJSON() }
                Button("Ekspor transaksi CSV") { exportCSV() }
            } footer: {
                Text("Berkas tetap di perangkat dan dibagikan lewat lembar bagikan iOS. Tidak ada unggahan otomatis.")
            }
        }
        .navigationTitle("Ekspor")
        .sheet(item: $sharePayload) { payload in
            ActivityView(url: payload.url)
        }
    }

    private func exportJSON() {
        let backup = ExportService.makeBackup(
            settings: settingsRows.first,
            accounts: accounts,
            categories: categories,
            transactions: transactions,
            budgets: budgets,
            goals: goals,
            recurring: recurring,
            reservations: reservations,
            bills: bills,
            expectedIncome: expected
        )
        do {
            let data = try ExportService.jsonData(from: backup)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("budget-cadangan.json")
            try data.write(to: url, options: .atomic)
            sharePayload = SharePayload(url: url)
        } catch {
            return
        }
    }

    private func exportCSV() {
        let csv = ExportService.csv(from: transactions)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("budget-transaksi.csv")
        do {
            try csv.data(using: .utf8)?.write(to: url, options: .atomic)
            sharePayload = SharePayload(url: url)
        } catch {
            return
        }
    }
}

struct SharePayload: Identifiable {
    var id: String { url.absoluteString }
    var url: URL
}

struct ActivityView: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
