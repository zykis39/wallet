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
        enum EditType {
            case new, edit
        }
        var editType: EditType
        var presented: Bool
        var item: WalletItem
        var transactions: [WalletTransaction]
        
        static let initial: Self = .init(editType: .new, presented: false, item: .none, transactions: [])
    }
    
    public enum Action: Sendable {
        case confirmedTapped
        case cancelTapped
        case presentedChanged(Bool)
        case nameChanged(String)
        case balanceChanged(Double)
        case currencyChanged(Currency)
        case createWalletItem(WalletItem)
        case updateWalletItem(WalletItem)
        case deleteWalletItem(UUID)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .confirmedTapped:
                return .run { [editType = state.editType, item = state.item] send in
                    switch editType {
                    case .edit: await send(.updateWalletItem(item))
                    case .new: await send(.createWalletItem(item))
                    }
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
            case let .balanceChanged(balance):
                state.item.balance = balance
                return .none
            case let .currencyChanged(currency):
                state.item.currency = currency
                return .none
                
            case .deleteWalletItem:
                return .none
            case .createWalletItem:
                return .none
            case .updateWalletItem:
                return .none
            }
        }
    }
}
