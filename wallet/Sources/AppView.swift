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
        NavigationStack {
            WalletView(store: store)
                .fullScreenCover(isPresented: $store.transaction.presented.sending(\.transaction.presentedChanged)) {
                    TransactionView(store: store.scope(state: \.transaction, action: \.transaction))
                }
                .fullScreenCover(isPresented: $store.walletItemEdit.presented.sending(\.walletItemEdit.presentedChanged)) {
                    WalletItemEditView(store: store.scope(state: \.walletItemEdit, action: \.walletItemEdit))
                }
                .navigationDestination(isPresented: $store.aboutAppPresented.sending(\.aboutAppPresentedChanged)) {
                    AboutApplicationView()
                }
                .navigationDestination(isPresented: $store.expensesStatisticsPresented.sending(\.expensesStatisticsPresentedChanged)) {
                    ExpensesStatisticsView(store: store)
                }
        }
    }
}
