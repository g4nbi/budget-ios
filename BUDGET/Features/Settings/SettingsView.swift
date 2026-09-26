import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsRows: [FinanceSettings]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                Section("Bulan keuangan") {
                    NavigationLink("Awal siklus") {
                        FinanceMonthSettingsView()
                    }
                    if let settings = settingsRows.first {
                        Text("Saat ini dimulai tanggal \(settings.financeMonthStartDay)")
                            .font(BudgetFont.footnote())
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Data") {
                    NavigationLink("Rekening") { AccountListView() }
                    NavigationLink("Kategori") { CategoryListView() }
                    NavigationLink("Pengeluaran wajib") { BillListView() }
                    NavigationLink("Pemasukan diharapkan") { ExpectedIncomeListView() }
                    NavigationLink("Uang disisihkan") { ReservationListView() }
                    NavigationLink("Transaksi berulang") { RecurringListView() }
                    NavigationLink("Ekspor & cadangan") { ExportView() }
                    NavigationLink("Hapus semua data") { DeleteAllDataView() }
                }
                Section("Gemini AI") {
                    NavigationLink("Kunci API & uji koneksi") { GeminiSettingsView() }
                    NavigationLink("Tanya data lokal") { GeminiAskView() }
                }
                Section("Privasi") {
                    Text("Data keuangan disimpan di perangkat ini melalui SwiftData. Tidak ada akun, pelacakan, atau iklan. Gemini adalah satu-satunya layanan luar, dan hanya dipakai jika kamu memintanya.")
                        .font(BudgetFont.footnote())
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Pengaturan")
            .onAppear {
                if settingsRows.isEmpty {
                    context.insert(FinanceSettings())
                    try? context.save()
                }
            }
        }
    }
}

struct FinanceMonthSettingsView: View {
    @Query private var settingsRows: [FinanceSettings]
    @Environment(\.modelContext) private var context
    @State private var startDay = 1

    var body: some View {
        Form {
            Section {
                Stepper(value: $startDay, in: 1...31) {
                    Text("Mulai tanggal \(startDay)")
                }
            } footer: {
                Text("Jika suatu bulan tidak memiliki tanggal tersebut, siklus memakai hari terakhir bulan itu. Ini pengaturan kalender, bukan data keuangan.")
            }
            if let preview = previewText {
                Section("Pratinjau periode berjalan") {
                    Text(preview)
                }
            }
        }
        .navigationTitle("Bulan keuangan")
        .onAppear {
            startDay = settingsRows.first?.financeMonthStartDay ?? 1
        }
        .onChange(of: startDay) { _, newValue in
            let settings = settingsRows.first ?? {
                let created = FinanceSettings()
                context.insert(created)
                return created
            }()
            settings.financeMonthStartDay = newValue
            try? context.save()
        }
    }

    private var previewText: String? {
        let period = FinanceMonth.period(containing: .now, startDay: startDay)
        return "\(DateFormatting.long(period.start)) – \(DateFormatting.long(period.end))"
    }
}
