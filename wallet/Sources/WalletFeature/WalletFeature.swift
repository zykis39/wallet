//
//  WalletFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import ComposableArchitecture

@Reducer
public struct WalletFeature {
    
    @ObservableState
    public struct State: Equatable {
        public struct TransactionState: Equatable {
            var transactionPresented: Bool
            var transaction: WalletTransaction
            
            static let initial: Self = .init(transactionPresented: false, transaction: .init(currency: .RUB, amount: 0, source: .none, destination: .none))
        }
        
        var accounts: [WalletItem]
        var expences: [WalletItem]
        var transactionState: TransactionState
        var transactionPresented: Bool
        
        static let initial: Self = .init(accounts: WalletItem.defaultAccounts, expences: WalletItem.defaultExpenses, transactionState: .initial, transactionPresented: false)
    }
    
    public enum Action: BindableAction {
        case onItemDropped(WalletItem, WalletItem)
        case createTransaction(WalletTransaction)
        case binding(BindingAction<State>)
        
        case closeTransaction(Bool)
    }
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case let .createTransaction(transaction):
                print("transaction from \(transaction.source.name) to \(transaction.destination.name) with \(transaction.currency)\(transaction.amount)")
                return .none
            case let .onItemDropped(source, destination):
                print("dragged \(source.name) to \(destination.name)")
                state.transactionState.transaction = .init(currency: .RUB, amount: 0, source: source, destination: destination)
                state.transactionState.transactionPresented = true
                return .none
            case let .closeTransaction(ok):
                state.transactionState.transactionPresented = false
                print("close transaction: \(ok ? "confirm" : "cancel")")
                return .none
            case .binding:
                return .none
            }
        }
    }
}
