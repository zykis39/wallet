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

final class SwiftDataContainerProvider {
    static let shared: SwiftDataContainerProvider = .init()
    
    func container(inMemory: Bool) -> ModelContainer {
        do {
            let configuration: ModelConfiguration = {
                switch inMemory {
                case true:
                    return .init(isStoredInMemoryOnly: true)
                case false:
                    return .init(url: URL.documentsDirectory.appending(path: "database.sqlite"))
                }
            }()
            return try ModelContainer(for: WalletItemModel.self, WalletTransactionModel.self,
                                      migrationPlan: MigrationPlan.self,
                                      configurations: configuration)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

struct Database {
    var context: () throws -> ModelContext
}

let appContext: ModelContext = {
    let context = ModelContext(SwiftDataContainerProvider.shared.container(inMemory: false))
    context.autosaveEnabled = false
    return context
}()

extension Database: DependencyKey {
    static let liveValue = Self(context: { appContext })
    static let testValue = Self(context: { appContext })
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

// MARK: - CurrencyService
extension DependencyValues {
    public var currencyService: CurrencyServiceProtocol {
        get { self[CurrencyServiceKey.self].value }
        set { self[CurrencyServiceKey.self].value = newValue }
    }
    
    private enum CurrencyServiceKey: DependencyKey {
        static var liveValue: UncheckedSendable<CurrencyServiceProtocol> {
            return UncheckedSendable(CurrencyService())
        }
    }
}
