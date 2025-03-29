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
        case saveTransactions
        case generateDefaultWalletItems
        case applyTransaction(WalletTransaction)
        case reverseTransaction(WalletTransaction)
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
                    state.transactions = transactions
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
                state.walletItemEdit.editType = .edit
                state.walletItemEdit.item = item
                state.walletItemEdit.transactions = state.transactions.filter {
                    $0.source.id == item.id || $0.destination.id == item.id
                }
                state.walletItemEdit.presented = true
                return .none
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
                return .none
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
            case .saveTransactions:
                do {
                    let encoder = JSONEncoder()
                    let encodedTransactions = try state.transactions.compactMap { try encoder.encode($0) }
                    appStorage.set(encodedTransactions, forKey: AppStorageKey.transactions.rawValue)
                } catch {
                    print("error encoding transactions: \(error.localizedDescription)")
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
                
                // clear DB
                return .run { [transactionsToRemove] send in
                    for t in transactionsToRemove {
                        // restore balance of affected accounts/expenses
                        await send(.reverseTransaction(t))
                    }
                    await send(.saveTransactions)
                    await send(.saveWalletItems)
                    await send(.walletItemEdit(.presentedChanged(false)))
                }
            case let .walletItemEdit(.createWalletItem(item)):
                return .none
            case let .walletItemEdit(.updateWalletItem(id, item)):
                return .none
            case .walletItemEdit:
                return .none
            }
        }
    }
}
