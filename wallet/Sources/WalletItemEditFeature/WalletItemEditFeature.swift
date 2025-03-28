//
//  WalletItemEditFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import ComposableArchitecture
import SwiftUI

@Reducer
public struct WalletItemEditFeature {
    @ObservableState
    public struct State: Equatable {
        var presented: Bool
        var item: WalletItem
        
        static let initial: Self = .init(presented: false, item: .none)
    }
    
    public enum Action: Sendable {
        case confirmedTapped
        case cancelTapped
        case presentedChanged(Bool)
        case nameChanged(String)
        case currencyChanged(Currency)
        case createWalletItem(WalletItem)
        case updateWalletItem(UUID, WalletItem)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .confirmedTapped:
                return .run { send in
                    await send(.presentedChanged(false))
                }
            case .cancelTapped:
                return .run { send in
                    await send(.presentedChanged(false))
                }
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            case let .nameChanged(name):
                state.item.name = name
                return .none
            case let .currencyChanged(currency):
                state.item.currency = currency
                return .none
            case let .createWalletItem(item):
                return .none
            case let .updateWalletItem(id, item):
                return .none
            }
        }
    }
}
