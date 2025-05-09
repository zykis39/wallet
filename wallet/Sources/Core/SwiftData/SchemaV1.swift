//
//  SchemaV1.swift
//  wallet
//
//  Created by Артём Зайцев on 10.04.2025.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        WalletItemModel.self,
        WalletTransactionModel.self,
    ]
    
    // MARK: - SwiftData Models
    @Model
    final class WalletItemModel: Sendable {
        @Attribute(.unique) var id: UUID
        var order: UInt
        var type: WalletItem.WalletItemType
        var name: String
        var icon: String
        var currency: Currency
        var balance: Double
        
        init(id: UUID, order: UInt, type: WalletItem.WalletItemType, name: String, icon: String, currency: Currency, balance: Double) {
            self.id = id
            self.order = order
            self.type = type
            self.name = name
            self.icon = icon
            self.currency = currency
            self.balance = balance
        }
        
        convenience init(model: WalletItem) {
            self.init(id: model.id,
                      order: model.order,
                      type: model.type,
                      name: model.name,
                      icon: model.icon,
                      currency: model.currency,
                      balance: model.balance)
        }
        
        var valueType: WalletItem {
            return .init(id: self.id,
                         order: self.order,
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
        var commentary: String
        var rate: Double
        
        var source: WalletItem
        var destination: WalletItem
        
        init(id: UUID, timestamp: Date, currency: Currency, amount: Double, commentary: String, rate: Double, source: WalletItem, destination: WalletItem) {
            self.id = id
            self.timestamp = timestamp
            self.currency = currency
            self.amount = amount
            self.commentary = commentary
            self.rate = rate
            self.source = source
            self.destination = destination
        }
        
        convenience init(model: WalletTransaction) {
            self.init(id: model.id,
                      timestamp: model.timestamp,
                      currency: model.currency,
                      amount: model.amount,
                      commentary: model.commentary,
                      rate: model.rate,
                      source: model.source,
                      destination: model.destination)
        }
        
        var valueType: WalletTransaction {
            .init(id: self.id,
                  timestamp: self.timestamp,
                  currency: self.currency,
                  amount: self.amount,
                  commentary: self.commentary,
                  rate: self.rate,
                  source: self.source,
                  destination: self.destination)
        }
    }
    
    // MARK: Value types
    public struct WalletItem: Codable, Hashable, Sendable {
        public enum WalletItemType: Int, Codable, Equatable, Sendable {
            case account, expenses
        }

        let id: UUID
        let order: UInt
        let type: WalletItemType
        let name: String
        let icon: String
        let currency: Currency
        let balance: Double
        
        init(id: UUID, order: UInt, type: WalletItemType, name: String, icon: String, currency: Currency, balance: Double) {
            self.id = id
            self.order = order
            self.type = type
            self.name = name
            self.icon = icon
            self.currency = currency
            self.balance = balance
        }
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
}
