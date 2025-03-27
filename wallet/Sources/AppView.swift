//
//  AppView.swift
//  wallet
//
//  Created by Артём Зайцев on 23.03.2025.
//
import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<WalletFeature>
    
    init(store: StoreOf<WalletFeature>) {
        self.store = store
        store.send(.start)
    }
    
    public var body: some View {
        WalletView(store: store)
            .fullScreenCover(isPresented: $store.transaction.presented.sending(\.transaction.presentedChanged)) {
                TransactionView(store: store.scope(state: \.transaction, action: \.transaction))
            }
    }
}
