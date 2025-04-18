//
//  WalletItemView.swift
//  wallet
//
//  Created by Артём Зайцев on 08.03.2025.
//

import ComposableArchitecture
import SwiftUI

public struct WalletItemView: View {
    private struct Constants {
        static let size: CGFloat = 64
        static let imageSize: CGFloat = 42
    }
    
    public var store: StoreOf<WalletFeature>
    private let item: WalletItem

    private var currencyAmount: String {
        (CurrencyFormatter.formatter.string(from: .init(value: item.balance)) ?? "") + " " + item.currency.fixedSymbol
    }
    
    private var simpleDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
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
        VStack(alignment: .center, spacing: 4) {
            Text(LocalizedStringKey(item.name))
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Circle()
                .fill(Color.walletItemColor(for: item.type).opacity(0.2))
                .frame(width: Constants.size, height: Constants.size)
                .highPriorityGesture(simpleDrag)
            Text(currencyAmount)
                .foregroundStyle(Color.walletItemColor(for: item.type))
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .background {
            Circle()
                .stroke(.gray, lineWidth: 1)
                .fill(.clear)
                .frame(width: Constants.size, height: Constants.size)
            ZStack {
                Circle()
                    .fill(Color.walletItemColor(for: item.type))
                    .frame(width: Constants.size, height: Constants.size)
                Image(systemName: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .foregroundStyle(.white)
            }
            .offset(store.state.dragItem == item ? store.state.draggingOffset : .zero)
            .animation(.easeInOut.speed(4), value: store.state.draggingOffset)
            Rectangle()
                .fill((store.state.dropItem == item) ? .green.opacity(0.1) : .clear)
                .cornerRadius(4)
                .padding(-4)
        }
        .onTapGesture {
            store.send(.itemTapped(item))
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { newValue in
            store.send(.itemFrameChanged(item, newValue))
        }
    }
}
