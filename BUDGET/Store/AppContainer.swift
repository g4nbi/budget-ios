import Foundation
import SwiftData

enum AppContainer {
    static func make() throws -> ModelContainer {
        let schema = Schema([
            Account.self,
            CategoryItem.self,
            MoneyTransaction.self,
            BudgetPlan.self,
            FinancialGoal.self,
            RecurringRule.self,
            ReservedMoney.self,
            UpcomingBill.self,
            ExpectedIncome.self,
            FinanceSettings.self
        ])
        let configuration = ModelConfiguration(
            "budget-local",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func preview() -> ModelContainer {
        let schema = Schema([
            Account.self,
            CategoryItem.self,
            MoneyTransaction.self,
            BudgetPlan.self,
            FinancialGoal.self,
            RecurringRule.self,
            ReservedMoney.self,
            UpcomingBill.self,
            ExpectedIncome.self,
            FinanceSettings.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        // Preview container is empty on purpose: no invented financial data.
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
