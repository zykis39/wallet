//
//  WalletFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import Combine
import ComposableArchitecture
import Foundation
import SwiftData
import SwiftUI

enum AppStorageKey {
    static let wasLaunchedBefore = "wasLaunchedBefore"
    static let selectedLocaleIdentifier = "selectedLocaleIdentifier"
    static let selectedCurrencyCode = "selectedCurrencyCode"
    static let isReorderButtonHidden = "isReorderButtonHidden"
    static let wasAskedForReview = "wasAskedForReview"
}

public enum DragMode: Equatable, Sendable {
    case normal
    case reordering
}

public enum CancelID: Hashable, Sendable {
    static let changeScrollPositionEffectID = "changeScrollPositionEffectID"
}

@Reducer
public struct WalletFeature {
    @ObservableState
    public struct State: Equatable {
        // child
        var transaction: TransactionFeature.State
        var walletItemEdit: WalletItemEditFeature.State
        var spendings: SpendingsFeature.State
        var transactionsList: TransactionsListFeature.State
        var appScore: AppScoreFeature.State
        
        // app score
        var score: Int = 0
        var review: String = ""
        
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
        var expensesGranularity: ExpensesGranularity = .month
        
        var currencies: [Currency] = [.USD]
        var rates: [ConversionRate] = []
        
        // data
        var balance: Double
        var monthExpenses: Double
        var budget: Double
        var accounts: [WalletItem]
        var expenses: [WalletItem]
        var transactions: [WalletTransaction]
        
        // view
        var accountsScrollPosition: ScrollPosition = .init(x: 0)
        
        // drag and drop
        var dragMode: DragMode = .normal
        var itemFrames: [UUID: CGRect] = [:]
        var draggingOffset: CGSize = .zero
        var draggingLocation: CGPoint = .zero
        var draggingTime: Date? = nil
        var dragItem: WalletItem?
        var dropItem: WalletItem?
        
        // navigation
        var settingsPresented: Bool = false
        var aboutAppPresented: Bool = false
        var expensesStatisticsPresented: Bool = false
        var appScorePresented: Bool = false
        
        static let initial: Self = .init(transaction: .initial,
                                         walletItemEdit: .initial,
                                         spendings: .initial,
                                         transactionsList: .initial,
                                         appScore: .initial,
                                         balance: 0,
                                         monthExpenses: 0,
                                         budget: 0,
                                         accounts: [],
                                         expenses: [],
                                         transactions: [])
    }
    
    public enum Action: Sendable {
        // child
        case transaction(TransactionFeature.Action)
        case walletItemEdit(WalletItemEditFeature.Action)
        case spendings(SpendingsFeature.Action)
        case transactionsList(TransactionsListFeature.Action)
        case appScore(AppScoreFeature.Action)
        
        // internal
        case start
        case readSettings
        case getCurrenciesAndRates
        case prepareItemsAndTransactions
        case calculateBalanceAndBudget
        case calculateExpenses
        case calculateExpensesBalance
        case currenciesFetched([Currency])
        case conversionRatesFetched([ConversionRate])
        case readWalletItems
        case readTransactions
        case saveWalletItemsToDB([WalletItem])
        case deleteTransaction(UUID)
        case deleteTransactionsFromDB([UUID])
        case deleteWalletItem(UUID)
        case generateDefaultWalletItems(Currency)
        case generateTestTransactions(Currency)
        case applyTransaction(WalletTransaction)
        case revertTransaction(UUID)
        case saveTransactionToDB(WalletTransaction)
        case transactionsUpdated([WalletTransaction])
        case dragModeChanged(DragMode)
        case resetDrag
        
        case checkLocale
        case checkIfAppScoreCanBePresented
        // settings
        case selectedLocaleChanged(Locale)
        case selectedCurrencyChanged(Currency)
        case isReorderButtonHiddenChanged(Bool)
        
        // view
        case accountsScrollPositionChanged(ScrollPosition)
        case createNewItemTapped(WalletItem.WalletItemType)
        case itemFrameChanged(UUID, CGRect?)
        case onItemDragging(CGSize, CGPoint, Date, WalletItem)
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
    @Dependency(\.continuousClock) var clock
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
        Scope(state: \.transactionsList, action: \.transactionsList) {
            TransactionsListFeature()
        }
        Scope(state: \.appScore, action: \.appScore) {
            AppScoreFeature()
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
            case .checkIfAppScoreCanBePresented:
                guard state.transactions.count > 10,
                        !appStorage.bool(forKey: AppStorageKey.wasAskedForReview) else { return .none }
                defer { appStorage.set(true, forKey: AppStorageKey.wasAskedForReview) }
                return .send(.appScore(.presentedChanged(true)))
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
                let currencyCode = state.selectedCurrency.code
                let locale = state.selectedLocale.identifier
                
                return .run { [currencies = state.currencies] send in
                    if !wasLaunchedBefore {
                        analytics.logEvent(.appStarted(firstLaunch: !wasLaunchedBefore, currencyCode: currencyCode, locale: locale))
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
            case .calculateBalanceAndBudget:
                let balance: Double = state.accounts.reduce(0) {
                    if state.selectedCurrency.code == $1.currencyCode {
                        return $0 + $1.balance
                    } else {
                        let rate = ConversionRate.rate(for: $1.currencyCode, destinationCode: state.selectedCurrency.code, rates: state.rates)
                        return $0 + $1.balance * rate
                    }
                }
                state.balance = balance
                
                let budget: Double = state.expenses.reduce(0) {
                    if state.selectedCurrency.code == $1.currencyCode, let budget = $1.monthBudget {
                        return $0 + budget
                    } else if let budget = $1.monthBudget {
                        let rate = ConversionRate.rate(for: $1.currencyCode, destinationCode: state.selectedCurrency.code, rates: state.rates)
                        return $0 + budget * rate
                    } else {
                        return $0
                    }
                }
                state.budget = budget
                return .none
            case .calculateExpenses:
                let expensesIds = state.expenses.map { $0.id }
                let monthExpenses: Double = state.transactions
                    .filter { expensesIds.contains($0.destinationID) }
                    .filter {
                        switch state.expensesGranularity {
                        case .month: $0.timestamp.isEqual(to: .now, toGranularity: .month)
                        case .week: $0.timestamp.isEqual(to: .now, toGranularity: .weekOfMonth)
                        }
                    }
                    .reduce(0) {
                        if $1.currencyCode == state.selectedCurrency.code {
                            return $0 + $1.amount
                        } else {
                            let rate = ConversionRate.rate(for: $1.currencyCode, destinationCode: state.selectedCurrency.code, rates: state.rates)
                            return $0 + $1.amount * rate
                        }
                    }
                state.monthExpenses = monthExpenses
                return .none
            case .calculateExpensesBalance:
                var zeroBalanceExpenses = state.expenses.map {
                    WalletItem(id: $0.id,
                               order: $0.order,
                               type: $0.type,
                               name: $0.name,
                               icon: $0.icon,
                               currencyCode: $0.currencyCode,
                               balance: 0,
                               monthBudget: $0.monthBudget)
                }
                
                let currentPeriodTransactions = state.transactions.filter {
                    switch state.expensesGranularity {
                    case .week: $0.timestamp.isEqual(to: .now, toGranularity: .weekOfMonth)
                    case .month: $0.timestamp.isEqual(to: .now, toGranularity: .month)
                    }
                }
                for transaction in currentPeriodTransactions {
                    guard let expenseIndex = zeroBalanceExpenses.firstIndex(where: { $0.id == transaction.destinationID }) else { continue }
                    var expense = zeroBalanceExpenses[expenseIndex]
                    let newBalance = expense.balance + transaction.amount * transaction.rate
                    expense = WalletItem(id: expense.id,
                                         order: expense.order,
                                         type: expense.type,
                                         name: expense.name,
                                         icon: expense.icon,
                                         currencyCode: expense.currencyCode,
                                         balance: newBalance,
                                         monthBudget: expense.monthBudget)
                    zeroBalanceExpenses[expenseIndex] = expense
                }
                state.expenses = zeroBalanceExpenses
                
                return .run { [expenses = state.expenses] send in
                    await send(.saveWalletItemsToDB(expenses))
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
                return .send(.selectedCurrencyChanged(selectedCurrency))
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
                    await send(.calculateExpensesBalance)
                }
            case let .accountsScrollPositionChanged(position):
                state.accountsScrollPosition = position
                return .none
            case .readWalletItems:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let itemDescriptor = FetchDescriptor<WalletItemModel>(predicate: #Predicate<WalletItemModel> { _ in true }, sortBy: [ .init(\.order, order: .forward) ])
                do {
                    let accounts = try database.fetch(itemDescriptor).filter { $0.type == WalletItem.WalletItemType.account.rawValue }.map { $0.valueType }
                    _ = accounts.map { print("\($0.name): \($0.order)") }
                    let expenses = try database.fetch(itemDescriptor).filter { $0.type == WalletItem.WalletItemType.expenses.rawValue }.map { $0.valueType }
                    _ = expenses.map { print("\($0.name): \($0.order)") }
                    state.accounts = accounts
                    state.expenses = expenses
                } catch {
                    analytics.logEvent(.error("WalletItem decoding error: \(error.localizedDescription)"))
                }
                return .send(.calculateBalanceAndBudget)
            case let .saveWalletItemsToDB(items):
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
                    for t in transactions {
                        if let source = [state.accounts + state.expenses].flatMap ({ $0 }).first(where: { t.sourceID == $0.id }),
                           let destination = [state.accounts + state.expenses].flatMap ({ $0 }).first(where: { t.destinationID == $0.id }){
                            print("transaction from: \(source.name), to: \(destination.name), value: \(t.amount), currency: \(t.currencyCode), rate: \(t.rate)")
                        }
                    }
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
                               currencyCode: currency.code,
                               balance: $0.balance,
                               monthBudget: $0.monthBudget)
                }
                
                state.expenses = WalletItem.defaultExpenses.map {
                    WalletItem(id: $0.id,
                               order: $0.order,
                               type: $0.type,
                               name: $0.name,
                               icon: $0.icon,
                               currencyCode: currency.code,
                               balance: $0.balance,
                               monthBudget: $0.monthBudget)
                }
                
                return .run { [accounts = state.accounts, expenses = state.expenses] send in
                    await send(.saveWalletItemsToDB(accounts + expenses))
                    await send(.calculateBalanceAndBudget)
                }
            case let .generateTestTransactions(currency):
                let transactions = WalletTransaction.testTransactions(currency)
                state.transactions = transactions
                return .run { send in
                    for t in transactions {
                        await send(.applyTransaction(t))
                        await send(.saveTransactionToDB(t))
                    }
                }
            case let .itemFrameChanged(itemId, frame):
                state.itemFrames[itemId] = frame
                return .none
            case let .onItemDragging(offset, point, date, item):
                state.draggingOffset = offset
                state.draggingLocation = point
                state.draggingTime = date
                state.dragItem = item
                let droppingItemFrames = state.itemFrames.filter { $0.value.contains(point) }

                switch state.dragMode {
                case .normal:
                    guard let dropItemId = droppingItemFrames.keys.first,
                          let dropItem = [state.accounts, state.expenses].flatMap({ $0 }).first(where: { $0.id == dropItemId }),
                            WalletTransaction.canBePerformed(source: item, destination: dropItem) else {
                        state.dropItem = nil
                        return checkForScrollPositionChange(state: &state, dragPoint: point)
                    }
                    
                    state.dropItem = dropItem
                    return checkForScrollPositionChange(state: &state, dragPoint: point)
                    
                case .reordering:
                    guard let dropItemId = droppingItemFrames.keys.first,
                          let dropItem = [state.accounts, state.expenses].flatMap({ $0 }).first(where: { $0.id == dropItemId }),
                          let droppingFrame = droppingItemFrames.first?.value,
                          item.id != dropItem.id,
                          dropItem.type == item.type
                    else { return checkForScrollPositionChange(state: &state, dragPoint: point) }
                    
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
                    return checkForScrollPositionChange(state: &state, dragPoint: point)
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
                
                func checkForScrollPositionChange(state: inout State, dragPoint: CGPoint) -> Effect<WalletFeature.Action> {
                    if state.accounts.count > 4 {
                        let inAccountsRow: Bool = point.y > 0 && point.y < WalletView.Constants.accountsViewHeight
                        if inAccountsRow {
                            let windowWidth: CGFloat = UIScreen.main.bounds.width
                            let cornerWidth: CGFloat = 30
                            let currentPositionXOffset: CGFloat = state.accountsScrollPosition.point?.x ?? 0
                            let inLeftCornerOfAccounts: Bool = point.x < cornerWidth
                            let inRightCornerOfAccounts: Bool = point.x > windowWidth - cornerWidth
                            
                            if inLeftCornerOfAccounts {
                                return .run { send in
                                    let newX: CGFloat = max(0, currentPositionXOffset - windowWidth)
                                    try? await clock.sleep(for: .seconds(1))
                                    await send(.accountsScrollPositionChanged(.init(x: newX)), animation: .easeInOut)
                                }.cancellable(id: CancelID.changeScrollPositionEffectID)
                            } else if inRightCornerOfAccounts {
                                return .run { send in
                                    let newX: CGFloat = currentPositionXOffset + windowWidth
                                    try? await clock.sleep(for: .seconds(1))
                                    await send(.accountsScrollPositionChanged(.init(x: newX)), animation: .easeInOut)
                                }.cancellable(id: CancelID.changeScrollPositionEffectID)
                            } else {
                                return .cancel(id: CancelID.changeScrollPositionEffectID)
                            }
                            
                        } else {
                            return .cancel(id: CancelID.changeScrollPositionEffectID)
                        }
                    }
                    return .cancel(id: CancelID.changeScrollPositionEffectID)
                }
                
            case .onDraggingStopped:
                switch state.dragMode {
                case .normal:
                    let dragItem = state.dragItem
                    let dropItem = state.dropItem
                    let currencies = state.currencies
                    
                    state.draggingOffset = .zero
                    state.dragItem = nil
                    state.dropItem = nil
                    
                    guard let dragItem, let dropItem else { return .none }
                    return .run { [rates = state.rates] send in
                        let rate = ConversionRate.rate(for: dragItem.currencyCode, destinationCode: dropItem.currencyCode, rates: rates)
                        analytics.logEvent(.transactionScreenTransition(source: dragItem.name, destination: dropItem.name, rate: rate))
                        
                        await send(.transaction(.onItemDropped(dragItem, dropItem, rate, currencies)))
                    }
                    
                case .reordering:
                    state.draggingOffset = .zero
                    state.dragItem = nil
                    state.dropItem = nil
                    return .none
                }
            case let .itemTapped(item):
                let transactions = state.transactions.filter { $0.sourceID == item.id || $0.destinationID == item.id }
                
                return .run { [currencies = state.currencies, rates = state.rates, items = state.accounts + state.expenses] send in
                    await send(.walletItemEdit(.presentItem(item, items, transactions, currencies, rates)))
                    analytics.logEvent(.itemTapped(name: item.name))
                }
            case let .applyTransaction(transaction):
                var destinationType: WalletItem.WalletItemType?
                var sourceIndex: Int?
                var destinationIndex: Int?
                
                if let idx = state.accounts.firstIndex(where: { $0.id == transaction.sourceID })
                    {
                    sourceIndex = idx
                }
                if let idx = state.expenses.firstIndex(where: { $0.id == transaction.destinationID }) {
                    destinationIndex = idx
                    destinationType = .expenses
                } else if let idx = state.accounts.firstIndex(where: { $0.id == transaction.destinationID }) {
                    destinationIndex = idx
                    destinationType = .account
                }
                
                /// transaction can be partly applied
                /// example: we removed source of transaction, but we want to revent balance from destination
                 
                var updatedSource: WalletItem?
                var updatedDestination: WalletItem?
                
                if let src = state.accounts.first(where: { transaction.sourceID == $0.id }) {
                    updatedSource = WalletItem(id: src.id,
                                               order: src.order,
                                               type: src.type,
                                               name: src.name,
                                               icon: src.icon,
                                               currencyCode: src.currencyCode,
                                               balance: src.balance - transaction.amount,
                                               monthBudget: src.monthBudget)
                }
                if let dst = [state.accounts, state.expenses].flatMap ({ $0 }).first(where: { transaction.destinationID == $0.id }) {
                    updatedDestination = WalletItem(id: dst.id,
                                                    order: dst.order,
                                                    type: dst.type,
                                                    name: dst.name,
                                                    icon: dst.icon,
                                                    currencyCode: dst.currencyCode,
                                                    balance: dst.balance + transaction.amount * transaction.rate,
                                                    monthBudget: dst.monthBudget)
                }
                if let updatedSource, let sourceIndex {
                    state.accounts[sourceIndex] = updatedSource
                }
                if let destinationType, let updatedDestination, let destinationIndex {
                    switch destinationType {
                    case .account:
                        state.accounts[destinationIndex] = updatedDestination
                        break
                    case .expenses:
                        state.expenses[destinationIndex] = updatedDestination
                        break
                    }
                }
                
                return .run { [updatedSource, updatedDestination] send in
                    let items = [updatedSource, updatedDestination].compactMap { $0 }
                    guard items.count > 0 else { return }
                    await send(.saveWalletItemsToDB(items))
                    await send(.calculateBalanceAndBudget)
                    await send(.calculateExpenses)
                }
            case let .revertTransaction(transactionID):
                guard let transaction = state.transactions.first(where: { $0.id == transactionID }) else { return .none }
                var destinationType: WalletItem.WalletItemType?
                var sourceIndex: Int?
                var destinationIndex: Int?
                
                if let idx = state.accounts.firstIndex(where: { $0.id == transaction.sourceID })
                    {
                    sourceIndex = idx
                }
                if let idx = state.expenses.firstIndex(where: { $0.id == transaction.destinationID }) {
                    destinationIndex = idx
                    destinationType = .expenses
                } else if let idx = state.accounts.firstIndex(where: { $0.id == transaction.destinationID }) {
                    destinationIndex = idx
                    destinationType = .account
                }
                
                /// transaction can be partly applied
                /// example: we removed source of transaction, but we want to revent balance from destination
                 
                var updatedSource: WalletItem?
                var updatedDestination: WalletItem?
                
                if let src = state.accounts.first(where: { transaction.sourceID == $0.id }) {
                    updatedSource = WalletItem(id: src.id,
                                               order: src.order,
                                               type: src.type,
                                               name: src.name,
                                               icon: src.icon,
                                               currencyCode: src.currencyCode,
                                               balance: src.balance + transaction.amount,
                                               monthBudget: src.monthBudget)
                }
                
                if let dst = [state.accounts, state.expenses].flatMap ({ $0 }).first(where: { transaction.destinationID == $0.id }) {
                    updatedDestination = WalletItem(id: dst.id,
                                                    order: dst.order,
                                                    type: dst.type,
                                                    name: dst.name,
                                                    icon: dst.icon,
                                                    currencyCode: dst.currencyCode,
                                                    balance: dst.balance - transaction.amount * transaction.rate,
                                                    monthBudget: dst.monthBudget)
                }
                
                if let updatedSource, let sourceIndex {
                    state.accounts[sourceIndex] = updatedSource
                } else {
                    analytics.logEvent(.error("error, reverting transaction (possible account deletion) \(updatedSource?.name ?? "")"))
                }
                
                if let updatedDestination,
                    let destinationIndex,
                    let destinationType {
                    switch destinationType {
                    case .account:
                        state.accounts[destinationIndex] = updatedDestination
                        break
                    case .expenses:
                        state.expenses[destinationIndex] = updatedDestination
                        break
                    }
                } else {
                    analytics.logEvent(.error("error, reverting transaction (possible expense deletion) \(updatedDestination?.name ?? "")"))
                }
                
                return .run { [updatedSource, updatedDestination] send in
                    let items = [updatedSource, updatedDestination].compactMap { $0 }
                    guard items.count > 0 else { return }
                    await send(.saveWalletItemsToDB(items))
                    await send(.calculateBalanceAndBudget)
                    await send(.calculateExpenses)
                }
            case let .saveTransactionToDB(transaction):
                do {
                    try database.insert(WalletTransactionModel(model: transaction))
                    try database.save()
                } catch {
                    analytics.logEvent(.error("error, applying transaction to DB: \(error)"))
                }
                return .none
            case let .deleteTransaction(transactionID):
                return .run { send in
                    await send(.revertTransaction(transactionID))
                    await send(.deleteTransactionsFromDB([transactionID]))
                }
            case let .deleteTransactionsFromDB(transactionIds):
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
                let items = [state.accounts + state.expenses].flatMap { $0 }
                var transactions: [TransactionsListFeature.State.Period: [WalletTransaction]] = [:]
                
                let todayTransactions = state.transactions
                    .filter { $0.timestamp.isEqual(to: .now, toGranularity: .day) }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                
                let yesterdayTransactions = state.transactions
                    .filter { t in
                        Calendar.current.isDateInYesterday(t.timestamp) &&
                        !todayTransactions.contains(where: { today in today.id == t.id })
                    }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                let weekTransactions = state.transactions
                    .filter { $0.timestamp.isEqual(to: .now, toGranularity: .weekOfYear) }
                    .filter { t in
                        !todayTransactions.contains(where: { today in today.id == t.id }) &&
                        !yesterdayTransactions.contains(where: { today in today.id == t.id })
                    }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                let monthTransactions = state.transactions
                    .filter { $0.timestamp.isEqual(to: .now, toGranularity: .month) }
                    .filter { t in
                        !todayTransactions.contains(where: { today in today.id == t.id }) &&
                        !yesterdayTransactions.contains(where: { today in today.id == t.id }) &&
                        !weekTransactions.contains(where: { today in today.id == t.id })
                    }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                let allTransactions = state.transactions
                    .filter { $0.timestamp.isEqual(to: .now, toGranularity: .month) }
                    .filter { t in
                        !todayTransactions.contains(where: { today in today.id == t.id }) &&
                        !yesterdayTransactions.contains(where: { today in today.id == t.id }) &&
                        !weekTransactions.contains(where: { today in today.id == t.id }) &&
                        !monthTransactions.contains(where: { today in today.id == t.id })
                    }
                    .sorted(by: { $0.timestamp > $1.timestamp })
                
                transactions[.today] = todayTransactions
                transactions[.yesterday] = yesterdayTransactions
                transactions[.thisWeek] = weekTransactions
                transactions[.thisMonth] = monthTransactions
                transactions[.all] = allTransactions
                
                return .run { [period = state.spendings.period, transactions, items, currencies = state.currencies] send in
                    await send(.spendings(.recalculateAndPresentSpendings(period)))
                    await send(.transactionsList(.presentTransactionsList(transactions, items, currencies)))
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
                                                 currencyCode: item.currencyCode,
                                                 balance: item.balance,
                                                 monthBudget: item.monthBudget)
                        state.accounts[idx] = newItem
                    }
                    
                    for (idx, item) in state.expenses.enumerated() {
                        let newItem = WalletItem(id: item.id,
                                                 order: UInt(idx),
                                                 type: item.type,
                                                 name: item.name,
                                                 icon: item.icon,
                                                 currencyCode: item.currencyCode,
                                                 balance: item.balance,
                                                 monthBudget: item.monthBudget)
                        state.expenses[idx] = newItem
                    }
                    
                    return .run { [items = state.accounts + state.expenses] send in
                        await send(.saveWalletItemsToDB(items))
                    }
                    
                case .reordering:
                    return .none
                }
            case .resetDrag:
                state.draggingOffset = .zero
                state.dragItem = nil
                state.dropItem = nil
                return .none
                
                // MARK: - App Score
            case .appScore:
                return .none
                
                // MARK: - TransactionsList
            case let .transactionsList(.deleteTransaction(id)):
                return .send(.deleteTransaction(id))
            case .transactionsList:
                return .none
                
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
                let source = [state.accounts + state.expenses].flatMap({ $0 }).first(where: { $0.id == transaction.sourceID })
                let destination = [state.accounts + state.expenses].flatMap({ $0 }).first(where: { $0.id == transaction.destinationID })
                
                return .run { send in
                    if let source, let destination {
                        analytics.logEvent(
                            .transactionCreated(source: source.name,
                                                destination: destination.name,
                                                amount: transaction.amount,
                                                rate: transaction.rate))
                    }
                    await send(.applyTransaction(transaction))
                    await send(.saveTransactionToDB(transaction))
                    // TODO: check if need to ask AppScore
                }
            case .transaction:
                return .none
                
                // MARK: - WalletItemEdit
            case let .walletItemEdit(.deleteWalletItem(id, deleteTransactions)):
                let item = [state.accounts + state.expenses].flatMap { $0 }.first(where: { $0.id == id })
                // remove related transactions
                let transactionsToRemove = deleteTransactions ? state.transactions.filter { $0.sourceID == id || $0.destinationID == id } : []
                
                analytics.logEvent(.itemDeleted(name: item?.name ?? "",
                                                hasTransactions: !transactionsToRemove.isEmpty,
                                                deleteTransactions: deleteTransactions))
                
                return .run { [transactionsToRemove] send in
                    for t in transactionsToRemove {
                        // restore balance of affected accounts/expenses
                        await send(.revertTransaction(t.id))
                    }
                    // clear DB
                    await send(.deleteTransactionsFromDB(transactionsToRemove.map { $0.id }))
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
                                             currencyCode: item.currencyCode,
                                             balance: item.balance,
                                             monthBudget: item.monthBudget)
                
                switch item.type {
                case .account:
                    state.accounts.append(orderedItem)
                case .expenses:
                    state.expenses.append(orderedItem)
                }
                return .run { send in
                    analytics.logEvent(.itemCreated(name: orderedItem.name, icon: orderedItem.icon, currency: orderedItem.currencyCode))
                    await send(.saveWalletItemsToDB([orderedItem]))
                    await send(.calculateBalanceAndBudget)
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
                    await send(.saveWalletItemsToDB([item]))
                    await send(.calculateBalanceAndBudget)
                }
            case let .walletItemEdit(.deleteTransaction(transaction)):
                let items = [state.accounts + state.expenses].flatMap { $0 }
                if let source = items.first(where: { $0.id == transaction.sourceID }),
                   let destination = items.first(where: { $0.id == transaction.destinationID }) {
                    analytics.logEvent(.transactionDeleted(source: source.name,
                                                           destination: destination.name, amount: transaction.amount,
                                                           rate: transaction.rate))
                }
                
                return .run { send in
                    await send(.deleteTransaction(transaction.id))
                }
            case .walletItemEdit:
                return .none
            }
        }
    }
}

extension WalletFeature.State {
    
    enum ExpensesGranularity {
        case week, month
    }
}
