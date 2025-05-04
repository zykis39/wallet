//
//  MigrationPlan.swift
//  wallet
//
//  Created by Артём Зайцев on 10.04.2025.
//
import Foundation
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self,
    ]
    
    /// Миграция должна происходить путём копирования данных из одной таблицы в другую
    /// Название таблицы судя по всему берутся из названий классов с макросом @Model
    /// В окончании блока willMigrate ожидается, что данные для V2 уже будут подготовлены
    /// Поэтому в сложных миграциях нужно создать промежуточную модель с дополнительными полями
    /// Название класса модели при этом должно отличаться от исходной
    /// (SchemaV1.Model -> SchemaV2.Model будут причиной проблем)
    /// В блоке didMigrate мы удаляем промежуточные модели (V12) и наполняем их новыми (V2)
    
    static let migrationV1toV2 = MigrationStage.custom(fromVersion: SchemaV1.self,
                                                       toVersion: SchemaV2.self,
                                                       willMigrate: { context in
        
        let itemsV1 = try context.fetch(FetchDescriptor<SchemaV1.WalletItemModel>())
        let transactionsV1 = try context.fetch(FetchDescriptor<SchemaV1.WalletTransactionModel>())
        
        let itemsV12: [ScopeV12.WalletItemModelV12] = itemsV1.map {
            ScopeV12.WalletItemModelV12(id: $0.id,
                                        order: $0.order,
                                        type: $0.type,
                                        name: $0.name,
                                        icon: $0.icon,
                                        currency: $0.currency,
                                        currencyCode: $0.currency.code,
                                        balance: $0.balance)
        }
        
        let transactionsV12: [ScopeV12.WalletTransactionModelV12] = transactionsV1.map {
            ScopeV12.WalletTransactionModelV12(id: $0.id,
                                               timestamp: $0.timestamp,
                                               currency: $0.currency,
                                               currencyCode: $0.currency.code,
                                               amount: $0.amount,
                                               commentary: $0.commentary,
                                               rate: $0.rate,
                                               source: $0.source,
                                               destination: $0.destination,
                                               sourceID: $0.source.id,
                                               destinationID: $0.destination.id)
        }
        
        
        for t in transactionsV1 {
            context.delete(t)
        }
        for i in itemsV1 {
            context.delete(i)
        }
        
        for i in itemsV12 {
            context.insert(i)
        }
        
        for t in transactionsV12 {
            context.insert(t)
        }
        
        try context.save()
    },
                                                       didMigrate: { context in
        let itemsV12 = try context.fetch(FetchDescriptor<ScopeV12.WalletItemModelV12>())
        let transactionsV12 = try context.fetch(FetchDescriptor<ScopeV12.WalletTransactionModelV12>())
        
        let itemsV2 = itemsV12.map { item in
            let type: SchemaV2.WalletItem.WalletItemType = {
                switch item.type {
                case .account: return .account
                case .expenses: return .expenses
                }
            }()
            return SchemaV2.WalletItemModel(id: item.id,
                                            order: item.order,
                                            type: type.rawValue,
                                            name: item.name,
                                            icon: item.icon,
                                            currencyCode: item.currency.code,
                                            balance: item.balance)
        }
        
        let transactionsV2 = transactionsV12.map {
            SchemaV2.WalletTransactionModel(id: $0.id,
                                            timestamp: $0.timestamp,
                                            currencyCode: $0.currency.code,
                                            amount: $0.amount,
                                            commentary: $0.commentary,
                                            rate: $0.rate,
                                            sourceID: $0.source.id,
                                            destinationID: $0.destination.id)
        }
        
        for t in transactionsV12 {
            context.delete(t)
        }
        for i in itemsV12 {
            context.delete(i)
        }
        for i in itemsV2 {
            context.insert(i)
        }
        for t in transactionsV2 {
            context.insert(t)
        }
        
        try context.save()
    })
    
    static var stages: [MigrationStage] = [
        migrationV1toV2
    ]
}

class ScopeV12 {
    @Model
    final class WalletItemModelV12: Sendable {
        @Attribute(.unique) var id: UUID
        var order: UInt
        var type: SchemaV1.WalletItem.WalletItemType
        var name: String
        var icon: String
        var currency: Currency
        var currencyCode: String
        var balance: Double
        
        init(id: UUID, order: UInt, type: SchemaV1.WalletItem.WalletItemType, name: String, icon: String, currency: Currency, currencyCode: String, balance: Double) {
            self.id = id
            self.order = order
            self.type = type
            self.name = name
            self.icon = icon
            self.currency = currency
            self.currencyCode = currencyCode
            self.balance = balance
        }
    }

    @Model
    final class WalletTransactionModelV12: Sendable {
        @Attribute(.unique) var id: UUID
        var timestamp: Date
        var currency: Currency
        var currencyCode: String
        var amount: Double
        var commentary: String
        var rate: Double
        
        var source: SchemaV1.WalletItem
        var destination: SchemaV1.WalletItem
        var sourceID: UUID
        var destinationID: UUID
        
        init(id: UUID, timestamp: Date, currency: Currency, currencyCode: String, amount: Double, commentary: String, rate: Double, source: SchemaV1.WalletItem, destination: SchemaV1.WalletItem, sourceID: UUID, destinationID: UUID) {
            self.id = id
            self.timestamp = timestamp
            self.currency = currency
            self.currencyCode = currencyCode
            self.amount = amount
            self.commentary = commentary
            self.rate = rate
            self.source = source
            self.destination = destination
            self.sourceID = sourceID
            self.destinationID = destinationID
        }
    }
}


