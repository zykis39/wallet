//
//  WalletFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

enum AppStorageKey {
    static let wasLaunchedBefore = "wasLaunchedBefore"
    static let selectedLocaleIdentifier = "selectedLocaleIdentifier"
    static let selectedCurrencyCode = "selectedCurrencyCode"
}

@Reducer
public struct WalletFeature {
    @ObservableState
    public struct State: Equatable {
        // child
        var transaction: TransactionFeature.State
        var walletItemEdit: WalletItemEditFeature.State
        var spendings: SpendingsFeature.State
        
        // locale
        var supportedLocales: [Locale] = [
            .init(identifier: "en"),
            .init(identifier: "ru"),
            .init(identifier: "fr"),
            .init(identifier: "de"),
            .init(identifier: "he"),
            .init(identifier: "hi"),
            .init(identifier: "it"),
            .init(identifier: "es"),
        ]
        var selectedLocale: Locale = .current
        
        // currency & rates
        var selectedCurrency: Currency = .USD
        var currencies: [Currency] = [.USD]
        var rates: [ConversionRate] = []
        
        // data
        var accounts: [WalletItem]
        var expenses: [WalletItem]
        var transactions: [WalletTransaction]
        
        /// changing state in case of dragging is expensive
        /// forcing to redraw whole scene, when we move an item
        
        // drag and drop
        var itemFrames: [WalletItem: CGRect] = [:]
        var draggingOffset: CGSize = .zero
        var dragItem: WalletItem?
        var dropItem: WalletItem?
        
        // navigation
        var settingsPresented: Bool = false
        var aboutAppPresented: Bool = false
        var expensesStatisticsPresented: Bool = false
        
        static let initial: Self = .init(transaction: .initial,
                                         walletItemEdit: .initial,
                                         spendings: .initial,
                                         accounts: [],
                                         expenses: [],
                                         transactions: [])
    }
    
    public enum Action: Sendable {
        // child
        case transaction(TransactionFeature.Action)
        case walletItemEdit(WalletItemEditFeature.Action)
        case spendings(SpendingsFeature.Action)
        
        // internal
        case start
        case getCurrenciesAndRates
        case prepareItemsAndTransactions
        case currenciesFetched([Currency])
        case conversionRatesFetched([ConversionRate])
        case readWalletItems
        case readTransactions
        case saveWalletItems([WalletItem])
        case deleteTransaction([WalletTransaction])
        case deleteWalletItem(UUID)
        case generateDefaultWalletItems(Currency)
        case applyTransaction(WalletTransaction)
        case revertTransaction(WalletTransaction)
        case saveTransaction(WalletTransaction)
        case transactionsUpdated([WalletTransaction])
        
        // locale & currency
        case checkLocale
        case selectedLocaleChanged(Locale)
        case selectedCurrencyChanged(Currency)
        
        // view
        case createNewItemTapped(WalletItem.WalletItemType)
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
        case itemTapped(WalletItem)
        
        // navigation
        case settingsPresentedChanged(Bool)
        case aboutAppPresentedChanged(Bool)
        case presentSpendings
    }
    
    @Dependency(\.currencyService) var currencyService
    @Dependency(\.analytics) var analytics
    @Dependency(\.database) var database
    @Dependency(\.defaultAppStorage) var appStorage
    public var body: some Reducer<State, Action> {
        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
        }
        Scope(state: \.walletItemEdit, action: \.walletItemEdit) {
            WalletItemEditFeature()
        }
        Scope(state: \.spendings, action: \.spendings) {
            SpendingsFeature()
        }
        Reduce { state, action in
            switch action {
            case .start:
                return .run { send in
                    await send(.checkLocale)
                    await send(.getCurrenciesAndRates)
                }
            case .checkLocale:
                if let selectedLocaleIdentifier = appStorage.string(forKey: AppStorageKey.selectedLocaleIdentifier),
                   let locale = state.supportedLocales.first(where: { $0.identifier == selectedLocaleIdentifier }) {
                    state.selectedLocale = locale
                } else {
                    if let identifier = Locale.current.language.languageCode?.identifier {
                        state.selectedLocale = .init(identifier: identifier)
                    } else {
                        state.selectedLocale = .current
                    }
                }
                return .none
            case .getCurrenciesAndRates:
                return .run { send in
                    do {
                        let currencies = try await currencyService.currencies(codes: Currency.currencyCodes)
                        await send(.currenciesFetched(currencies))
                        
                        let rates = try await currencyService.conversionRates(base: .USD, to: currencies)
                        await send(.conversionRatesFetched(rates))
                        try currencyService.save(currencies)
                        try currencyService.save(rates)
                    } catch {
                        do {
                            let currencies = try currencyService.readCurrencies()
                            await send(.currenciesFetched(currencies))
                            
                            let rates = try currencyService.readConversionRates(currencies: currencies)
                            await send(.conversionRatesFetched(rates))
                        } catch {
                            analytics.logEvent(.error("error, trying to get currencies/rates: \(error)"))
                        }
                    }
                    await send(.prepareItemsAndTransactions)
                }
            case .prepareItemsAndTransactions:
                let wasLaunchedBefore = appStorage.bool(forKey: AppStorageKey.wasLaunchedBefore)
                if !wasLaunchedBefore {
                    appStorage.set(true, forKey: AppStorageKey.wasLaunchedBefore)
                }
                
                return .run { [currencies = state.currencies] send in
                    if !wasLaunchedBefore {
                        analytics.logEvent(.appStarted(firstLaunch: !wasLaunchedBefore))
                        let currency = CurrencyManager.shared.defaultCurrency(for: .current, from: currencies)
                        await send(.generateDefaultWalletItems(currency))
                    } else {
                        await send(.readWalletItems)
                        await send(.readTransactions)
                    }
                }
            case let .currenciesFetched(currencies):
                state.currencies = currencies
                
                var selectedCurrency: Currency?
                if let code = appStorage.string(forKey: AppStorageKey.selectedCurrencyCode),
                   let currency = currencies.first(where: { $0.code == code }) {
                       selectedCurrency = currency
                } else {
                    selectedCurrency = CurrencyManager.shared.defaultCurrency(for: .current, from: currencies)
                }
                guard let selectedCurrency else { return .none }
                
                return .run { send in
                    await send(.selectedCurrencyChanged(selectedCurrency))
                }
            case let .conversionRatesFetched(rates):
                state.rates = rates
                return .none
            case let .selectedCurrencyChanged(currency):
                state.selectedCurrency = currency
                appStorage.set(currency.code, forKey: AppStorageKey.selectedCurrencyCode)
                return .none
            case let .selectedLocaleChanged(locale):
                state.selectedLocale = locale
                appStorage.set(locale.identifier, forKey: AppStorageKey.selectedLocaleIdentifier)
                return .none
            case let .transactionsUpdated(transactions):
                state.transactions = transactions
                return .none
            case .readWalletItems:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let itemDescriptor = FetchDescriptor<WalletItemModel>(predicate: #Predicate<WalletItemModel> { _ in true }, sortBy: [ .init(\.timestamp, order: .forward) ])
                do {
                    let accounts = try database.fetch(itemDescriptor).filter { $0.type == .account }.map { $0.valueType }
                    _ = accounts.map { print("\($0.name): \($0.timestamp)") }
                    let expenses = try database.fetch(itemDescriptor).filter { $0.type == .expenses }.map { $0.valueType }
                    _ = expenses.map { print("\($0.name): \($0.timestamp)") }
                    state.accounts = accounts
                    state.expenses = expenses
                    return .none
                } catch {
                    analytics.logEvent(.error("WalletItem decoding error: \(error.localizedDescription)"))
                }
                return .none
            case let .saveWalletItems(items):
                let models = items.map { WalletItemModel(model: $0) }
                do {
                    try database.insert(models)
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, applying transaction to DB: \(error)"))
                }
                return .none
            case .readTransactions:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let transactionsDescriptor = FetchDescriptor<WalletTransactionModel>(predicate: #Predicate<WalletTransactionModel> { _ in true }, sortBy: [])
                do {
                    let transactions = try database.fetch(transactionsDescriptor).map { $0.valueType }
                    return .run { send in
                        await send(.transactionsUpdated(transactions))
                    }
                } catch {
                    analytics.logEvent(.error("Transaction decoding error: \(error.localizedDescription)"))
                }
                return .none
            case let .generateDefaultWalletItems(currency):
                state.accounts = WalletItem.defaultAccounts.map {
                    WalletItem(id: $0.id,
                               timestamp: $0.timestamp,
                               type: $0.type,
                               name: $0.name,
                               icon: $0.icon,
                               currency: currency,
                               balance: $0.balance)
                }
                
                state.expenses = WalletItem.defaultExpenses.map {
                    WalletItem(id: $0.id,
                               timestamp: $0.timestamp,
                               type: $0.type,
                               name: $0.name,
                               icon: $0.icon,
                               currency: currency,
                               balance: $0.balance)
                }
                
                return .run { [accounts = state.accounts, expenses = state.expenses] send in
                    await send(.saveWalletItems(accounts + expenses))
                }
            case let .itemFrameChanged(item, frame):
                // FIXME: не вызывается для нового элемента
                state.itemFrames[item] = frame
                return .none
            case let .onItemDragging(offset, point, item):
                state.draggingOffset = offset
                state.dragItem = item

                let droppingItemFrames = state.itemFrames.filter { $0.value.contains(point) }
                guard let dropItem = droppingItemFrames.keys.first, WalletTransaction.canBePerformed(source: item, destination: dropItem) else {
                    state.dropItem = nil
                    return .none
                }
                
                state.dropItem = dropItem
                return .none
            case .onDraggingStopped:
                let dragItem = state.dragItem
                let dropItem = state.dropItem
                
                state.draggingOffset = .zero
                state.dragItem = nil
                state.dropItem = nil
                
                guard let dragItem, let dropItem else { return .none }
                return .run { [rates = state.rates] send in
                    analytics.logEvent(.draggingStopped(source: dragItem.name, destination: dropItem.name))
                    let rate = ConversionRate.rate(for: dragItem.currency, destination: dropItem.currency, rates: rates)
                    await send(.transaction(.onItemDropped(dragItem, dropItem, rate)))
                }
            case let .itemTapped(item):
                let transactions = state.transactions.filter { $0.source.id == item.id || $0.destination.id == item.id }
                
                return .run { [currencies = state.currencies, rates = state.rates] send in
                    await send(.walletItemEdit(.presentItem(item, transactions, currencies, rates)))
                    analytics.logEvent(.itemTapped(itemName: item.name))
                }
            case let .applyTransaction(transaction):
                var destinationType: WalletItem.WalletItemType?
                var sourceIndex: Int?
                var destinationIndex: Int?
                
                if let idx = state.accounts.firstIndex(where: { $0.id == transaction.source.id })
                    {
                    sourceIndex = idx
                }
                if let idx = state.expenses.firstIndex(where: { $0.id == transaction.destination.id }) {
                    destinationIndex = idx
                    destinationType = .expenses
                } else if let idx = state.accounts.firstIndex(where: { $0.id == transaction.destination.id }) {
                    destinationIndex = idx
                    destinationType = .account
                }
                
                /// prevent transaction to be partly applied
                guard let destinationType,
                      let sourceIndex,
                      let destinationIndex else { return .none }
                
                let src = transaction.source
                let updatedSource = WalletItem(id: src.id,
                                               timestamp: src.timestamp,
                                               type: src.type,
                                               name: src.name,
                                               icon: src.icon,
                                               currency: src.currency,
                                               balance: src.balance - transaction.amount)
                
                let dst = transaction.destination
                let updatedDestination = WalletItem(id: dst.id,
                                                    timestamp: dst.timestamp,
                                                    type: dst.type,
                                                    name: dst.name,
                                                    icon: dst.icon,
                                                    currency: dst.currency,
                                                    balance: dst.balance + transaction.amount * transaction.rate)
                
                switch destinationType {
                case .account:
                    state.accounts[sourceIndex] = updatedSource
                    state.accounts[destinationIndex] = updatedDestination
                    break
                case .expenses:
                    state.accounts[sourceIndex] = updatedSource
                    state.expenses[destinationIndex] = updatedDestination
                    break
                }
                
                return .run { send in
                    await send(.saveWalletItems([updatedSource, updatedDestination]))
                }
            case let .revertTransaction(transaction):
                var destinationType: WalletItem.WalletItemType?
                var sourceIndex: Int?
                var destinationIndex: Int?
                
                if let idx = state.accounts.firstIndex(where: { $0.id == transaction.source.id })
                    {
                    sourceIndex = idx
                }
                if let idx = state.expenses.firstIndex(where: { $0.id == transaction.destination.id }) {
                    destinationIndex = idx
                    destinationType = .expenses
                } else if let idx = state.accounts.firstIndex(where: { $0.id == transaction.destination.id }) {
                    destinationIndex = idx
                    destinationType = .account
                }
                
                /// prevent transaction to be partly applied
                guard let destinationType,
                      let sourceIndex,
                      let destinationIndex else { return .none }
                
                let src = transaction.source
                let updatedSource = WalletItem(id: src.id,
                                               timestamp: src.timestamp,
                                               type: src.type,
                                               name: src.name,
                                               icon: src.icon,
                                               currency: src.currency,
                                               balance: src.balance + transaction.amount)
                
                let dst = transaction.destination
                let updatedDestination = WalletItem(id: dst.id,
                                                    timestamp: dst.timestamp,
                                                    type: dst.type,
                                                    name: dst.name,
                                                    icon: dst.icon,
                                                    currency: dst.currency,
                                                    balance: dst.balance - transaction.amount * transaction.rate)
                
                switch destinationType {
                case .account:
                    state.accounts[sourceIndex] = updatedSource
                    state.accounts[destinationIndex] = updatedDestination
                    break
                case .expenses:
                    state.accounts[sourceIndex] = updatedSource
                    state.expenses[destinationIndex] = updatedDestination
                    break
                }
                
                return .run { send in
                    await send(.saveWalletItems([updatedSource, updatedDestination]))
                }
            case let .saveTransaction(transaction):
                do {
                    try database.insert(WalletTransactionModel(model: transaction))
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, applying transaction to DB: \(error)"))
                }
                return .none
            case let .deleteTransaction(transactions):
                do {
                    let transactionIds = transactions.map { $0.id }
                    let predicate = #Predicate<WalletTransactionModel> { transactionIds.contains($0.id) }
                    try database.delete(model: WalletTransactionModel.self, where: predicate)
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, removing transactions from DB: \(error)"))
                }
                return .none
            case let .deleteWalletItem(id):
                do {
                    let predicate = #Predicate<WalletItemModel> { $0.id == id }
                    try database.delete(model: WalletItemModel.self, where: predicate)
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, removing wallet item from DB: \(error)"))
                }
                return .none
            case let .createNewItemTapped(itemType):
                return .run { [currency = state.selectedCurrency, currencies = state.currencies] send in
                    await send(.walletItemEdit(.presentNewItem(itemType, currency, currencies)))
                }
            case let .settingsPresentedChanged(presented):
                state.settingsPresented = presented
                return .none
            case let .aboutAppPresentedChanged(presented):
                state.aboutAppPresented = presented
                return .run { _ in
                    analytics.logEvent(.aboutScreenTransition)
                }
            case .presentSpendings:
                return .run { send in
                    await send(.spendings(.recalculateAndPresentSpendings(.month)))
                }
                // MARK: - Spendings
            case let .spendings(.recalculateAndPresentSpendings(period)):
                let spendings = Spending.calculateSpendings(state.transactions,
                                                            expenses: state.expenses,
                                                            period: period,
                                                            rates: state.rates,
                                                            currency: state.selectedCurrency)
                let chartSections = spendings.map {
                    PieChartSection(name: $0.name,
                                    angle: $0.percent * 360,
                                    icon: $0.icon,
                                    color: $0.color,
                                    opacity: $0.expenses == 0 ? 0.5 : 1)
                }
                let currency = state.selectedCurrency
                return .run { send in
                    await send(.spendings(.presentSpendings(currency, spendings, chartSections)))
                }
            case .spendings:
                return .none
                
                // MARK: - Transaction
            case let .transaction(.createTransaction(transaction)):
                state.transactions.append(transaction)
                return .run { send in
                    analytics.logEvent(.transactionCreated(source: transaction.source.name,
                                                           destination: transaction.destination.name,
                                                           amount: transaction.amount))
                    await send(.applyTransaction(transaction))
                    await send(.saveTransaction(transaction))
                }
            case .transaction:
                return .none
                
                // MARK: - WalletItemEdit
            case let .walletItemEdit(.deleteWalletItem(id)):
                // remove related transactions
                let transactionsToRemove = state.transactions.filter { $0.source.id == id || $0.destination.id == id }
                state.transactions.removeAll(where: { transaction in
                    transactionsToRemove.contains { $0.id == transaction.id }
                })
                
                // remove item
                guard let item: WalletItem = [state.accounts, state.expenses].flatMap({ $0 }).filter({ $0.id == id }).first else { return .none }
                
                switch item.type {
                case .account:
                    state.accounts.removeAll { $0.id == item.id }
                case .expenses:
                    state.expenses.removeAll { $0.id == item.id }
                }
                
                return .run { [transactionsToRemove] send in
                    for t in transactionsToRemove {
                        // restore balance of affected accounts/expenses
                        await send(.revertTransaction(t))
                    }
                    // clear DB
                    await send(.deleteTransaction(transactionsToRemove))
                    await send(.deleteWalletItem(id))
                    // close sheet
                    await send(.walletItemEdit(.presentedChanged(false)))
                }
            case let .walletItemEdit(.createWalletItem(item)):
                switch item.type {
                case .account:
                    state.accounts.append(item)
                case .expenses:
                    state.expenses.append(item)
                }
                return .run { send in
                    analytics.logEvent(.itemCreated(itemName: item.name, currency: item.currency.code))
                    await send(.saveWalletItems([item]))
                }
            case let .walletItemEdit(.updateWalletItem(item)):
                switch item.type {
                case .account:
                    guard let index = state.accounts.firstIndex(where: { $0.id == item.id }) else { return .none }
                    state.accounts[index] = item
                case .expenses:
                    guard let index = state.expenses.firstIndex(where: { $0.id == item.id }) else { return .none }
                    state.expenses[index] = item
                }
                return .run { send in
                    await send(.saveWalletItems([item]))
                }
            case let .walletItemEdit(.deleteTransaction(transaction)):
                state.transactions = state.transactions.filter { $0.id != transaction.id }
                
                return .run { send in
                    await send(.revertTransaction(transaction))
                    await send(.deleteTransaction([transaction]))
                }
            case .walletItemEdit:
                return .none
            }
        }
    }
}
