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

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
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
                .sheet(isPresented: $store.appScore.presented.sending(\.appScore.presentedChanged), content: {
                    let scoped = store.scope(state: \.appScore, action: \.appScore)
                    AppScore(store: scoped)
                    .presentationDetents([.medium])
                })
                .navigationDestination(isPresented: $store.settingsPresented.sending(\.settingsPresentedChanged)) {
                    SettingsView(store: store,
                                 selectedLocale: store.selectedLocale,
                                 selectedCurrency: store.selectedCurrency,
                                 isReorderButtonVisible: store.isReorderButtonHidden,
                    )
                    .navigationDestination(isPresented: $store.aboutAppPresented.sending(\.aboutAppPresentedChanged)) {
                        AboutApplicationView()
                    }
                }
                .navigationDestination(isPresented: $store.spendings.presented.sending(\.spendings.presentedChanged)) {
                    TransactionsSpendingsView(store: store)
                }
        }
        .environment(\.locale, store.selectedLocale)
    }
}
