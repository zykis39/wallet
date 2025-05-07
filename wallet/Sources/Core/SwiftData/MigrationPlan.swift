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
        SchemaV3.self,
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
    
    static let migrationV2toV3 = MigrationStage.custom(fromVersion: SchemaV2.self,
                                                       toVersion: SchemaV3.self,
                                                       willMigrate: { context in
        // create empty fields
        let itemsV2 = try context.fetch(FetchDescriptor<SchemaV2.WalletItemModel>())
        let itemsV3 = itemsV2.map {
            SchemaV3.WalletItemModel(id: $0.id,
                                     order: $0.order,
                                     type: $0.type,
                                     name: $0.name,
                                     icon: $0.icon,
                                     currencyCode: $0.currencyCode,
                                     balance: $0.balance,
                                     monthBudget: nil)
        }
        
        for item in itemsV3 {
            context.insert(item)
        }
        try context.save()
    }, didMigrate: nil)
    
    static var stages: [MigrationStage] = [
        migrationV1toV2,
        migrationV2toV3,
    ]
}



