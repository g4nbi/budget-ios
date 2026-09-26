import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.sm) {
            Label(title, systemImage: systemImage)
                .font(BudgetFont.headline())
                .foregroundStyle(.primary)
            Text(message)
                .font(BudgetFont.body())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, BudgetSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, BudgetSpacing.md)
        .accessibilityElement(children: .combine)
    }
}

struct EstimateDisclaimer: View {
    var body: some View {
        Text("Ini estimasi, bukan saran keuangan.")
            .font(BudgetFont.caption())
            .foregroundStyle(.secondary)
    }
}

struct AmountField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = "0"

    var body: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.xxs) {
            Text(title)
                .font(BudgetFont.footnote())
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Rp")
                    .font(BudgetFont.headline())
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(.numberPad)
                    .font(BudgetFont.money())
                    .accessibilityLabel(title)
            }
        }
    }
}

struct DestructiveConfirm: View {
    var title: String
    var message: String
    var confirmTitle: String
    var action: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        EmptyView()
            .confirmationDialog(title, isPresented: $isPresented, titleVisibility: .visible) {
                Button(confirmTitle, role: .destructive, action: action)
                Button("Batal", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

struct StatusPill: View {
    var text: String
    var tone: Tone = .neutral

    enum Tone { case neutral, warning, success, danger }

    var body: some View {
        Text(text)
            .font(BudgetFont.caption())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background.opacity(0.16), in: Capsule())
            .foregroundStyle(background)
    }

    private var background: Color {
        switch tone {
        case .neutral: .secondary
        case .warning: BudgetColor.warningFallback
        case .success: BudgetColor.successFallback
        case .danger: BudgetColor.expenseFallback
        }
    }
}

struct AccountGlyph: View {
    var systemImage: String
    var hex: String
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: hex), in: Circle())
            .accessibilityHidden(true)
    }
}
