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
        
        var currency: Currency
        var amount: Int
        var source: WalletItem
        var destination: WalletItem
        
        static let initial: Self = .init(presented: false, currency: .RUB, amount: 0, source: .none, destination: .none)
    }
    
    public enum Action: Sendable {
        case presentedChanged(Bool)
        case amountChanged(Int)
        case onItemDropped(WalletItem, WalletItem)
        case createTransaction(WalletTransaction)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onItemDropped(source, destination):
                state.source = source
                state.destination = destination
                return .run { send in
                    await send(.presentedChanged(true))
                }
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            case let .createTransaction(transaction):
                return .none
            case let .amountChanged(amount):
                state.amount = amount
                return .none
            }
        }
    }
}
