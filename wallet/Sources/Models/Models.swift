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

public enum Currency: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    public var id: Int { representation.hashValue }
    case RUB
    
    var representation: String {
        switch self {
        case .RUB: "₽"
        }
    }
}

public struct WalletTransaction: Codable, Equatable, Sendable, Identifiable {
    public var id = UUID()
    let timestamp: Date
    let currency: Currency
    let amount: Double
    
    let source: WalletItem
    let destination: WalletItem
    
    static let empty: Self = .init(timestamp: .now, currency: .RUB, amount: 0, source: .none, destination: .none)
    static func canBePerformed(source: WalletItem, destination: WalletItem) -> Bool {
        source.type == .account &&
        (destination.type == .expenses || destination.type == .account) &&
        source.id != destination.id
    }
}

public enum Period: CaseIterable {
    case day, week, month
    var representation: String {
        switch self {
        case .day: "День"
        case .week: "Неделя"
        case .month: "Месяц"
        }
    }
}

extension WalletItem {
    static let none: Self = .init(type: .account, name: "", icon: "", currency: .RUB, balance: 0)
    
    // default accounts
    static let defaultAccounts: [Self] = [card, cash]
    static let card: Self = .init(timestamp: .init(timeIntervalSince1970: 1), type: .account, name: "Карта", icon: "creditcard", currency: .RUB, balance: 0)
    static let cash: Self = .init(timestamp: .init(timeIntervalSince1970: 2), type: .account, name: "Наличные", icon: "wallet.bifold", currency: .RUB, balance: 0)
    
    // default expences
    static let defaultExpenses: [Self] = [groceries, cafe, transport, shopping, services, entertainments]
    static let groceries: Self = .init(timestamp: .init(timeIntervalSince1970: 1), type: .expenses, name: "Продукты", icon: "carrot", currency: .RUB, balance: 0)
    static let cafe: Self = .init(timestamp: .init(timeIntervalSince1970: 2), type: .expenses, name: "Кафе", icon: "fork.knife", currency: .RUB, balance: 0)
    static let transport: Self = .init(timestamp: .init(timeIntervalSince1970: 3), type: .expenses, name: "Транспорт", icon: "bus.fill", currency: .RUB, balance: 0)
    static let shopping: Self = .init(timestamp: .init(timeIntervalSince1970: 4), type: .expenses, name: "Покупки", icon: "handbag", currency: .RUB, balance: 0)
    static let services: Self = .init(timestamp: .init(timeIntervalSince1970: 5), type: .expenses, name: "Услуги", icon: "network", currency: .RUB, balance: 0)
    static let entertainments: Self = .init(timestamp: .init(timeIntervalSince1970: 6), type: .expenses, name: "Развлечения", icon: "party.popper", currency: .RUB, balance: 0)
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
