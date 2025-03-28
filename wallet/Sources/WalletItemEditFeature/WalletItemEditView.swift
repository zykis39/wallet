//
//  WalletItemEditView.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import ComposableArchitecture
import SwiftUI

struct WalletItemEditView: View {
    var store: StoreOf<WalletItemEditFeature>
    
    init(store: StoreOf<WalletItemEditFeature>) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            Header(leftSystemImageName: "xmark.circle.fill",
                   rightSystemImageName: "checkmark.circle.fill",
                   leftAction: { store.send(.presentedChanged(false)) },
                   rightAction: { store.send(.presentedChanged(false)) },
                   imageSize: 32)
            Spacer()
        }
        .padding()
        .tint(.white)
        .background(Color.walletItemColor(for: store.item.type))
    }
}
