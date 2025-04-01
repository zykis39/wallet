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
    public var modelContext: ModelContext {
        get { self[ModelContextKey.self].value }
        set { self[ModelContextKey.self].value = newValue }
    }
    
    static let shared: ModelContainer = try! ModelContainer(for: WalletItemModel.self, WalletTransactionModel.self)
    private enum ModelContextKey: DependencyKey {
        static var liveValue: UncheckedSendable<ModelContext> {
            return UncheckedSendable(ModelContext(shared))
        }
    }
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
