import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [FinanceSettings]
    @Query private var categories: [CategoryItem]
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    markOnboardingDone()
                }
            } else {
                MainTabView()
            }
        }
        .onAppear {
            CategoryCatalog.seedIfNeeded(context: context)
        }
    }

    private var showOnboarding: Bool {
        if hasSeenOnboarding { return false }
        return !(settings.first?.hasCompletedOnboarding ?? false)
    }

    private func markOnboardingDone() {
        if let first = settings.first {
            first.hasCompletedOnboarding = true
        } else {
            let created = FinanceSettings(hasCompletedOnboarding: true)
            context.insert(created)
        }
        hasSeenOnboarding = true
        try? context.save()
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onAddTransaction: { showAddTransaction = true })
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
                .tag(AppTab.home)

            TransactionListView()
                .tabItem { Label(AppTab.transactions.title, systemImage: AppTab.transactions.systemImage) }
                .tag(AppTab.transactions)

            BudgetListView()
                .tabItem { Label(AppTab.budgets.title, systemImage: AppTab.budgets.systemImage) }
                .tag(AppTab.budgets)

            GoalListView()
                .tabItem { Label(AppTab.goals.title, systemImage: AppTab.goals.systemImage) }
                .tag(AppTab.goals)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.systemImage) }
                .tag(AppTab.settings)
        }
        .sheet(isPresented: $showAddTransaction) {
            NavigationStack {
                TransactionEditorView(existing: nil)
            }
        }
    }
}

enum AppTab: Hashable {
    case home, transactions, budgets, goals, settings

    var title: String {
        switch self {
        case .home: "Ringkasan"
        case .transactions: "Transaksi"
        case .budgets: "Anggaran"
        case .goals: "Tujuan"
        case .settings: "Pengaturan"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "square.grid.2x2"
        case .transactions: "list.bullet"
        case .budgets: "chart.bar"
        case .goals: "flag"
        case .settings: "gearshape"
        }
    }
}
