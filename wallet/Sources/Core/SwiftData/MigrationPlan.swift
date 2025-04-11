//
//  MigrationPlan.swift
//  wallet
//
//  Created by Артём Зайцев on 10.04.2025.
//
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
    ]
    
    static var stages: [MigrationStage] = []
}
