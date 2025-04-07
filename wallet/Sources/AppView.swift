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
                    let scoped = store.scope(state: \.walletItemEdit, action: \.walletItemEdit)
                    WalletItemEditView(store: scoped)
                    .sheet(isPresented: $store.walletItemEdit.iconSelectionPresented.sending(\.walletItemEdit.iconSelectionPresentedChanged)) {
                        IconSelectionView(store: scoped)
                    }
                }
                .navigationDestination(isPresented: $store.settingsPresented.sending(\.settingsPresentedChanged)) {
                    SettingsView(store: store,
                                 selectedLocale: store.selectedLocale,
                                 selectedCurrency: store.selectedCurrency)
                        .navigationDestination(isPresented: $store.aboutAppPresented.sending(\.aboutAppPresentedChanged)) {
                            AboutApplicationView()
                        }
                }
                .navigationDestination(isPresented: $store.expensesStatisticsPresented.sending(\.expensesStatisticsPresentedChanged)) {
                    ExpensesStatisticsView(store: store)
                }
        }
    }
}
