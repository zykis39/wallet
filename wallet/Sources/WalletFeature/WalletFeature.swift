//
//  WalletFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import ComposableArchitecture
import Foundation

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
        var accounts: [WalletItem]
        var expenses: [WalletItem]
        var transactions: [WalletTransaction]
        
        // drag and drop
        var itemFrames: [WalletItem: CGRect] = [:]
        var draggingOffset: CGSize = .zero
        var dragItem: WalletItem?
        var dropItem: WalletItem?
        
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
        case readWalletItems
        case readTransactions
        case saveWalletItems
        case generateDefaultWalletItems
        case applyTransaction(WalletTransaction)
        case saveTransaction(WalletTransaction)
        
        // view
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
        case itemTapped(WalletItem)
    }
    
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
                let wasLaunchedBefore = appStorage.bool(forKey: AppStorageKey.wasLaunchedBefore.rawValue)
                
                return .run { send in
                    if !wasLaunchedBefore {
                        await send(.generateDefaultWalletItems)
                        appStorage.set(true, forKey: AppStorageKey.wasLaunchedBefore.rawValue)
                    } else {
                        await send(.readWalletItems)
                        await send(.readTransactions)
                    }
                }
            case .readWalletItems:
                do {
                    if let encodedAccounts = (appStorage.array(forKey: AppStorageKey.accounts.rawValue)) {
                        state.accounts = try encodedAccounts.compactMap {
                            guard let itemData = $0 as? Data else { return nil }
                            
                            let decoder = JSONDecoder()
                            return try decoder.decode(WalletItem.self, from: itemData)
                        }
                    }
                    if let encodedExpenses = (appStorage.array(forKey: AppStorageKey.expenses.rawValue)) {
                        state.expenses = try encodedExpenses.compactMap {
                            guard let itemData = $0 as? Data else { return nil }
                            
                            let decoder = JSONDecoder()
                            return try decoder.decode(WalletItem.self, from: itemData)
                        }
                    }
                } catch {
                    print("WalletItem decoding error: \(error.localizedDescription)")
                }
                return .none
            case .saveWalletItems:
                do {
                    let encodedAccounts = try state.accounts.map {
                        let encoder = JSONEncoder()
                        return try encoder.encode($0)
                    }
                    let encodedExpenses = try state.expenses.map {
                        let encoder = JSONEncoder()
                        return try encoder.encode($0)
                    }
                    appStorage.set(encodedAccounts, forKey: AppStorageKey.accounts.rawValue)
                    appStorage.set(encodedExpenses, forKey: AppStorageKey.expenses.rawValue)
                } catch {
                    print("WalletItem encoding error: \(error.localizedDescription)")
                }
                
                return .none
            case .readTransactions:
                do {
                    let decoder = JSONDecoder()
                    let transactionsData = appStorage.array(forKey: AppStorageKey.transactions.rawValue)?.compactMap { $0 as? Data } ?? []
                    let transactions = try transactionsData.compactMap { try decoder.decode(WalletTransaction.self, from: $0) }
                    return .run { [transactions] send in
                        for transaction in transactions {
                            await send(.applyTransaction(transaction))
                        }
                    }
                } catch {
                    print("Transaction decoding error: \(error.localizedDescription)")
                    return .none
                }
            case .generateDefaultWalletItems:
                state.accounts = WalletItem.defaultAccounts
                state.expenses = WalletItem.defaultExpenses
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
                    await send(.transaction(.onItemDropped(dragItem, dropItem)))
                }
            case let .itemTapped(item):
                state.walletItemEdit.item = item
                state.walletItemEdit.presented = true
                return .none
            case let .applyTransaction(transaction):
                /// FIXME:
                /// транзакции не должны применяться частично в случае ошибок
                /// обновления состояния массивов [WalletItem] не происходит без смены \.id
                /// при сравнении нужно завязаться на \.id, но это приведет к ошибкам на текущий момент
                if let sourceIndex = state.accounts.firstIndex(where: { $0.name == transaction.source.name })
                    {
                    let newID = UUID()
                    state.accounts[sourceIndex].id = newID
                    state.accounts[sourceIndex].balance -= transaction.amount
                }
                if let destinationIndex = state.expenses.firstIndex(where: { $0.name == transaction.destination.name }) {
                    let newID = UUID()
                    state.expenses[destinationIndex].id = newID
                    state.expenses[destinationIndex].balance += transaction.amount
                } else if let destinationIndex = state.accounts.firstIndex(where: { $0.name == transaction.destination.name }) {
                    let newID = UUID()
                    state.accounts[destinationIndex].id = newID
                    state.accounts[destinationIndex].balance += transaction.amount
                }
                return .none
            case let .saveTransaction(transaction):
                let decoder = JSONDecoder()
                let encoder = JSONEncoder()
                do {
                    // decode all
                    let transactionsData = appStorage.array(forKey: AppStorageKey.transactions.rawValue)?.compactMap { $0 as? Data } ?? []
                    var transactions = try transactionsData.compactMap { try decoder.decode(WalletTransaction.self, from: $0) }
                    // append
                    transactions.append(transaction)
                    // encode all
                    let encodedTransactions = try transactions.compactMap { try encoder.encode($0) }
                    appStorage.set(encodedTransactions, forKey: AppStorageKey.transactions.rawValue)
                } catch {
                    print("Transaction decoding/encoding error: \(error.localizedDescription)")
                }
                return .none
                
                // MARK: - Transaction
            case let .transaction(.createTransaction(transaction)):
                state.transactions.append(transaction)
                return .run { send in
                    await send(.applyTransaction(transaction))
                    await send(.saveTransaction(transaction))
                }
            case .transaction:
                return .none
                
                // MARK: - WalletItemEdit
            case .walletItemEdit:
                return .none
            }
        }
    }
}
