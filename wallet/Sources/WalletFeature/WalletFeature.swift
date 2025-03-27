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
                                         accounts: [],
                                         expenses: [],
                                         transactions: [])
    }
    
    public enum Action: Sendable {
        // child
        case transaction(TransactionFeature.Action)
        
        // internal
        case start
        case readWalletItems
        case readTransactions
        case saveWalletItems
        case saveTransactions
        case generateDefaultWalletItems
        case applyTransaction(WalletTransaction)
        
        // view
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
    }
    
    @Dependency(\.defaultAppStorage) var appStorage
    public var body: some Reducer<State, Action> {
        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
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
                return .none
            case .saveTransactions:
                return .none
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
            case let .applyTransaction(transaction):
                /// FIXME:
                /// транзакции не должны применяться частично в случае ошибок
                /// обновления состояния массивов [WalletItem] не происходит без смены \.id
                if let sourceIndex = state.accounts.firstIndex(where: { $0.id == transaction.source.id })
                    {
                    let newID = UUID()
                    state.accounts[sourceIndex].id = newID
                    state.accounts[sourceIndex].balance -= transaction.amount
                }
                if let destinationIndex = state.expenses.firstIndex(where: { $0.id == transaction.destination.id }) {
                    let newID = UUID()
                    state.expenses[destinationIndex].id = newID
                    state.expenses[destinationIndex].balance += transaction.amount
                } else if let destinationIndex = state.accounts.firstIndex(where: { $0.id == transaction.destination.id }) {
                    let newID = UUID()
                    state.accounts[destinationIndex].id = newID
                    state.accounts[destinationIndex].balance += transaction.amount
                }
                return .none
                
                // MARK: - Child
            case let .transaction(.createTransaction(transaction)):
                state.transactions.append(transaction)
                return .run { send in
                    await send(.applyTransaction(transaction))
                }
            case .transaction:
                return .none
            }
        }
    }
}
