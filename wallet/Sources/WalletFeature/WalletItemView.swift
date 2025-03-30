//
//  WalletItemView.swift
//  wallet
//
//  Created by Артём Зайцев on 08.03.2025.
//

import ComposableArchitecture
import SwiftUI

public struct WalletItemView: View {
    public var store: StoreOf<WalletFeature>
    private let item: WalletItem

    private var currencyAmount: String {
        let lessThenZero = item.balance < 0
        return (lessThenZero ? "-" : "") + "\(abs(Int(item.balance))) " + item.currency.representation
    }
    
    private var simpleDrag: some Gesture {
        DragGesture(coordinateSpace: .named("WalletSpace"))
            .onChanged({ [store] value in
                store.send(.onItemDragging(value.translation, value.location, item))
            })
            .onEnded { [store] _ in
                store.send(.onDraggingStopped)
            }
    }
    
    public init(store: StoreOf<WalletFeature>, item: WalletItem) {
        self.store = store
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(item.name)
                .lineLimit(1)
            Circle()
                .fill(Color.walletItemColor(for: item.type))
                .frame(width: 50, height: 50)
                .offset(store.state.dragItem == item ? store.state.draggingOffset : .zero)
            Text(currencyAmount)
                .foregroundStyle(Color.walletItemColor(for: item.type))
                .lineLimit(1)
        }
        .background {
            Rectangle()
                .fill((store.state.dropItem == item) ? .green.opacity(0.2) : .clear)
                .cornerRadius(4)
                .padding(-4)
        }
        .gesture(simpleDrag)
        .onTapGesture {
            store.send(.itemTapped(item))
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named("WalletSpace"))
        } action: { newValue in
            store.send(.itemFrameChanged(item, newValue))
        }
    }
}
