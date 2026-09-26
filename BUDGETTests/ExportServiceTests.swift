import XCTest
@testable import BUDGET

final class ExportServiceTests: XCTestCase {
    func testCSVContainsHeaderAndEscapes() {
        let account = Account(name: "Dompet", kind: .cash, openingBalance: 0)
        let category = CategoryItem(name: "Makan", iconName: "fork.knife", isSystem: true)
        let item = MoneyTransaction(
            kind: .expense,
            amount: 25_000,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            payee: "Warung, Bu Ani",
            note: "Nasi",
            account: account,
            category: category
        )
        let csv = ExportService.csv(from: [item])
        XCTAssertTrue(csv.contains("tanggal,jenis,jumlah"))
        XCTAssertTrue(csv.contains("Pengeluaran"))
        XCTAssertTrue(csv.contains("\"Warung, Bu Ani\""))
        XCTAssertTrue(csv.contains("25000"))
    }

    func testJSONBackupRoundTripShape() {
        let settings = FinanceSettings(financeMonthStartDay: 25)
        let account = Account(name: "Bank", kind: .bank, openingBalance: 0)
        let backup = ExportService.makeBackup(
            settings: settings,
            accounts: [account],
            categories: [],
            transactions: [],
            budgets: [],
            goals: [],
            recurring: [],
            reservations: [],
            bills: [],
            expectedIncome: []
        )
        XCTAssertEqual(backup.financeMonthStartDay, 25)
        XCTAssertEqual(backup.accounts.count, 1)
        XCTAssertNoThrow(try ExportService.jsonData(from: backup))
    }
}
