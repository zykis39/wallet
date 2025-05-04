//
//  SchemaV2.swift
//  wallet
//
//  Created by Артём Зайцев on 04.05.2025.
//

import Foundation
import SwiftData

public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version = .init(2, 0, 0)
    public static var models: [any PersistentModel.Type] = [
        WalletItemModel.self,
        WalletTransactionModel.self,
    ]
    
    // MARK: - SwiftData Models
    @Model
    final class WalletItemModel: Sendable {
        @Attribute(.unique) var id: UUID
        var order: UInt
        var type: Int
        var name: String
        var icon: String
        var currencyCode: String
        var balance: Double
        
        init(id: UUID, order: UInt, type: Int, name: String, icon: String, currencyCode: String, balance: Double) {
            self.id = id
            self.order = order
            self.type = type
            self.name = name
            self.icon = icon
            self.currencyCode = currencyCode
            self.balance = balance
        }
        
        convenience init(model: WalletItem) {
            self.init(id: model.id,
                      order: model.order,
                      type: model.type.rawValue,
                      name: model.name,
                      icon: model.icon,
                      currencyCode: model.currencyCode,
                      balance: model.balance)
        }
        
        var valueType: WalletItem {
            let type: WalletItem.WalletItemType = {
                switch self.type {
                case 1: return .account
                case 2: return .expenses
                default: return .account
                }
            }()
            return .init(id: self.id,
                         order: self.order,
                         type: type,
                         name: self.name,
                         icon: self.icon,
                         currencyCode: self.currencyCode,
                         balance: self.balance)
        }
    }

    @Model
    final class WalletTransactionModel: Sendable {
        @Attribute(.unique) var id: UUID
        var timestamp: Date
        var currencyCode: String
        var amount: Double
        var commentary: String
        var rate: Double
        
        var sourceID: UUID
        var destinationID: UUID
        
        init(id: UUID, timestamp: Date, currencyCode: String, amount: Double, commentary: String, rate: Double, sourceID: UUID, destinationID: UUID) {
            self.id = id
            self.timestamp = timestamp
            self.currencyCode = currencyCode
            self.amount = amount
            self.commentary = commentary
            self.rate = rate
            self.sourceID = sourceID
            self.destinationID = destinationID
        }
        
        convenience init(model: WalletTransaction) {
            self.init(id: model.id,
                      timestamp: model.timestamp,
                      currencyCode: model.currencyCode,
                      amount: model.amount,
                      commentary: model.commentary,
                      rate: model.rate,
                      sourceID: model.sourceID,
                      destinationID: model.destinationID)
        }
        
        var valueType: WalletTransaction {
            .init(id: self.id,
                  timestamp: self.timestamp,
                  currencyCode: self.currencyCode,
                  amount: self.amount,
                  commentary: self.commentary,
                  rate: self.rate,
                  sourceID: self.sourceID,
                  destinationID: self.destinationID)
        }
    }
    
    // MARK: Value types
    public struct WalletItem: Codable, Hashable, Sendable {
        public enum WalletItemType: Int, Codable, Equatable, Sendable {
            case account = 1, expenses = 2
        }

        let id: UUID
        let order: UInt
        let type: WalletItemType
        let name: String
        let icon: String
        let currencyCode: String
        let balance: Double
        
        public init(id: UUID, order: UInt, type: WalletItemType, name: String, icon: String, currencyCode: String, balance: Double) {
            self.id = id
            self.order = order
            self.type = type
            self.name = name
            self.icon = icon
            self.currencyCode = currencyCode
            self.balance = balance
        }
    }
    
    public struct WalletTransaction: Codable, Equatable, Sendable, Identifiable {
        public var id = UUID()
        let timestamp: Date
        let currencyCode: String
        let amount: Double
        let commentary: String
        /// source.currency to destination.currency rate
        let rate: Double
        
        let sourceID: UUID
        let destinationID: UUID
        
        static func canBePerformed(source: WalletItem, destination: WalletItem) -> Bool {
            source.type == .account &&
            (destination.type == .expenses || destination.type == .account) &&
            source.id != destination.id
        }
    }
}
