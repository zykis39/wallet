//
//  WalletItemView.swift
//  wallet
//
//  Created by Артём Зайцев on 08.03.2025.
//

import SwiftUI

public struct WalletItemView: View {
    private let item: WalletItem
    private let highlighted: Bool
    private let globalDropLocation: CGPoint?
    @Environment(\.dropItem) private var dropItem: WalletItem?
    @State private var offset: CGSize = .zero
    @State private var globalLocation: CGPoint = .zero
    @State private var isItemDraggedOver: Bool = false
    
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
            .onChanged({ value in
                offset = value.translation
                globalLocation = value.location
            })
            .onEnded { _ in
                print("dragged \(item.name) to \(dropItem?.name ?? "")")
                // TODO: perform drop action source->destination
                offset = .zero
            }
    }
    
    public init(item: WalletItem, highlighted: Bool, globalDropLocation: CGPoint? = nil) {
        self.item = item
        self.highlighted = highlighted
        self.globalDropLocation = globalDropLocation
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(item.name)
                .lineLimit(1)
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .offset(offset)
            Text(currencyAmount)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .background {
            GeometryReader { geometry in
                Rectangle()
                    .fill((dropItem == item) ? .green.opacity(0.2) : .clear)
                    .stroke(highlighted ? .yellow : .clear,
                            style: .init(lineWidth: 2, lineCap: .butt, lineJoin: .miter, miterLimit: 4, dash: [5, 10], dashPhase: 0))
                    .padding(-4)
                    .preference(key: WalletItemDropPreferenceKey.self, value: (geometry.frame(in: .named("WalletSpace")).contains(globalDropLocation ?? .zero)) ? .init(item: item) : .init(item: nil))
            }
        }
        .gesture(simpleDrag)
        .border(.red)
        .preference(key: WalletItemDragPreferenceKey.self, value: offset == .zero ? .empty : .init(item: item, location: globalLocation))
    }
}

struct WalletItemDragPreferenceData: Equatable {
    let item: WalletItem?
    let location: CGPoint
    
    static let empty: Self = .init(item: nil, location: .zero)
}

struct WalletItemDragPreferenceKey: PreferenceKey {
    typealias Value = WalletItemDragPreferenceData
    
    static var defaultValue: WalletItemDragPreferenceData = .init(item: nil, location: .zero)
    static func reduce(value: inout WalletItemDragPreferenceData, nextValue: () -> WalletItemDragPreferenceData) {
        guard let _ = nextValue().item else { return }
        value = nextValue()
    }
}

struct WalletItemDropPreferenceData: Equatable {
    let item: WalletItem?
    
    static let empty: Self = .init(item: nil)
}


struct WalletItemDropPreferenceKey: PreferenceKey {
    typealias Value = WalletItemDropPreferenceData
    
    static var defaultValue: WalletItemDropPreferenceData = .init(item: nil)
    static func reduce(value: inout WalletItemDropPreferenceData, nextValue: () -> WalletItemDropPreferenceData) {
        guard let _ = nextValue().item else { return }
        value = nextValue()
    }
}


struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: .cash, highlighted: true)
    }
}
