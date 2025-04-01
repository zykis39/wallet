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
        case createNewItemTapped(WalletItem.WalletItemType)
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
        case itemTapped(WalletItem)
        
        // navigation
        case aboutButtonTapped
        case addMoneyButtonTapped
    }
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.modelContext) var modelContext
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
                    analytics.logEvent(.appStarted(firstLaunch: !wasLaunchedBefore))
                    if !wasLaunchedBefore {
                        await send(.generateDefaultWalletItems)
                        appStorage.set(true, forKey: AppStorageKey.wasLaunchedBefore.rawValue)
                    } else {
                        await send(.readWalletItems)
                        await send(.readTransactions)
                    }
                }
            case .readWalletItems:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let itemDescriptor = FetchDescriptor<WalletItemModel>(predicate: #Predicate<WalletItemModel> { _ in true }, sortBy: [ .init(\.model.timestamp, order: .forward) ])
                do {
                    let accounts = try modelContext.fetch<WalletItemModel>(itemDescriptor).map { $0.model }.filter { $0.type == .account }
                    let expenses = try modelContext.fetch<WalletItemModel>(itemDescriptor).map { $0.model }.filter { $0.type == .expenses }
                    state.accounts = accounts
                    state.expenses = expenses
                } catch {
                    print("WalletItem decoding error: \(error.localizedDescription)")
                }
                
                return .none
            case .saveWalletItems:
                let models = [state.accounts, state.expenses].flatMap { $0 }.map { WalletItemModel(model: $0) }
                for m in models {
                    modelContext.insert(m)
                }
                
                return .none
            case .readTransactions:
                /// FIXME: Predicates cause runtime error, when dealing with Enums
                /// So, filtering happens outside SwiftData, in-memory
                let transactionsDescriptor = FetchDescriptor<WalletTransactionModel>(predicate: #Predicate<WalletTransactionModel> { _ in true }, sortBy: [])
                
                do {
                    let transactions = try modelContext.fetch<WalletTransactionModel>(transactionsDescriptor).map { $0.model }
                    
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
                modelContext.insert(WalletTransactionModel(model: transaction))
                return .none
            case .saveTransactions:
                for t in state.transactions {
                    modelContext.insert(WalletTransactionModel(model: t))
                }
                return .none
            case let .createNewItemTapped(itemType):
                state.walletItemEdit.editType = .new
                state.walletItemEdit.item = .none
                state.walletItemEdit.item.type = itemType
                state.walletItemEdit.presented = true
                return .none
            case .aboutButtonTapped:
                return .none
            case .addMoneyButtonTapped:
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
                        await send(.reverseTransaction(t))
                    }
                    // clear DB
                    await send(.saveTransactions)
                    await send(.saveWalletItems)
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
                    analytics.logEvent(.itemCreated(itemName: item.name, currency: item.currency.representation))
                    await send(.saveWalletItems)
                }
            case let .walletItemEdit(.updateWalletItem(id, item)):
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
