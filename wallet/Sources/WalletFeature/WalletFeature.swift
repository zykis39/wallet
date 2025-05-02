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
    static let isReorderButtonHidden = "isReorderButtonHidden"
}

public enum DragMode: Equatable, Sendable {
    case normal
    case reordering
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
        
        // settings
        var selectedLocale: Locale = .current
        var selectedCurrency: Currency = .USD
        var isReorderButtonHidden: Bool = true
        
        var currencies: [Currency] = [.USD]
        var rates: [ConversionRate] = []
        
        // data
        var dragMode: DragMode = .normal
        var balance: Double
        var monthExpenses: Double
        var accounts: [WalletItem]
        var expenses: [WalletItem]
        var transactions: [WalletTransaction]
        
        /// changing state in case of dragging is expensive
        /// forcing to redraw whole scene, when we move an item
        
        // drag and drop
        var itemFrames: [UUID: CGRect] = [:]
        var draggingOffset: CGSize = .zero
        var draggingLocation: CGPoint = .zero
        var dragItem: WalletItem?
        var dropItem: WalletItem?
        
        // navigation
        var settingsPresented: Bool = false
        var aboutAppPresented: Bool = false
        var expensesStatisticsPresented: Bool = false
        
        static let initial: Self = .init(transaction: .initial,
                                         walletItemEdit: .initial,
                                         spendings: .initial,
                                         balance: 0,
                                         monthExpenses: 0,
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
        case readSettings
        case getCurrenciesAndRates
        case prepareItemsAndTransactions
        case calculateBalance
        case calculateExpenses
        case currenciesFetched([Currency])
        case conversionRatesFetched([ConversionRate])
        case readWalletItems
        case readTransactions
        case saveWalletItems([WalletItem])
        case deleteTransactions([UUID])
        case deleteWalletItem(UUID)
        case generateDefaultWalletItems(Currency)
        case generateTestTransactions(Currency)
        case applyTransaction(WalletTransaction)
        case revertTransaction(WalletTransaction)
        case saveTransaction(WalletTransaction)
        case transactionsUpdated([WalletTransaction])
        case dragModeChanged(DragMode)
        
        case checkLocale
        // settings
        case selectedLocaleChanged(Locale)
        case selectedCurrencyChanged(Currency)
        case isReorderButtonHiddenChanged(Bool)
        
        // view
        case createNewItemTapped(WalletItem.WalletItemType)
        case itemFrameChanged(UUID, CGRect?)
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
                    await send(.readSettings)
                    await send(.checkLocale)
                    await send(.getCurrenciesAndRates)
                }
            case .readSettings:
                state.isReorderButtonHidden = appStorage.bool(forKey: AppStorageKey.isReorderButtonHidden)
                return .none
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
                        let currencies = try currencyService.readCurrencies()
                        await send(.currenciesFetched(currencies))
                        
                        let rates = try await currencyService.conversionRates(base: .USD, to: currencies)
                        await send(.conversionRatesFetched(rates))
                        try currencyService.save(currencies)
                        try currencyService.save(rates)
                    } catch {
                        do {
                            let currencies = try currencyService.readCurrencies()
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
                        #if DEBUG
                        await send(.generateTestTransactions(currency))
                        #endif
                    } else {
                        await send(.readWalletItems)
                        await send(.readTransactions)
                    }
                }
            case .calculateBalance:
                let balance: Double = state.accounts.reduce(0) {
                    if state.selectedCurrency == $1.currency {
                        return $0 + $1.balance
                    } else {
                        let rate = ConversionRate.rate(for: $1.currency, destination: state.selectedCurrency, rates: state.rates)
                        return $0 + $1.balance * rate
                    }
                }
                state.balance = balance
                return .none
            case .calculateExpenses:
                let monthExpenses: Double = state.transactions
                    .filter { $0.destination.type == .expenses }
                    .filter { $0.timestamp.isEqual(to: .now, toGranularity: .month) }
                    .reduce(0) {
                        if $1.currency == state.selectedCurrency {
                            return $0 + $1.amount
                        } else {
                            let rate = ConversionRate.rate(for: $1.currency, destination: state.selectedCurrency, rates: state.rates)
                            return $0 + $1.amount * rate
                        }
                    }
                state.monthExpenses = monthExpenses
                return .none
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
            case let .isReorderButtonHiddenChanged(visible):
                state.isReorderButtonHidden = visible
                return .none
            case let .transactionsUpdated(transactions):
                state.transactions = transactions
                return .run { send in
                    await send(.calculateExpenses)
                }
            case .readWalletItems:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let itemDescriptor = FetchDescriptor<WalletItemModel>(predicate: #Predicate<WalletItemModel> { _ in true }, sortBy: [ .init(\.order, order: .forward) ])
                do {
                    let accounts = try database.fetch(itemDescriptor).filter { $0.type == .account }.map { $0.valueType }
                    _ = accounts.map { print("\($0.name): \($0.order)") }
                    let expenses = try database.fetch(itemDescriptor).filter { $0.type == .expenses }.map { $0.valueType }
                    _ = expenses.map { print("\($0.name): \($0.order)") }
                    state.accounts = accounts
                    state.expenses = expenses
                } catch {
                    analytics.logEvent(.error("WalletItem decoding error: \(error.localizedDescription)"))
                }
                return .run { send in
                    await send(.calculateBalance)
                }
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
                               order: $0.order,
                               type: $0.type,
                               name: $0.name,
                               icon: $0.icon,
                               currency: currency,
                               balance: $0.balance)
                }
                
                state.expenses = WalletItem.defaultExpenses.map {
                    WalletItem(id: $0.id,
                               order: $0.order,
                               type: $0.type,
                               name: $0.name,
                               icon: $0.icon,
                               currency: currency,
                               balance: $0.balance)
                }
                
                return .run { [accounts = state.accounts, expenses = state.expenses] send in
                    await send(.saveWalletItems(accounts + expenses))
                    await send(.calculateBalance)
                }
            case let .generateTestTransactions(currency):
                let transactions = WalletTransaction.testTransactions(currency)
                state.transactions = transactions
                return .run { send in
                    for t in transactions {
                        await send(.applyTransaction(t))
                        await send(.saveTransaction(t))
                    }
                }
            case let .itemFrameChanged(itemId, frame):
                // FIXME: не вызывается для нового элемента
                state.itemFrames[itemId] = frame
                return .none
            case let .onItemDragging(offset, point, item):
                state.draggingOffset = offset
                state.draggingLocation = point
                state.dragItem = item
                let droppingItemFrames = state.itemFrames.filter { $0.value.contains(point) }
                
                switch state.dragMode {
                case .normal:
                    guard let dropItemId = droppingItemFrames.keys.first,
                          let dropItem = [state.accounts, state.expenses].flatMap({ $0 }).first(where: { $0.id == dropItemId }),
                            WalletTransaction.canBePerformed(source: item, destination: dropItem) else {
                        state.dropItem = nil
                        return .none
                    }
                    
                    state.dropItem = dropItem
                    return .none
                    
                case .reordering:
                    guard let dropItemId = droppingItemFrames.keys.first,
                          let dropItem = [state.accounts, state.expenses].flatMap({ $0 }).first(where: { $0.id == dropItemId }),
                          let droppingFrame = droppingItemFrames.first?.value,
                          item.id != dropItem.id,
                          dropItem.type == item.type
                    else { return .none }
                    
                    let centerX = droppingFrame.origin.x + droppingFrame.size.width / 2
                    let placingBefore: Bool = point.x < centerX
                    
                    switch item.type {
                    case .account:
                        reorder(dragItemId: item.id,
                                dropItemId: dropItemId,
                                placingBefore: placingBefore,
                                in: &state.accounts)
                    case .expenses:
                        reorder(dragItemId: item.id,
                                dropItemId: dropItemId,
                                placingBefore: placingBefore,
                                in: &state.expenses)
                    }
                    
                    func reorder(dragItemId: UUID, dropItemId: UUID, placingBefore: Bool, in items: inout [WalletItem]) {
                        guard let dropItemIdx = items.firstIndex(where: { $0.id == dropItemId }),
                              let dragItemIdx = items.firstIndex(where: { $0.id == dragItemId }) else { return }
                        let targetIdx = placingBefore ? dropItemIdx : dropItemIdx + 1
                        if targetIdx < dragItemIdx {
                            items.remove(at: dragItemIdx)
                            items.insert(item, at: targetIdx)
                        } else {
                            items.insert(item, at: targetIdx)
                            items.remove(at: dragItemIdx)
                        }
                    }
                    
                    return .none
                }
            case .onDraggingStopped:
                switch state.dragMode {
                case .normal:
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
                    
                case .reordering:
                    state.draggingOffset = .zero
                    state.dragItem = nil
                    state.dropItem = nil
                    return .none
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
                      let destinationIndex,
                      let src = state.accounts.first(where: { transaction.source.id == $0.id }),
                      let dst = [state.accounts, state.expenses].flatMap ({ $0 }).first(where: { transaction.destination.id == $0.id })
                else { return .none }
                
                let updatedSource = WalletItem(id: src.id,
                                               order: src.order,
                                               type: src.type,
                                               name: src.name,
                                               icon: src.icon,
                                               currency: src.currency,
                                               balance: src.balance - transaction.amount)
                
                let updatedDestination = WalletItem(id: dst.id,
                                                    order: dst.order,
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
                    await send(.calculateBalance)
                    await send(.calculateExpenses)
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
                /// may be partially apply is not that bad
                /// example: partially revert transaction after deleting expense/account
                guard let destinationType,
                      let sourceIndex,
                      let destinationIndex,
                      let src = state.accounts.first(where: { transaction.source.id == $0.id }),
                      let dst = [state.accounts, state.expenses].flatMap ({ $0 }).first(where: { transaction.destination.id == $0.id })
                else {
                    analytics.logEvent(.error("error, reverting partly applied transaction: \(transaction)"))
                    return .none
                }
                                      
                let updatedSource = WalletItem(id: src.id,
                                               order: src.order,
                                               type: src.type,
                                               name: src.name,
                                               icon: src.icon,
                                               currency: src.currency,
                                               balance: src.balance + transaction.amount)
                
                
                let updatedDestination = WalletItem(id: dst.id,
                                                    order: dst.order,
                                                    type: dst.type,
                                                    name: dst.name,
                                                    icon: dst.icon,
                                                    currency: dst.currency,
                                                    balance: dst.balance - transaction.amount * transaction.rate)
                
                state.accounts[sourceIndex] = updatedSource
                switch destinationType {
                case .account:
                    state.accounts[destinationIndex] = updatedDestination
                    break
                case .expenses:
                    state.expenses[destinationIndex] = updatedDestination
                    break
                }
                
                return .run { send in
                    await send(.saveWalletItems([updatedSource, updatedDestination]))
                    await send(.calculateBalance)
                    await send(.calculateExpenses)
                }
            case let .saveTransaction(transaction):
                do {
                    try database.insert(WalletTransactionModel(model: transaction))
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, applying transaction to DB: \(error)"))
                }
                return .none
            case let .deleteTransactions(transactionIds):
                // remove from memory
                state.transactions = state.transactions.filter { !transactionIds.contains($0.id) }
                
                // remove from db
                do {
                    let predicate = #Predicate<WalletTransactionModel> { transactionIds.contains($0.id) }
                    try database.delete(model: WalletTransactionModel.self, where: predicate)
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, removing transactions from DB: \(error)"))
                }
                return .none
            case let .deleteWalletItem(id):
                state.accounts = state.accounts.filter { $0.id != id }
                state.expenses = state.expenses.filter { $0.id != id }
                
                do {
                    let predicate = #Predicate<WalletItemModel> { $0.id == id }
                    try database.delete(model: WalletItemModel.self, where: predicate)
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, removing wallet item from DB: \(error)"))
                }
                return .run { send in
                    await send(.itemFrameChanged(id, nil))
                }
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
                return .run { [period = state.spendings.period] send in
                    await send(.spendings(.recalculateAndPresentSpendings(period)))
                }
            case let .dragModeChanged(dragMode):
                state.dragMode = dragMode
                
                switch dragMode {
                case .normal:
                    for (idx, item) in state.accounts.enumerated() {
                        let newItem = WalletItem(id: item.id,
                                                 order: UInt(idx),
                                                 type: item.type,
                                                 name: item.name,
                                                 icon: item.icon,
                                                 currency: item.currency,
                                                 balance: item.balance)
                        state.accounts[idx] = newItem
                    }
                    
                    for (idx, item) in state.expenses.enumerated() {
                        let newItem = WalletItem(id: item.id,
                                                 order: UInt(idx),
                                                 type: item.type,
                                                 name: item.name,
                                                 icon: item.icon,
                                                 currency: item.currency,
                                                 balance: item.balance)
                        state.expenses[idx] = newItem
                    }
                    
                    return .run { [items = state.accounts + state.expenses] send in
                        await send(.saveWalletItems(items))
                    }
                    
                case .reordering:
                    return .none
                }
                
                // MARK: - Spendings
            case let .spendings(.recalculateAndPresentSpendings(period)):
                let spendings = Spending.calculateSpendings(state.transactions,
                                                            expenses: state.expenses,
                                                            period: period,
                                                            rates: state.rates,
                                                            currency: state.selectedCurrency)
                var middleAngle: Double = -90.0
                let chartSections = spendings.map {
                    let angle = $0.percent * 360
                    middleAngle += angle / 2
                    defer { middleAngle += angle / 2 }
                    return PieChartSection(name: $0.name,
                                           angle: angle,
                                           middleAngle: middleAngle,
                                           icon: $0.icon,
                                           color: $0.color)
                }
                let currency = state.selectedCurrency
                return .run { send in
                    await send(.spendings(.presentSpendings(period, currency, spendings, chartSections)))
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
            case let .walletItemEdit(.deleteWalletItem(id, deleteTransactions)):
                // remove related transactions
                let transactionsToRemove = deleteTransactions ? state.transactions.filter { $0.source.id == id || $0.destination.id == id } : []
                
                return .run { [transactionsToRemove] send in
                    for t in transactionsToRemove {
                        // restore balance of affected accounts/expenses
                        await send(.revertTransaction(t))
                    }
                    // clear DB
                    await send(.deleteTransactions(transactionsToRemove.map { $0.id }))
                    await send(.deleteWalletItem(id))
                    // close sheet
                    await send(.walletItemEdit(.presentedChanged(false)))
                }
            case let .walletItemEdit(.createWalletItem(item)):
                let order: UInt = {
                    switch item.type {
                    case .account:
                        return (state.accounts.map { $0.order }.max() ?? 0) + 1
                    case .expenses:
                        return (state.expenses.map { $0.order }.max() ?? 0) + 1
                    }
                }()
                let orderedItem = WalletItem(id: item.id,
                                             order: order,
                                             type: item.type,
                                             name: item.name,
                                             icon: item.icon,
                                             currency: item.currency,
                                             balance: item.balance)
                
                switch item.type {
                case .account:
                    state.accounts.append(orderedItem)
                case .expenses:
                    state.expenses.append(orderedItem)
                }
                return .run { send in
                    analytics.logEvent(.itemCreated(itemName: orderedItem.name, currency: orderedItem.currency.code))
                    await send(.saveWalletItems([orderedItem]))
                    await send(.calculateBalance)
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
                    await send(.calculateBalance)
                }
            case let .walletItemEdit(.deleteTransaction(transaction)):
                return .run { send in
                    await send(.revertTransaction(transaction))
                    await send(.deleteTransactions([transaction.id]))
                }
            case .walletItemEdit:
                return .none
            }
        }
    }
}
