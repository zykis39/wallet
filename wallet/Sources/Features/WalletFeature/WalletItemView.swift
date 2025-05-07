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
        static let longPressDuration = 0.5
    }
    
    public var store: StoreOf<WalletFeature>
    private let item: WalletItem
    @State fileprivate var pressingClass: PressingClass = .init(pressing: false)
    @State private var shakeAnimationRunning: Bool = false
    private var tag: String? = nil
    
    struct ShakeAnimationProperties {
        var angle: Double = 0.0
    }

    private func currencyAmount(currencies: [Currency]) -> String {
        let currencySymbol: String = {
            guard let currency = currencies.first(where: { $0.code == item.currencyCode }) else { return item.currencyCode }
            return currency.fixedSymbol
        }()
        
        return (CurrencyFormatter.formatter.string(from: .init(value: item.balance)) ?? "") + " " + currencySymbol
    }
    
    private var simpleDrag: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .named("WalletSpace"))
            .onChanged({ [weak store] value in
                pressingClass.pressing = false
                store?.send(.onItemDragging(value.translation, value.location, value.time, item))
            })
            .onEnded { [weak store] _ in
                store?.send(.onDraggingStopped)
            }
    }
    
    public init(store: StoreOf<WalletFeature>, item: WalletItem, tag: String? = nil) {
        self.store = store
        self.item = item
        self.tag = tag
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(LocalizedStringKey(item.name))
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            ZStack {
                Circle()
                    .fill(Color.walletItemColor(for: item.type).opacity(0.2))
                    .gesture(simpleDrag)
                if let budget = item.monthBudget, budget > 0 {
                    // TODO: Optimization
                    let monthTransactions = store.state.transactions
                        .filter { $0.destinationID == item.id && $0.timestamp.isEqual(to: .now, toGranularity: .month) }
                    let spendings = monthTransactions.reduce(into: 0) {
                        $0 += $1.amount * $1.rate
                    }
                    let kSpent = min(1, spendings / budget)
                    Arc(angle: kSpent * 360, color: kSpent == 1 ? .yellow : .green)
                }
            }.frame(width: Constants.size, height: Constants.size)
                
            Text(currencyAmount(currencies: store.state.currencies))
                .foregroundStyle(Color.walletItemColor(for: item.type))
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .background {
            ZStack {
                Circle()
                    .stroke(.gray, lineWidth: 1)
                    .fill(.clear)
                    .frame(width: Constants.size, height: Constants.size)
            }
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
            .offset((store.state.dragItem == item && store.state.dragMode == .normal) ? store.state.draggingOffset : .zero)
            .animation(.easeInOut.speed(4), value: store.state.draggingOffset)
            Rectangle()
                .fill((store.state.dropItem == item) ? .green.opacity(0.2) : .clear)
                .cornerRadius(4)
                .padding(-4)
        }
        .opacity((store.state.dragItem == item &&
                  store.state.dragMode == .reordering &&
                  tag != "DragItem") ? 0.3 : 1)
        .onLongPressGesture(perform: {},
                            onPressingChanged: { [weak store] pressed in
            pressingClass.pressing = pressed
            if pressed {
                Task { [pressingClass] in
                    try? await Task.sleep(for: .seconds(Constants.longPressDuration))
                    if pressingClass.pressing {
                        store?.send(.dragModeChanged(.reordering))
                    }
                }
            }
        })
        .keyframeAnimator(initialValue: ShakeAnimationProperties(),
                          repeating: store.state.dragMode == .reordering && store.state.dragItem != item,
                          content: { content, value in
            content.rotationEffect(.degrees(value.angle), anchor: .center)
        }, keyframes: { _ in
            KeyframeTrack(\.angle) {
                SpringKeyframe(-3, duration: 0.15)
                SpringKeyframe(3, duration: 0.15)
            }
        })
        .onTapGesture { [weak store] in
            store?.send(.itemTapped(item))
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named("WalletSpace"))
        } action: { [weak store] newValue in
            guard tag == nil else { return }
            store?.send(.itemFrameChanged(item.id, newValue))
        }
    }
}

/// need a reference type to capture and cancel long press gesture
fileprivate class PressingClass {
    var pressing: Bool
    init(pressing: Bool) {
        self.pressing = pressing
    }
}
