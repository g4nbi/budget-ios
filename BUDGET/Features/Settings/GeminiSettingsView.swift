import SwiftUI

struct GeminiSettingsView: View {
    @State private var keyText = ""
    @State private var hasKey = KeychainService.hasGeminiKey
    @State private var status: String?
    @State private var busy = false

    var body: some View {
        Form {
            Section {
                SecureField("Kunci API Gemini", text: $keyText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(hasKey ? "Ganti kunci" : "Simpan kunci") {
                    let trimmed = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if KeychainService.saveGeminiKey(trimmed) {
                        hasKey = true
                        keyText = ""
                        status = "Kunci disimpan di Keychain perangkat ini."
                    } else {
                        status = "Gagal menyimpan kunci."
                    }
                }
                .disabled(keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if hasKey {
                    Button("Uji koneksi") {
                        Task { await test() }
                    }
                    .disabled(busy)
                    Button("Hapus kunci", role: .destructive) {
                        KeychainService.deleteGeminiKey()
                        hasKey = false
                        status = "Kunci API dihapus dari Keychain."
                    }
                }
            } footer: {
                Text("Kunci tidak pernah disimpan di SwiftData atau kode sumber. Aplikasi tetap berfungsi tanpa Gemini.")
            }
            if busy {
                Section { Text("Menghubungi Gemini\u2026") }
            }
            if let status {
                Section { Text(status) }
            }
        }
        .navigationTitle("Gemini AI")
        .onAppear {
            hasKey = KeychainService.hasGeminiKey
        }
    }

    private func test() async {
        guard let key = KeychainService.readGeminiKey() else {
            status = "Tidak ada kunci."
            return
        }
        busy = true
        defer { busy = false }
        do {
            let reply = try await GeminiService.shared.testConnection(apiKey: key)
            status = "Koneksi berhasil. Balasan: \(reply)"
        } catch {
            status = error.localizedDescription
        }
    }
}

struct GeminiAskView: View {
    @Query private var accounts: [Account]
    @Query private var transactions: [MoneyTransaction]
    @Query private var budgets: [BudgetPlan]
    @Query private var settingsRows: [FinanceSettings]

    @State private var question = ""
    @State private var answer = ""
    @State private var busy = false
    @State private var errorText: String?
    @State private var confirm = false
    @State private var mode: Mode = .ask

    enum Mode: String, CaseIterable, Identifiable {
        case ask, summarize, unusual
        var id: String { rawValue }
        var title: String {
            switch self {
            case .ask: "Tanya"
            case .summarize: "Ringkas pengeluaran"
            case .unusual: "Perubahan tidak biasa"
            }
        }
    }

    var body: some View {
        Form {
            if !KeychainService.hasGeminiKey {
                Section {
                    Text("Atur kunci API Gemini terlebih dahulu. Semua fitur lain tetap bisa dipakai tanpa AI.")
                }
            } else {
                Section {
                    Picker("Jenis bantuan", selection: $mode) {
                        ForEach(Mode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    if mode == .ask {
                        TextField("Pertanyaan", text: $question, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }
                    Button("Jalankan") { confirm = true }
                        .disabled(busy || (mode == .ask && question.trimmingCharacters(in: .whitespaces).isEmpty))
                } footer: {
                    Text("Data ringkas dari perangkat ini akan dikirim ke Gemini hanya setelah kamu mengonfirmasi.")
                }
                if busy {
                    Text("Mengirim ke Gemini\u2026")
                }
                if let errorText {
                    Text(errorText).foregroundStyle(BudgetColor.expenseFallback)
                }
                if !answer.isEmpty {
                    Section("Jawaban") {
                        Text(answer)
                    }
                }
            }
        }
        .navigationTitle("AI")
        .alert("Kirim data ke Gemini?", isPresented: $confirm) {
            Button("Kirim") { Task { await run() } }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Ringkasan rekening, transaksi, dan anggaran lokal akan dikirim ke layanan luar. Jangan lanjutkan jika kamu tidak ingin itu terjadi.")
        }
    }

    private func run() async {
        guard let key = KeychainService.readGeminiKey() else {
            errorText = "Kunci API belum diatur."
            return
        }
        busy = true
        errorText = nil
        defer { busy = false }
        let context = localContext()
        let prompt: String
        switch mode {
        case .ask:
            prompt = GeminiPromptBuilder.question(question, context: context)
        case .summarize:
            prompt = GeminiPromptBuilder.summarize(context: context)
        case .unusual:
            prompt = GeminiPromptBuilder.unusual(context: context)
        }
        do {
            answer = try await GeminiService.shared.generate(
                apiKey: key,
                prompt: prompt,
                system: GeminiPromptBuilder.system
            )
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func localContext() -> String {
        let period = FinanceMonth.period(containing: .now, startDay: settingsRows.first?.financeMonthStartDay ?? 1)
        var lines: [String] = []
        lines.append("Periode: \(DateFormatting.string(period.start)) - \(DateFormatting.string(period.end))")
        for account in accounts where !account.isArchived {
            let value = MoneyCalculator.balance(
                account: SnapshotFactory.accounts([account])[0],
                transactions: SnapshotFactory.transactions(transactions)
            )
            lines.append("Rekening \(account.name) (\(account.isSavings ? "tabungan" : "cair")): \(value)")
        }
        let periodItems = transactions.filter { period.contains($0.date) }
        lines.append("Jumlah transaksi periode ini: \(periodItems.count)")
        for item in periodItems.prefix(40) {
            lines.append("\(DateFormatting.string(item.date)) \(item.kind.title) \(item.amount) \(item.category?.name ?? "-") \(item.payee)")
        }
        for budget in budgets {
            lines.append("Anggaran \(budget.category?.name ?? "-"): batas \(budget.monthlyLimit)")
        }
        return lines.joined(separator: "\n")
    }
}
