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
    private let geometry: GeometryProxy

    private var color: Color {
        switch item.type {
        case .account: return .yellow
        case .expenses: return .green
        }
    }
    
    private var currencyAmount: String {
        item.currency.representation + " \(Int(item.amount))"
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
    
    public init(store: StoreOf<WalletFeature>, item: WalletItem, geometry: GeometryProxy) {
        self.store = store
        self.item = item
        self.geometry = geometry
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(item.name)
                .lineLimit(1)
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .offset(store.state.dragItem == item ? store.state.draggingOffset : .zero)
            Text(currencyAmount)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .background {
            Rectangle()
                .fill((store.state.dropItem == item) ? .green.opacity(0.2) : .clear)
                .stroke((store.state.dragItem == item) ? .yellow : .clear,
                        style: .init(lineWidth: 2, lineCap: .butt, lineJoin: .miter, miterLimit: 4, dash: [5, 10], dashPhase: 0))
                .padding(-4)
        }
        .gesture(simpleDrag)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named("WalletSpace"))
        } action: { newValue in
            store.send(.itemFrameChanged(item, newValue))
        }
        .border(.red)
    }
}
