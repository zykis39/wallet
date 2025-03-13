//
//  WalletItemView.swift
//  wallet
//
//  Created by Артём Зайцев on 08.03.2025.
//

import SwiftUI

public struct WalletItemView: View {
    private var item: WalletItem
    
    private var color: Color {
        switch item.type {
        case .account: return .yellow
        case .expenses: return .green
        }
    }
    private var currencyAmount: String {
        item.currency.representation + " \(Int(item.amount))"
    }
    
    var simpleDrag: some Gesture {
        DragGesture(coordinateSpace: .named("WalletSpace"))
            .onChanged({ value in
                offset = value.translation
                globalLocation = value.location
            })
            .onEnded { _ in
                offset = .zero
            }
    }
    @State private var offset: CGSize = .zero
    @State private var globalLocation: CGPoint = .zero
    private let highlighted: Bool
    
    public init(item: WalletItem, highlighted: Bool) {
        self.item = item
        self.highlighted = highlighted
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
        .gesture(simpleDrag)
        .border(highlighted ? .green : .red)
        .preference(key: WalletItemPreferenceKey.self, value: offset == .zero ? .empty : .init(item: item, location: globalLocation))
    }
}

struct WalletItemPreferenceData: Equatable {
    let item: WalletItem?
    let location: CGPoint
    
    static let empty: Self = .init(item: nil, location: .zero)
}

struct WalletItemPreferenceKey: PreferenceKey {
    typealias Value = WalletItemPreferenceData
    
    static var defaultValue: WalletItemPreferenceData = .init(item: nil, location: .zero)
    static func reduce(value: inout WalletItemPreferenceData, nextValue: () -> WalletItemPreferenceData) {
        guard let _ = nextValue().item else { return }
        value = nextValue()
    }
}


struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: .cash, highlighted: true)
    }
}
