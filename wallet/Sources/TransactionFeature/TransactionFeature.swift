//
//  TransactionFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 25.03.2025.
//
import ComposableArchitecture
import SwiftUI

@Reducer
public struct TransactionFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var presented: Bool
        
        var amount: Double
        var source: WalletItem
        var destination: WalletItem
        
        static let initial: Self = .init(presented: false, amount: 0, source: .none, destination: .none)
    }
    
    public enum Action: Sendable {
        // internal
        case onItemDropped(WalletItem, WalletItem)
        case createTransaction(WalletTransaction)
        
        // view
        case cancelTapped
        case confirmTapped
        case presentedChanged(Bool)
        case amountChanged(Double)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .confirmTapped:
                return .run { [state] send in
                    await send(.presentedChanged(false))
                    guard state.amount > 0 else { return }
                    
                    let transaction = WalletTransaction(timestamp: .now, currency: state.source.currency, amount: state.amount, source: state.source, destination: state.destination)
                    await send(.createTransaction(transaction))
                }
            case .cancelTapped:
                return .run { send in
                    await send(.presentedChanged(false))
                }
            case let .onItemDropped(source, destination):
                state.source = source
                state.destination = destination
                return .run { send in
                    await send(.presentedChanged(true))
                }
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            case .createTransaction:
                return .none
            case let .amountChanged(amount):
                state.amount = amount
                return .none
            }
        }
    }
}
