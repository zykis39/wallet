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
    
    @State var dragAmount: CGSize = .zero
    
    public init(item: WalletItem) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(item.name)
                .lineLimit(1)
            Circle()
                .fill(color)
                .draggable(item)
                .frame(width: 50, height: 50)
            Text(currencyAmount)
                .foregroundStyle(color)
        }
        .dropDestination(for: WalletItem.self, action: { items, location in
            return true
        })
        .border(Color.red)
    }
}


struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: .cash)
    }
}
