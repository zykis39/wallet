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
        var transaction: TransactionFeature.State
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
        // internal
        case start
        case readWalletItems
        case readTransactions
        case saveWalletItems
        case saveTransaction(WalletTransaction)
        case generateDefaultWalletItems
        
        // view
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
        
        // child
        case transaction(TransactionFeature.Action)
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
            case .readTransactions:
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
            case let .saveTransaction(transaction):
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
                state.dropItem = droppingItemFrames.keys.first
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
            case .transaction:
                return .none
            }
        }
    }
}
