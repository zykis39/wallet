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
            let configuration = ModelConfiguration(url: URL.documentsDirectory.appending(path: "database.sqlite"))
            let schema = Schema(versionedSchema: SchemaV1.self)
            return try ModelContainer(for: schema,
                                      migrationPlan: MigrationPlan.self,
                                      configurations: configuration)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

struct Database {
    var context: () throws -> ModelContext
    
    func save() throws {
        try context().save()
    }
    
    func insert<T>(_ model: T) throws where T: PersistentModel {
        try context().insert(model)
    }
    
    func insert<T>(_ models: [T]) throws where T: PersistentModel {
        _ = try models.map { try insert($0) }
    }
    
    func delete<T>(_ model: T) throws where T: PersistentModel {
        try context().delete(model)
    }
    
    func delete<T>(model: T.Type, where predicate: Predicate<T>? = nil, includeSubclasses: Bool = true) throws where T : PersistentModel {
        try context().delete(model: model, where: predicate, includeSubclasses: includeSubclasses)
    }
    
    func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
        try context().fetch(descriptor)
    }
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

// MARK: - AppScoreService
extension DependencyValues {
    public var appScoreService: AppScoreServiceProtocol {
        get { self[AppScoreServiceKey.self].value }
        set { self[AppScoreServiceKey.self].value = newValue }
    }
    
    private enum AppScoreServiceKey: DependencyKey {
        static var liveValue: UncheckedSendable<AppScoreServiceProtocol> {
            return UncheckedSendable(AppScoreService())
        }
    }
}
