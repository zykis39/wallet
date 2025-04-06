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

enum AppStorageKey: String {
    case accounts
    case expenses
    case transactions
    case wasLaunchedBefore
}

@Reducer
public struct WalletFeature {
    @ObservableState
    public struct State: Equatable {
        // child
        var transaction: TransactionFeature.State
        var walletItemEdit: WalletItemEditFeature.State
        
        // internal
        var selectedCurrency: Currency = .USD
        var currencies: [Currency] = [.USD]
        var rates: [ConversionRate] = []
        
        var accounts: [WalletItem]
        var expenses: [WalletItem]
        var transactions: [WalletTransaction]
        
        // drag and drop
        var itemFrames: [WalletItem: CGRect] = [:]
        var draggingOffset: CGSize = .zero
        var dragItem: WalletItem?
        var dropItem: WalletItem?
        
        // navigation
        var aboutAppPresented: Bool = false
        var expensesStatisticsPresented: Bool = false
        
        static let initial: Self = .init(transaction: .initial,
                                         walletItemEdit: .initial,
                                         accounts: [],
                                         expenses: [],
                                         transactions: [])
    }
    
    public enum Action: Sendable {
        // child
        case transaction(TransactionFeature.Action)
        case walletItemEdit(WalletItemEditFeature.Action)
        
        // internal
        case start
        case getCurrenciesAndRates
        case prepareItemsAndTransactions
        case currenciesFetched([Currency])
        case selectedCurrencyChanged(Currency)
        case conversionRatesFetched([ConversionRate])
        case readWalletItems
        case readTransactions
        case saveWalletItems
        case deleteTransaction([WalletTransaction])
        case deleteWalletItem(UUID)
        case generateDefaultWalletItems(Currency)
        case applyTransaction(WalletTransaction)
        case reverseTransaction(WalletTransaction)
        case saveTransaction(WalletTransaction)
        case accountsUpdated([WalletItem])
        case expensesUpdated([WalletItem])
        case transactionsUpdated([WalletTransaction])
        
        // view
        case createNewItemTapped(WalletItem.WalletItemType)
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
        case itemTapped(WalletItem)
        
        // navigation
        case aboutAppPresentedChanged(Bool)
        case expensesStatisticsPresentedChanged(Bool)
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
        Reduce { state, action in
            switch action {
            case .start:
                return .run { send in
                    await send(.getCurrenciesAndRates)
                }
            case .getCurrenciesAndRates:
                return .run { send in
                    do {
                        let currencies = try await currencyService.currencies(codes: Currency.currencyCodes)
                        // FIXME: use environment or propogate state to children
                        CurrencyManagerImpl.shared.currencies = currencies
                        let defaultCurrency = CurrencyManagerImpl.shared.defaultCurrency(for: .current, from: currencies)
                        await send(.currenciesFetched(currencies))
                        await send(.selectedCurrencyChanged(defaultCurrency))
                        
                        let rates = try await currencyService.conversionRates(base: .USD, to: currencies)
                        await send(.conversionRatesFetched(rates))
                        
                        // TODO: save currencies in UserDefaults
                        // TODO: save rates in UserDefaults
                    } catch {
                        // TODO: read currencies from UserDefaults
                        // TODO: read rates from UserDefaults
                    }
                    await send(.prepareItemsAndTransactions)
                }
            case .prepareItemsAndTransactions:
                let wasLaunchedBefore = appStorage.bool(forKey: AppStorageKey.wasLaunchedBefore.rawValue)
                if !wasLaunchedBefore {
                    appStorage.set(true, forKey: AppStorageKey.wasLaunchedBefore.rawValue)
                }
                
                return .run { [currencies = state.currencies] send in
                    if !wasLaunchedBefore {
                        analytics.logEvent(.appStarted(firstLaunch: !wasLaunchedBefore))
                        let currency = CurrencyManagerImpl.shared.defaultCurrency(for: .current, from: currencies)
                        await send(.generateDefaultWalletItems(currency))
                    } else {
                        await send(.readWalletItems)
                        await send(.readTransactions)
                    }
                }
            case let .currenciesFetched(currencies):
                state.currencies = currencies
                return .none
            case let .conversionRatesFetched(rates):
                state.rates = rates
                return .none
            case let .selectedCurrencyChanged(currency):
                state.selectedCurrency = currency
                return .none
            case let .accountsUpdated(accounts):
                state.accounts = accounts
                return .none
            case let .expensesUpdated(expenses):
                state.expenses = expenses
                return .none
            case let .transactionsUpdated(transactions):
                state.transactions = transactions
                return .none
            case .readWalletItems:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let itemDescriptor = FetchDescriptor<WalletItemModel>(predicate: #Predicate<WalletItemModel> { _ in true }, sortBy: [ .init(\.timestamp, order: .reverse) ])
                do {
                    let accounts = try database.context().fetch<WalletItemModel>(itemDescriptor).filter { $0.type == .account }.map { $0.valueType }
                    let expenses = try database.context().fetch<WalletItemModel>(itemDescriptor).filter { $0.type == .expenses }.map { $0.valueType }
                    return .run { [accounts, expenses] send in
                        await send(.accountsUpdated(accounts))
                        await send(.expensesUpdated(expenses))
                    }
                } catch {
                    analytics.logEvent(.error("WalletItem decoding error: \(error.localizedDescription)"))
                }
                return .none
            case .saveWalletItems:
                let models = [state.accounts, state.expenses].flatMap { $0 }.map { WalletItemModel(model: $0) }
                do {
                    for m in models {
                        try database.context().insert(m)
                    }
                    try database.context().save()
                } catch {
                    analytics.logEvent(.error("error, applying transaction to DB: \(error)"))
                }
                return .none
            case .readTransactions:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let transactionsDescriptor = FetchDescriptor<WalletTransactionModel>(predicate: #Predicate<WalletTransactionModel> { _ in true }, sortBy: [])
                do {
                    let transactions = try database.context().fetch<WalletTransactionModel>(transactionsDescriptor).map { $0.valueType }
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
                
                return .run { send in
                    await send(.saveWalletItems)
                }
            case let .itemFrameChanged(item, frame):
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
                return .run { send in
                    analytics.logEvent(.draggingStopped(source: dragItem.name, destination: dropItem.name))
                    await send(.transaction(.onItemDropped(dragItem, dropItem)))
                }
            case let .itemTapped(item):
                state.walletItemEdit.editType = .edit
                state.walletItemEdit.item = item
                state.walletItemEdit.transactions = state.transactions.filter {
                    $0.source.id == item.id || $0.destination.id == item.id
                }
                state.walletItemEdit.presented = true
                return .run { _ in
                    analytics.logEvent(.itemTapped(itemName: item.name))
                }
            case let .applyTransaction(transaction):
                /// FIXME:
                /// транзакции не должны применяться частично в случае ошибок
                if let sourceIndex = state.accounts.firstIndex(where: { $0.id == transaction.source.id })
                    {
                    state.accounts[sourceIndex].balance -= transaction.amount
                }
                if let destinationIndex = state.expenses.firstIndex(where: { $0.id == transaction.destination.id }) {
                    state.expenses[destinationIndex].balance += transaction.amount
                } else if let destinationIndex = state.accounts.firstIndex(where: { $0.id == transaction.destination.id }) {
                    state.accounts[destinationIndex].balance += transaction.amount
                }
                return .run { send in
                    // saving new balance after applying transaction
                    await send(.saveWalletItems)
                }
            case let .reverseTransaction(transaction):
                if let sourceIndex = state.accounts.firstIndex(where: { $0.id == transaction.source.id })
                    {
                    state.accounts[sourceIndex].balance += transaction.amount
                }
                if let destinationIndex = state.expenses.firstIndex(where: { $0.id == transaction.destination.id }) {
                    state.expenses[destinationIndex].balance -= transaction.amount
                } else if let destinationIndex = state.accounts.firstIndex(where: { $0.id == transaction.destination.id }) {
                    state.accounts[destinationIndex].balance -= transaction.amount
                }
                return .none
            case let .saveTransaction(transaction):
                do {
                    try database.context().insert(WalletTransactionModel(model: transaction))
                    try database.context().save()
                } catch {
                    analytics.logEvent(.error("error, applying transaction to DB: \(error)"))
                }
                return .none
            case let .deleteTransaction(transactions):
                do {
                    let transactionIds = transactions.map { $0.id }
                    let predicate = #Predicate<WalletTransactionModel> { transactionIds.contains($0.id) }
                    try database.context().delete(model: WalletTransactionModel.self, where: predicate)
                    try database.context().save()
                } catch {
                    analytics.logEvent(.error("error, removing transactions from DB: \(error)"))
                }
                return .none
            case let .deleteWalletItem(id):
                do {
                    let predicate = #Predicate<WalletItemModel> { $0.id == id }
                    try database.context().delete(model: WalletItemModel.self, where: predicate)
                    try database.context().save()
                } catch {
                    analytics.logEvent(.error("error, removing wallet item from DB: \(error)"))
                }
                return .none
            case let .createNewItemTapped(itemType):
                let randomIcon: String = {
                    switch itemType {
                    case .account: 
                        WalletItem.accountsSystemIconNames.randomElement() ?? ""
                    case .expenses:
                        WalletItem.expensesSystemIconNames.randomElement() ?? ""
                    }
                }()
                state.walletItemEdit = .initial
                state.walletItemEdit.editType = .new
                state.walletItemEdit.item.type = itemType
                state.walletItemEdit.item.icon = randomIcon
                state.walletItemEdit.presented = true
                return .none
            case let .aboutAppPresentedChanged(presented):
                state.aboutAppPresented = presented
                return .run { _ in
                    analytics.logEvent(.aboutScreenTransition)
                }
            case let .expensesStatisticsPresentedChanged(presented):
                state.expensesStatisticsPresented = presented
                return .run { _ in
                    analytics.logEvent(.expensesStatisticsScreenTransition)
                }
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
                        await send(.reverseTransaction(t))
                    }
                    // clear DB
                    await send(.deleteTransaction(transactionsToRemove))
                    await send(.deleteWalletItem(id))
                    await send(.saveWalletItems) // need to update balance after reverse
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
                    await send(.saveWalletItems)
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
                    await send(.saveWalletItems)
                }
            case .walletItemEdit:
                return .none
            }
        }
    }
}
