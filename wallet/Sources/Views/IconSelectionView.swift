//
//  IconSelectionView.swift
//  wallet
//
//  Created by Артём Зайцев on 02.04.2025.
//
import ComposableArchitecture
import SwiftUI

struct IconSelectionView: View {
    var store: StoreOf<WalletItemEditFeature>
    init(store: StoreOf<WalletItemEditFeature>) {
        self.store = store
    }
    
    var icons: [String] {
        switch store.item.type {
        case .account:
            WalletItem.accountsSystemIconNames
        case .expenses:
            WalletItem.expensesSystemIconNames
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64, maximum: 80))]) {
                ForEach(icons, id: \.self) { icon in
                    ZStack {
                        Circle()
                            .fill(Color.walletItemColor(for: store.item.type))
                        Image(systemName: icon)
                            .resizable()
                            .foregroundStyle(.white)
                            .padding(16)
                            .clipShape(.circle)
                            .aspectRatio(contentMode: .fit)
                    }.onTapGesture {
                        store.send(.iconSelected(icon))
                    }
                }
            }
        }
        .padding(12)
    }
}
