//
//  TransactionsSpendingsView.swift
//  wallet
//
//  Created by Артём Зайцев on 07.05.2025.
//

import ComposableArchitecture
import SwiftUI

struct TransactionsSpendingsView: View {
    var store: StoreOf<WalletFeature>
    var spendingsStore: StoreOf<SpendingsFeature>
    var transactionsListStore: StoreOf<TransactionsListFeature>
    @State var tabSelection: String = "Transactions"
    
    init(store: StoreOf<WalletFeature>) {
        self.store = store
        self.spendingsStore = store.scope(state: \.spendings, action: \.spendings)
        self.transactionsListStore = store.scope(state: \.transactionsList, action: \.transactionsList)
    }
    
    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("Transactions".localized(),
                systemImage: "chart.bar.horizontal.page.fill",
                value: "Transactions".localized()) {
                TransactionsListView(store: transactionsListStore)
            }
            Tab("Spendings".localized(),
                systemImage: "chart.pie.fill",
                value: "Spendings".localized()) {
                SpendingsView(store: spendingsStore)
            }
        }
        .navigationTitle(tabSelection.localized())
    }
}
