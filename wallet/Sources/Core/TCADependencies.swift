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
    
    @MainActor
    var container: ModelContainer {
        do {
            let configuration = ModelConfiguration(url: URL.documentsDirectory.appending(path: "database.sqlite"))
            return try ModelContainer(for: WalletItemModel.self, WalletTransactionModel.self, configurations: configuration)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

struct Database {
    var context: () throws -> ModelContext
}
@MainActor
let appContext: ModelContext = {
    let context = ModelContext(SwiftDataContainerProvider.shared.container)
    return context
}()

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
