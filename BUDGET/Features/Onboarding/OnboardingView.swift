import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: BudgetSpacing.xl)
                Text("BUDGET")
                    .font(.largeTitle.weight(.semibold))
                    .tracking(1.2)
                    .accessibilityAddTraits(.isHeader)
                Text("Kelola uangmu tanpa membuat aplikasi mengambil alih keputusanmu.")
                    .font(BudgetFont.title())
                    .foregroundStyle(.primary)
                    .padding(.top, BudgetSpacing.sm)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: BudgetSpacing.md) {
                    OnboardingPoint(
                        title: "Data tetap di perangkat",
                        detail: "Catatan keuangan disimpan secara lokal. Tidak ada akun dan tidak ada server milik aplikasi ini."
                    )
                    OnboardingPoint(
                        title: "Tidak ada angka rekaan",
                        detail: "Aplikasi tidak mengisi saldo, gaji, atau transaksi contoh. Semua angka berasal dari kamu."
                    )
                    OnboardingPoint(
                        title: "Gemini AI bersifat opsional",
                        detail: "AI hanya dipakai jika kamu memasukkan kunci API sendiri dan menekan fitur AI."
                    )
                }
                .padding(.top, BudgetSpacing.xxl)

                Spacer()

                VStack(spacing: BudgetSpacing.sm) {
                    Button(action: onFinish) {
                        Text("Mulai")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Button("Lewati", action: onFinish)
                        .frame(maxWidth: .infinity)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, BudgetSpacing.lg)
            .padding(.bottom, BudgetSpacing.lg)
            .background(Color(.systemBackground))
        }
    }
}

private struct OnboardingPoint: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BudgetFont.headline())
            Text(detail)
                .font(BudgetFont.body())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
