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
public enum Event {
    case appStarted(firstLaunch: Bool)
    case draggingStopped(source: String, destination: String)
    case itemTapped(itemName: String)
    case itemCreated(itemName: String, currency: String)
    case transactionCreated(source: String, destination: String, amount: Double)
}

public protocol AnalyticsClient {
    func logEvent(_ event: Event)
}

final class FirebaseAnalyticsClient: AnalyticsClient {
    func logEvent(_ event: Event) {
        switch event {
        case let .appStarted(firstLaunch):
            Analytics.logEvent("AppStarted", parameters: ["firstLaunch": firstLaunch])
        case let .draggingStopped(source, destination):
            Analytics.logEvent("DraggingStopped", parameters: ["source": source,
                                                               "destination": destination])
        case let .itemTapped(itemName):
            Analytics.logEvent("ItemTapped", parameters: ["itemName": itemName])
        case let .itemCreated(itemName, currency):
            Analytics.logEvent("ItemCreated", parameters: ["itemName": itemName,
                                                           "currency": currency])
        case let .transactionCreated(source, destination, amount):
            Analytics.logEvent("TransactionCreated", parameters: ["source": source,
                                                                  "destination": destination,
                                                                  "amount": amount])
        }
    }
}

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
