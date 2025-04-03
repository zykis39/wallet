//
//  TCADependencies.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import SwiftData
import ComposableArchitecture
import FirebaseAnalytics


// MARK: - SwiftData
extension DependencyValues {
    var database: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

struct Database {
    @MainActor
    static var container: ModelContainer {
        try! ModelContainer(for: WalletItemModel.self, WalletTransactionModel.self)
    }
    @MainActor
    static let appContext: ModelContext = {
        let context = ModelContext(Self.container)
        return context
    }()
    
    @MainActor
    var context: () throws -> ModelContext
}

extension Database: DependencyKey {
    @MainActor
    static let liveValue = Self(context: { appContext })
}


// MARK: - Analytics
extension DependencyValues {
    public var analytics: AnalyticsClient {
        get { self[AnalyticsKey.self].value }
        set { self[AnalyticsKey.self].value = newValue }
    }
    
    private enum AnalyticsKey: DependencyKey {
        static var liveValue: UncheckedSendable<AnalyticsClient> {
            return UncheckedSendable(FirebaseAnalyticsClient())
        }
    }
}
