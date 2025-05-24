//
//  TransactionsListFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 24.05.2025.
//

import Foundation
import ComposableArchitecture


@Reducer
public struct TransactionsListFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public enum Period: Hashable, Sendable {
            case today, yesterday, thisWeek, thisMonth, all
        }
        
        var transactions: [Period: [WalletTransaction]]
        var items: [WalletItem]
        var currencies: [Currency]
        
        public static let initial: Self = .init(transactions: [:], items: [], currencies: [])
    }
    
    public enum Action: Sendable {
        case presentTransactionsList([State.Period: [WalletTransaction]], [WalletItem], [Currency])
        case deleteTransaction(UUID)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentTransactionsList(transactions, items, currencies):
                state.transactions = transactions
                state.items = items
                state.currencies = currencies
                return .none
            case .deleteTransaction:
                return .none
            }
        }
    }
}
