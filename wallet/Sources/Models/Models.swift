//
//  Models.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

// MARK: - Models
typealias WalletItemModel = SchemaV1.WalletItemModel
typealias WalletTransactionModel = SchemaV1.WalletTransactionModel

public struct WalletItem: Codable, Hashable, Sendable {
    public enum WalletItemType: Int, Codable, Equatable, Sendable {
        case account, expenses
    }

    let id: UUID
    let timestamp: Date
    let type: WalletItemType
    let name: String
    let icon: String
    let currency: Currency
    let balance: Double
    
    init(id: UUID, timestamp: Date, type: WalletItemType, name: String, icon: String, currency: Currency, balance: Double) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.name = name
        self.icon = icon
        self.currency = currency
        self.balance = balance
    }
}

public struct Currency: Codable, Sendable, Hashable {
    let name: String
    let symbol: String
    let code: String
}

extension Currency {
    var fixedSymbol: String {
        switch symbol {
        case "RUB":
            return "₽"
        default:
            return symbol
        }
    }
}

extension Currency {
    static let currencyCodes: [String] = [
        "EUR", //    Euro
        "USD", //    US Dollar
        "JPY", //    Japanese Yen
        "BGN", //    Bulgarian Lev
        "CZK", //    Czech Republic Koruna
        "DKK", //    Danish Krone
        "GBP", //    British Pound Sterling
        "HUF", //    Hungarian Forint
        "PLN", //    Polish Zloty
        "RON", //    Romanian Leu
        "SEK", //    Swedish Krona
        "CHF", //    Swiss Franc
        "ISK", //    Icelandic Króna
        "NOK", //    Norwegian Krone
        "HRK", //    Croatian Kuna
        "RUB", //    Russian Ruble
        "TRY", //    Turkish Lira
        "AUD", //    Australian Dollar
        "BRL", //    Brazilian Real
        "CAD", //    Canadian Dollar
        "CNY", //    Chinese Yuan
        "HKD", //    Hong Kong Dollar
        "IDR", //    Indonesian Rupiah
        "ILS", //    Israeli New Sheqel
        "INR", //    Indian Rupee
        "KRW", //    South Korean Won
        "MXN", //    Mexican Peso
        "MYR", //    Malaysian Ringgit
        "NZD", //    New Zealand Dollar
        "PHP", //    Philippine Peso
        "SGD", //    Singapore Dollar
        "THB", //    Thai Baht
        "ZAR"  //    South African Rand
    ]
    
    static let USD: Self = .init(name: "United States Dollar",
                                 symbol: "$",
                                 code: "USD")
}

public struct WalletTransaction: Codable, Equatable, Sendable, Identifiable {
    public var id = UUID()
    let timestamp: Date
    let currency: Currency
    let amount: Double
    let commentary: String
    /// source.currency to destination.currency rate
    let rate: Double
    
    let source: WalletItem
    let destination: WalletItem
    
    static func canBePerformed(source: WalletItem, destination: WalletItem) -> Bool {
        source.type == .account &&
        (destination.type == .expenses || destination.type == .account) &&
        source.id != destination.id
    }
}

public enum Period: CaseIterable, Sendable {
    case day, week, month
    var representation: LocalizedStringKey {
        switch self {
        case .day: "Period.Day"
        case .week: "Period.Week"
        case .month: "Period.Month"
        }
    }
}

public enum TransactionPeriod: CaseIterable, Sendable {
    case today, yesterday, all
    var representation: LocalizedStringKey {
        switch self {
        case .today: "TransactionPeriod.Today"
        case .yesterday: "TransactionPeriod.Yesterday"
        case .all: "TransactionPeriod.All"
        }
    }
}

public struct ConversionRate: Codable, Sendable, Hashable {
    let source: Currency
    let destination: Currency
    let rate: Double
}

public enum EditType: Sendable {
    case new, edit
}

extension ConversionRate {
    /// base: USD
    /// "EUR": 0.9112801449,
    /// "RUB": 84.2370884976
    
    /// EUR/RUB = EUR/USD * USD/RUB
    /// EUR/RUB = EUR/USD 1/0.9112801449 USD/RUB 84.2370884976 = 92.43819145
    /// target1/target2 = (1 / usd/target1) * usd/target2
    static func rate(for source: Currency, destination: Currency, rates: [ConversionRate]) -> Double {
        guard let dollarToSourceRate = rates.filter({ $0.source.code == "USD" && $0.destination.code == source.code }).first,
              let dollarToDestinationRate = rates.filter({ $0.source.code == "USD" && $0.destination.code == destination.code }).first else { return 1.0 }
        return 1 / dollarToSourceRate.rate * dollarToDestinationRate.rate
    }
}

extension WalletItem {
    static let none: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 0), type: .account, name: "", icon: "", currency: .USD, balance: 0)
    
    // default accounts
    static let defaultAccounts: [Self] = [card, cash]
    static let card: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 1), type: .account, name: "Card", icon: "creditcard", currency: .USD, balance: 0)
    static let cash: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 2), type: .account, name: "Cash", icon: "wallet.bifold", currency: .USD, balance: 0)
    
    // default expences
    static let defaultExpenses: [Self] = [groceries, cafe, transport, shopping, services, entertainments]
    static let groceries: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 1), type: .expenses, name: "Groceries", icon: "carrot", currency: .USD, balance: 0)
    static let cafe: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 2), type: .expenses, name: "Cafe", icon: "fork.knife", currency: .USD, balance: 0)
    static let transport: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 3), type: .expenses, name: "Transport", icon: "bus.fill", currency: .USD, balance: 0)
    static let shopping: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 4), type: .expenses, name: "Shopping", icon: "handbag", currency: .USD, balance: 0)
    static let services: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 5), type: .expenses, name: "Services", icon: "network", currency: .USD, balance: 0)
    static let entertainments: Self = .init(id: UUID(), timestamp: .init(timeIntervalSince1970: 6), type: .expenses, name: "Entertainments", icon: "party.popper", currency: .USD, balance: 0)
}

extension WalletTransaction {
    func representation(for item: WalletItem) -> String {
        let isIncome = (self.destination.id == item.id) && (item.type == .account)
        let amount = self.amount
        let currency = self.currency.fixedSymbol
        let result = String.init(format: "%@ %@ %@", arguments: [
            isIncome ? "+" : "-",
            CurrencyFormatter.formatter.string(from: NSNumber(value: amount)) ?? "",
            currency,
        ])
        return result
    }
}

extension WalletItem {
    static let accountsSystemIconNames: [String] = [
        "creditcard",
        "wallet.bifold",
        "banknote",
        "rublesign.bank.building.fill",
        "eurosign.bank.building.fill",
        "dollarsign.bank.building.fill",
        "dollarsign",
    ]
    static let expensesSystemIconNames: [String] = [
        // home
        "house",
        "house.fill",
        
        // food
        "carrot.fill",
        "fork.knife",
        
        // transport
        "car",
        "bus.fill",
        "airplane",
        
        // healthcare
        "figure.run",
        "cross",
        
        // services
        "network",
        "cellularbars",
        
        // shopping
        "handbag",
        
        // entertainment
        "party.popper",
        "popcorn",
        "movieclapper",
        "birthday.cake",
    ]
}

extension Spending {
    static func calculateSpendings(_ transactions: [WalletTransaction], expenses: [WalletItem], period: Period, rates: [ConversionRate], currency: Currency) -> [Spending] {
        let granularity: Calendar.Component = {
            switch period {
            case .day: .day
            case .week: .weekOfMonth
            case .month: .month
            }
        }()
        let expensesIDs: [UUID: Double] = transactions
            .filter { $0.destination.type == .expenses }
            .filter { $0.timestamp.isEqual(to: .now, toGranularity: granularity) }
            .reduce(into: [:]) { (result: inout [UUID: Double], transaction: WalletTransaction) in
                if transaction.currency.code == currency.code {
                    result[transaction.destination.id, default: 0] += transaction.amount
                } else {
                    let rate = ConversionRate.rate(for: transaction.currency, destination: currency, rates: rates)
                    result[transaction.destination.id, default: 0] += transaction.amount * rate
                }
            }
        let overallExpenses: Double = expensesIDs.values.reduce(0) { $0 + $1 }
        /// sorting by UUID instead of spendings value to prevent
        /// PieChart animation breaking due to items reordering
        let items = expensesIDs.sorted { $0.key > $1.key }.enumerated().compactMap { (index, item) -> Spending? in
            guard let walletItem = expenses.first(where: { $0.id == item.key }) else { return nil }
            let percent = item.value / overallExpenses
            return Spending(
                name: walletItem.name,
                icon: walletItem.icon,
                expenses: item.value,
                percent: percent,
                currency: currency,
                color: Spending.preferredColors[safe: index] ?? .yellow)
        }
        
        guard items.count > 0 else {
            return [.init(name: "", icon: "", expenses: 0.0, percent: 0.0, currency: .USD, color: .red.opacity(0.5))]
        }
        
        return items
    }

}
