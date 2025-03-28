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
        case presentedChanged(Bool)
        case createWalletItem(WalletItem)
        case updateWalletItem(UUID, WalletItem)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            default:
                return .none
            }
        }
    }
}
