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
    }
    
    public var body: some View {
        ZStack {
            WalletView(store: store)
                .fullScreenCover(isPresented: $store.transactionState.transactionPresented) {
                    TransactionView(store: store)
                }
        }
    }
}
