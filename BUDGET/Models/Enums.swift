import Foundation

enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case cash
    case bank
    case ewallet
    case savings
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: "Tunai"
        case .bank: "Rekening bank"
        case .ewallet: "Dompet digital"
        case .savings: "Tabungan"
        case .custom: "Lainnya"
        }
    }

    var systemImage: String {
        switch self {
        case .cash: "banknote"
        case .bank: "building.columns"
        case .ewallet: "iphone"
        case .savings: "archivebox"
        case .custom: "wallet.pass"
        }
    }

    var treatsAsSavingsByDefault: Bool {
        self == .savings
    }
}

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case income
    case expense
    case transfer
    case refund
    case adjustment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: "Pemasukan"
        case .expense: "Pengeluaran"
        case .transfer: "Transfer"
        case .refund: "Pengembalian"
        case .adjustment: "Penyesuaian"
        }
    }

    var systemImage: String {
        switch self {
        case .income: "arrow.down.left"
        case .expense: "arrow.up.right"
        case .transfer: "arrow.left.arrow.right"
        case .refund: "arrow.uturn.left"
        case .adjustment: "plus.forwardslash.minus"
        }
    }
}

enum AdjustmentDirection: String, Codable, CaseIterable {
    case increase
    case decrease

    var title: String {
        switch self {
        case .increase: "Tambah saldo"
        case .decrease: "Kurangi saldo"
        }
    }
}

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: "Mingguan"
        case .monthly: "Bulanan"
        case .yearly: "Tahunan"
        }
    }
}

enum CategoryKind: String, Codable, CaseIterable {
    case expense
    case income
    case both

    var title: String {
        switch self {
        case .expense: "Pengeluaran"
        case .income: "Pemasukan"
        case .both: "Keduanya"
        }
    }
}

enum AccountTint: String, Codable, CaseIterable, Identifiable {
    case stone, olive, teal, navy, rust, plum, sand, slate

    var id: String { rawValue }

    var hex: String {
        switch self {
        case .stone: "6B6A66"
        case .olive: "5C6B4A"
        case .teal: "3E6B62"
        case .navy: "3B4C63"
        case .rust: "8A4A38"
        case .plum: "6A4B5E"
        case .sand: "8A7354"
        case .slate: "4F5A63"
        }
    }

    var title: String {
        switch self {
        case .stone: "Batu"
        case .olive: "Zaitun"
        case .teal: "Teal"
        case .navy: "Navy"
        case .rust: "Karat"
        case .plum: "Plum"
        case .sand: "Pasir"
        case .slate: "Slate"
        }
    }
}
