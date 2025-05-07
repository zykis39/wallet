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
typealias WalletItemModel = SchemaV3.WalletItemModel
typealias WalletTransactionModel = SchemaV3.WalletTransactionModel
public typealias WalletItem = SchemaV3.WalletItem
public typealias WalletTransaction = SchemaV3.WalletTransaction


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
    static func rate(for sourceCode: String, destinationCode: String, rates: [ConversionRate]) -> Double {
        guard let dollarToSourceRate = rates.filter({ $0.source.code == "USD" && $0.destination.code == sourceCode }).first,
              let dollarToDestinationRate = rates.filter({ $0.source.code == "USD" && $0.destination.code == destinationCode }).first else { return 1.0 }
        return 1 / dollarToSourceRate.rate * dollarToDestinationRate.rate
    }
}

extension WalletItem {
    static let none: Self = .init(id: UUID(), order: 0, type: .account, name: "", icon: "", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    
    // default accounts
    static let defaultAccounts: [Self] = [card, cash]
    static let card: Self = .init(id: UUID(), order: 0, type: .account, name: "Card", icon: "creditcard", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    static let cash: Self = .init(id: UUID(), order: 1, type: .account, name: "Cash", icon: "wallet.bifold", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    
    // default expences
    static let defaultExpenses: [Self] = [groceries, cafe, transport, shopping, services, entertainments]
    static let groceries: Self = .init(id: UUID(), order: 0, type: .expenses, name: "Groceries", icon: "carrot.fill", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    static let cafe: Self = .init(id: UUID(), order: 1, type: .expenses, name: "Cafe", icon: "fork.knife", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    static let transport: Self = .init(id: UUID(), order: 2, type: .expenses, name: "Transport", icon: "bus.fill", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    static let shopping: Self = .init(id: UUID(), order: 3, type: .expenses, name: "Shopping", icon: "handbag", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    static let services: Self = .init(id: UUID(), order: 4, type: .expenses, name: "Services", icon: "network", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
    static let entertainments: Self = .init(id: UUID(), order: 5, type: .expenses, name: "Entertainments", icon: "party.popper", currencyCode: Currency.USD.code, balance: 0, monthBudget: nil)
}

extension WalletTransaction {
    func representation(for item: WalletItem, currencies: [Currency]) -> String {
        let isIncome = (self.destinationID == item.id) && (item.type == .account)
        let amount = self.amount
        let currency: String = {
            currencies.first(where: { $0.code == self.currencyCode })?.fixedSymbol ?? self.currencyCode
        }()
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
        let ids = expenses.map { $0.id }
        let expensesIDs: [UUID: Double] = transactions
            .filter { ids.contains($0.destinationID) }
            .filter { $0.timestamp.isEqual(to: .now, toGranularity: granularity) }
            .reduce(into: [:]) { (result: inout [UUID: Double], transaction: WalletTransaction) in
                if transaction.currencyCode == currency.code {
                    result[transaction.destinationID, default: 0] += transaction.amount
                } else {
                    let rate = ConversionRate.rate(for: transaction.currencyCode, destinationCode: currency.code, rates: rates)
                    result[transaction.destinationID, default: 0] += transaction.amount * rate
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
