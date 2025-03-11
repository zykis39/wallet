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
        DragGesture()
            .onChanged({ value in
                offset = value.translation
            })
            .onEnded { _ in
                offset = .zero
            }
    }
    @State private var offset: CGSize = .zero
    
    public init(item: WalletItem) {
        self.item = item
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
        .border(.red)
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: .cash)
    }
}
