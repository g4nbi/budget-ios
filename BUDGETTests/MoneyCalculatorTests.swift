import XCTest
@testable import BUDGET

final class MoneyCalculatorTests: XCTestCase {
    private let cashID = UUID()
    private let bankID = UUID()
    private let saveID = UUID()
    private let foodID = UUID()

    private func account(_ id: UUID, name: String, opening: Decimal, savings: Bool = false, archived: Bool = false) -> LedgerAccount {
        LedgerAccount(id: id, name: name, openingBalance: opening, isSavings: savings, isArchived: archived)
    }

    private func tx(
        kind: TransactionKind,
        amount: Decimal,
        account: UUID?,
        destination: UUID? = nil,
        category: UUID? = nil,
        date: Date = Date(),
        increase: Bool = true
    ) -> LedgerTransaction {
        LedgerTransaction(
            id: UUID(),
            kind: kind,
            amount: amount,
            date: date,
            accountID: account,
            destinationAccountID: destination,
            categoryID: category,
            adjustmentIncrease: increase
        )
    }

    func testIncomeAndExpenseBalance() {
        let cash = account(cashID, name: "Dompet", opening: 50_000)
        let items = [
            tx(kind: .income, amount: 25_000, account: cashID),
            tx(kind: .expense, amount: 10_000, account: cashID)
        ]
        XCTAssertEqual(MoneyCalculator.balance(account: cash, transactions: items), 65_000)
    }

    func testTransferMovesMoneyBetweenAccounts() {
        let cash = account(cashID, name: "Dompet", opening: 40_000)
        let bank = account(bankID, name: "Bank", opening: 10_000)
        let items = [tx(kind: .transfer, amount: 15_000, account: cashID, destination: bankID)]
        XCTAssertEqual(MoneyCalculator.balance(account: cash, transactions: items), 25_000)
        XCTAssertEqual(MoneyCalculator.balance(account: bank, transactions: items), 25_000)
    }

    func testRefundAddsToAccount() {
        let cash = account(cashID, name: "Dompet", opening: 0)
        let items = [
            tx(kind: .expense, amount: 20_000, account: cashID),
            tx(kind: .refund, amount: 5_000, account: cashID)
        ]
        XCTAssertEqual(MoneyCalculator.balance(account: cash, transactions: items), -15_000)
    }

    func testAdjustmentIncreaseAndDecrease() {
        let cash = account(cashID, name: "Dompet", opening: 10_000)
        let items = [
            tx(kind: .adjustment, amount: 2_000, account: cashID, increase: true),
            tx(kind: .adjustment, amount: 3_000, account: cashID, increase: false)
        ]
        XCTAssertEqual(MoneyCalculator.balance(account: cash, transactions: items), 9_000)
    }

    func testNegativeBalanceAllowed() {
        let cash = account(cashID, name: "Dompet", opening: 1_000)
        let items = [tx(kind: .expense, amount: 5_000, account: cashID)]
        XCTAssertEqual(MoneyCalculator.balance(account: cash, transactions: items), -4_000)
    }

    func testSavingsExcludedFromLiquidMoney() {
        let cash = account(cashID, name: "Dompet", opening: 20_000)
        let save = account(saveID, name: "Tabungan", opening: 100_000, savings: true)
        let liquid = MoneyCalculator.liquidMoney(accounts: [cash, save], transactions: [])
        XCTAssertEqual(liquid, 20_000)
        XCTAssertEqual(MoneyCalculator.savingsBalances(accounts: [cash, save], transactions: []), 100_000)
    }

    func testArchivedAccountsIgnoredInBalancesMap() {
        let archived = account(cashID, name: "Lama", opening: 9_000, archived: true)
        let map = MoneyCalculator.balances(accounts: [archived], transactions: [])
        XCTAssertTrue(map.isEmpty)
    }

    func testBudgetProgressAndRemaining() {
        XCTAssertEqual(MoneyCalculator.budgetRemaining(limit: 100_000, spent: 25_000), 75_000)
        XCTAssertEqual(MoneyCalculator.budgetProgress(limit: 100_000, spent: 25_000), 0.25, accuracy: 0.0001)
        XCTAssertEqual(MoneyCalculator.budgetProgress(limit: 0, spent: 0), 0)
        XCTAssertEqual(MoneyCalculator.budgetProgress(limit: 0, spent: 10), 1)
    }

    func testExpenseByCategoryRespectsPeriod() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31))!
        let period = FinancePeriod(start: start, end: end)
        let inside = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!
        let outside = calendar.date(from: DateComponents(year: 2026, month: 2, day: 10))!
        let items = [
            tx(kind: .expense, amount: 25_000, account: cashID, category: foodID, date: inside),
            tx(kind: .expense, amount: 40_000, account: cashID, category: foodID, date: outside),
            tx(kind: .income, amount: 10_000, account: cashID, category: foodID, date: inside)
        ]
        let grouped = MoneyCalculator.expenseByCategory(transactions: items, period: period)
        XCTAssertEqual(grouped[foodID], 25_000)
    }

    func testSpendableFormula() {
        let cash = account(cashID, name: "Dompet", opening: 100_000)
        let save = account(saveID, name: "Tabungan", opening: 500_000, savings: true)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let period = FinancePeriod(start: start, end: end)
        let estimate = MoneyCalculator.spendable(
            accounts: [cash, save],
            transactions: [],
            expectedIncomeRemaining: 50_000,
            upcomingBillsRemaining: 20_000,
            savingsStillToSetAside: 10_000,
            reserved: 20_000,
            period: period,
            now: now,
            calendar: calendar,
            hasAnyAccount: true
        )
        XCTAssertEqual(estimate.flexibleMoney, 100_000)
        XCTAssertEqual(estimate.daysRemaining, 10)
        XCTAssertEqual(estimate.dailyEstimate, 10_000)
        XCTAssertTrue(estimate.missing.isEmpty)
    }

    func testSpendableMissingAccount() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 4, day: 30))!
        let estimate = MoneyCalculator.spendable(
            accounts: [],
            transactions: [],
            expectedIncomeRemaining: 0,
            upcomingBillsRemaining: 0,
            savingsStillToSetAside: 0,
            reserved: 0,
            period: FinancePeriod(start: start, end: end),
            now: start,
            calendar: calendar,
            hasAnyAccount: false
        )
        XCTAssertFalse(estimate.missing.isEmpty)
    }

    func testZeroDaysRemaining() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 2))!
        let estimate = MoneyCalculator.spendable(
            accounts: [account(cashID, name: "Dompet", opening: 10_000)],
            transactions: [],
            expectedIncomeRemaining: 0,
            upcomingBillsRemaining: 0,
            savingsStillToSetAside: 0,
            reserved: 0,
            period: FinancePeriod(start: start, end: end),
            now: now,
            calendar: calendar,
            hasAnyAccount: true
        )
        XCTAssertEqual(estimate.daysRemaining, 0)
        XCTAssertNil(estimate.dailyEstimate)
    }

    func testReservedMoneySubtracted() {
        let cash = account(cashID, name: "Dompet", opening: 80_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 5, day: 8))!
        let estimate = MoneyCalculator.spendable(
            accounts: [cash],
            transactions: [],
            expectedIncomeRemaining: 0,
            upcomingBillsRemaining: 0,
            savingsStillToSetAside: 0,
            reserved: 16_000,
            period: FinancePeriod(start: start, end: end),
            now: start,
            calendar: calendar,
            hasAnyAccount: true
        )
        XCTAssertEqual(estimate.flexibleMoney, 64_000)
        XCTAssertEqual(estimate.dailyEstimate, 8_000)
    }

    func testTotalsIgnoreOppositeKind() {
        let items = [
            tx(kind: .expense, amount: 7_000, account: cashID),
            tx(kind: .income, amount: 3_000, account: cashID)
        ]
        XCTAssertEqual(MoneyCalculator.total(of: .expense, in: items, period: nil), 7_000)
        XCTAssertEqual(MoneyCalculator.total(of: .income, in: items, period: nil), 3_000)
    }

    func testMultipleAccountsCombinedLiquid() {
        let a = account(cashID, name: "Tunai", opening: 5_000)
        let b = account(bankID, name: "Bank", opening: 15_000)
        let items = [
            tx(kind: .expense, amount: 2_000, account: cashID),
            tx(kind: .income, amount: 4_000, account: bankID)
        ]
        XCTAssertEqual(MoneyCalculator.liquidMoney(accounts: [a, b], transactions: items), 22_000)
    }

    func testRecurrenceIncrement() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let week = MoneyCalculator.incrementRecurrence(from: date, frequency: .weekly, calendar: calendar)
        let month = MoneyCalculator.incrementRecurrence(from: date, frequency: .monthly, calendar: calendar)
        let year = MoneyCalculator.incrementRecurrence(from: date, frequency: .yearly, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: week), 22)
        XCTAssertEqual(calendar.component(.month, from: month), 2)
        XCTAssertEqual(calendar.component(.year, from: year), 2027)
    }
}
