//
//  Models.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import SwiftUI
import UniformTypeIdentifiers

enum Currency: Codable, Equatable {
    case RUB, USD, EUR
    
    var representation: String {
        switch self {
        case .EUR: "€"
        case .USD: "$"
        case .RUB: "₽"
        }
    }
}

public struct WalletTransaction: Codable, Equatable, Sendable, Identifiable {
    public var id = UUID()
    let currency: Currency
    let amount: Int
    
    let source: WalletItem
    let destination: WalletItem
    
    static let empty: Self = .init(currency: .RUB, amount: 0, source: .none, destination: .none)
    static func canBePerformed(source: WalletItem, destination: WalletItem) -> Bool {
        source.type == .account &&
        (destination.type == .expenses || destination.type == .account) &&
        source != destination
    }
}

public struct WalletItem: Codable, Hashable, Identifiable, Sendable {
    public enum WalletItemType: Codable, Equatable, Sendable {
        case account, expenses
    }    
    public var id: UUID = UUID()
    let type: WalletItemType
    let name: String
    let icon: String
    let currency: Currency
    var balance: Int
}

extension WalletItem {
    static let none: Self = .init(type: .account, name: "", icon: "", currency: .RUB, balance: 0)
    
    // default accounts
    static let defaultAccounts: [Self] = [card, cash]
    static let card: Self = .init(type: .account, name: "Карта", icon: "card", currency: .RUB, balance: 0)
    static let cash: Self = .init(type: .account, name: "Наличные", icon: "cash", currency: .RUB, balance: 0)
    
    // default expences
    static let defaultExpenses: [Self] = [groceries, cafe, transport, shopping, services, entertainments]
    static let groceries: Self = .init(type: .expenses, name: "Продукты", icon: "groceries", currency: .RUB, balance: 0)
    static let cafe: Self = .init(type: .expenses, name: "Кафе", icon: "cafe", currency: .RUB, balance: 0)
    static let transport: Self = .init(type: .expenses, name: "Транспорт", icon: "transport", currency: .RUB, balance: 0)
    static let shopping: Self = .init(type: .expenses, name: "Покупки", icon: "shopping", currency: .RUB, balance: 0)
    static let services: Self = .init(type: .expenses, name: "Услуги", icon: "services", currency: .RUB, balance: 0)
    static let entertainments: Self = .init(type: .expenses, name: "Развлечения", icon: "entertainments", currency: .RUB, balance: 0)
}
