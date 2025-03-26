//
//  WalletFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct WalletFeature {
    @ObservableState
    public struct State: Equatable {
        var transaction: TransactionFeature.State
        var accounts: [WalletItem]
        var expences: [WalletItem]
        
        var itemFrames: [WalletItem: CGRect] = [:]
        var draggingOffset: CGSize = .zero
        var dropLocation: CGPoint = .zero
        var dragItem: WalletItem?
        var dropItem: WalletItem?
        
        static let initial: Self = .init(transaction: .initial,
                                         accounts: WalletItem.defaultAccounts,
                                         expences: WalletItem.defaultExpenses)
    }
    
    public enum Action: Sendable {
        case transaction(TransactionFeature.Action)
        
        // view
        case itemFrameChanged(WalletItem, CGRect)
        case onItemDragging(CGSize, CGPoint, WalletItem)
        case onDraggingStopped
    }
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.transaction, action: \.transaction) {
            TransactionFeature()
        }
        Reduce { state, action in
            switch action {
            case let .itemFrameChanged(item, frame):
                state.itemFrames[item] = frame
                return .none
            case let .onItemDragging(offset, point, item):
                state.draggingOffset = offset
                state.dropLocation = point
                state.dragItem = item

                let droppingItemFrames = state.itemFrames.filter { $0.value.contains(point) }
                state.dropItem = droppingItemFrames.keys.first
                return .none
            case .onDraggingStopped:
                let dragItem = state.dragItem
                let dropItem = state.dropItem
                
                state.draggingOffset = .zero
                state.dropLocation = .zero
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
