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

public struct WalletItem: Codable, Hashable, Sendable {
    public enum WalletItemType: Int, Codable, Equatable, Sendable {
        case account, expenses
    }

    var id: UUID = UUID()
    var timestamp: Date
    var type: WalletItemType
    var name: String
    var icon: String
    var currency: Currency
    var balance: Double
    
    init(id: UUID = UUID(), timestamp: Date = .now, type: WalletItemType, name: String, icon: String, currency: Currency, balance: Double) {
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
    
    let source: WalletItem
    let destination: WalletItem
    
    static let empty: Self = .init(timestamp: .now, currency: .USD, amount: 0, source: .none, destination: .none)
    static func canBePerformed(source: WalletItem, destination: WalletItem) -> Bool {
        source.type == .account &&
        (destination.type == .expenses || destination.type == .account) &&
        source.id != destination.id
    }
}

public enum Period: CaseIterable {
    case day, week, month
    var representation: LocalizedStringKey {
        switch self {
        case .day: "Period.Day"
        case .week: "Period.Week"
        case .month: "Period.Month"
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
    static func rate(for source: Currency, destination: Currency, rates: [ConversionRate]) -> Double? {
        guard let dollarToSourceRate = rates.filter({ $0.source.code == "USD" && $0.destination.code == source.code }).first,
              let dollarToDestinationRate = rates.filter({ $0.source.code == "USD" && $0.destination.code == destination.code }).first else { return nil }
        return 1 / dollarToSourceRate.rate * dollarToDestinationRate.rate
    }
}

extension WalletItem {
    static let none: Self = .init(type: .account, name: "", icon: "", currency: .USD, balance: 0)
    
    // default accounts
    static let defaultAccounts: [Self] = [card, cash]
    static let card: Self = .init(timestamp: .init(timeIntervalSince1970: 1), type: .account, name: "Card", icon: "creditcard", currency: .USD, balance: 0)
    static let cash: Self = .init(timestamp: .init(timeIntervalSince1970: 2), type: .account, name: "Cash", icon: "wallet.bifold", currency: .USD, balance: 0)
    
    // default expences
    static let defaultExpenses: [Self] = [groceries, cafe, transport, shopping, services, entertainments]
    static let groceries: Self = .init(timestamp: .init(timeIntervalSince1970: 1), type: .expenses, name: "Groceries", icon: "carrot", currency: .USD, balance: 0)
    static let cafe: Self = .init(timestamp: .init(timeIntervalSince1970: 2), type: .expenses, name: "Cafe", icon: "fork.knife", currency: .USD, balance: 0)
    static let transport: Self = .init(timestamp: .init(timeIntervalSince1970: 3), type: .expenses, name: "Transport", icon: "bus.fill", currency: .USD, balance: 0)
    static let shopping: Self = .init(timestamp: .init(timeIntervalSince1970: 4), type: .expenses, name: "Shopping", icon: "handbag", currency: .USD, balance: 0)
    static let services: Self = .init(timestamp: .init(timeIntervalSince1970: 5), type: .expenses, name: "Services", icon: "network", currency: .USD, balance: 0)
    static let entertainments: Self = .init(timestamp: .init(timeIntervalSince1970: 6), type: .expenses, name: "Entertainments", icon: "party.popper", currency: .USD, balance: 0)
}


// MARK: - SwiftData Models

@Model
final class WalletItemModel: Sendable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var type: WalletItem.WalletItemType
    var name: String
    var icon: String
    var currency: Currency
    var balance: Double
    
    init(id: UUID, timestamp: Date, type: WalletItem.WalletItemType, name: String, icon: String, currency: Currency, balance: Double) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.name = name
        self.icon = icon
        self.currency = currency
        self.balance = balance
    }
    
    convenience init(model: WalletItem) {
        self.init(id: model.id,
                  timestamp: model.timestamp,
                  type: model.type,
                  name: model.name,
                  icon: model.icon,
                  currency: model.currency,
                  balance: model.balance)
    }
    
    var valueType: WalletItem {
        return .init(id: self.id,
                     type: self.type,
                     name: self.name,
                     icon: self.icon,
                     currency: self.currency,
                     balance: self.balance)
    }
}

@Model
final class WalletTransactionModel: Sendable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var currency: Currency
    var amount: Double
    
    var source: WalletItem
    var destination: WalletItem
    
    init(id: UUID, timestamp: Date, currency: Currency, amount: Double, source: WalletItem, destination: WalletItem) {
        self.id = id
        self.timestamp = timestamp
        self.currency = currency
        self.amount = amount
        self.source = source
        self.destination = destination
    }
    
    convenience init(model: WalletTransaction) {
        self.init(id: model.id,
                  timestamp: model.timestamp,
                  currency: model.currency,
                  amount: model.amount,
                  source: model.source,
                  destination: model.destination)
    }
    
    var valueType: WalletTransaction {
        .init(id: self.id,
              timestamp: self.timestamp,
              currency: self.currency,
              amount: self.amount,
              source: self.source,
              destination: self.destination)
    }
}

extension WalletTransaction {
    func representation(for item: WalletItem) -> String {
        let isIncome = (self.destination.id == item.id) && (item.type == .account)
        let amount = self.amount
        let currency = self.currency.fixedSymbol
        let isItemSource = self.source.id == item.id
        let to = isItemSource ? self.destination.name.localized() : self.source.name.localized()
        let result = String.init(format: "%@ %@ %@ %@", arguments: [
            isIncome ? "+" : "-",
            CurrencyFormatter.formatter.string(from: NSNumber(value: amount)) ?? "",
            currency,
            to
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
        "carrot",
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
