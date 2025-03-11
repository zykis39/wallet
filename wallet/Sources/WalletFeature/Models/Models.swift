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

extension UTType {
    static var walletItem: UTType {
        UTType(exportedAs: "wallet.item.type")
    }
}

public struct WalletTransaction: Codable, Equatable {
    let currency: Currency
    let amount: Double
    
    let source: WalletItem
    let destination: WalletItem
}

public struct WalletItem: Codable, Hashable, Identifiable {
    public enum WalletItemType: Codable, Equatable {
        case account, expenses
    }    
    public var id: UUID = UUID()
    let type: WalletItemType
    let name: String
    let icon: String
    let currency: Currency
    let amount: Double
    
    var inTransactions: [WalletTransaction] {
        get { [] }
    }
    var outTransactions: [WalletTransaction] {
        get { [] }
    }
}

extension WalletItem: Transferable {
    static public var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .walletItem)
    }
}

extension WalletItem {
    // default accounts
    static let defaultAccounts: [Self] = [card, cash]
    static let card: Self = .init(type: .account, name: "Карта", icon: "card", currency: .RUB, amount: 0.0)
    static let cash: Self = .init(type: .account, name: "Наличные", icon: "cash", currency: .RUB, amount: 0.0)
    
    // default expences
    static let defaultExpenses: [Self] = [groceries, cafe, transport, shopping, services, entertainments]
    static let groceries: Self = .init(type: .expenses, name: "Продукты", icon: "groceries", currency: .RUB, amount: 0.0)
    static let cafe: Self = .init(type: .expenses, name: "Кафе", icon: "cafe", currency: .RUB, amount: 0.0)
    static let transport: Self = .init(type: .expenses, name: "Транспорт", icon: "transport", currency: .RUB, amount: 0.0)
    static let shopping: Self = .init(type: .expenses, name: "Покупки", icon: "shopping", currency: .RUB, amount: 0.0)
    static let services: Self = .init(type: .expenses, name: "Услуги", icon: "services", currency: .RUB, amount: 0.0)
    static let entertainments: Self = .init(type: .expenses, name: "Развлечения", icon: "entertainments", currency: .RUB, amount: 0.0)
}
