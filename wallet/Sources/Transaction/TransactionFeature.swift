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
        public var transaction: WalletTransaction
        
        static let initial: Self = .init(presented: false, transaction: .empty)
    }
    
    public enum Action: Sendable {
        case onItemDropped(WalletItem, WalletItem)
        case presentedChanged(Bool)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onItemDropped(source, destination):
                state.transaction = .init(currency: .RUB, amount: 0, source: source, destination: destination)
                return .run { send in
                    await send(.presentedChanged(true))
                }
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            }
        }
    }
}
