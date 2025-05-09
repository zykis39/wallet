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
    var scoped: StoreOf<SpendingsFeature>
    @State var tabSelection: String = "Transactions"
    
    init(store: StoreOf<WalletFeature>) {
        self.store = store
        self.scoped = store.scope(state: \.spendings, action: \.spendings)
    }
    
    var body: some View {
        TabView(selection: $tabSelection) {
            Tab("Transactions".localized(),
                systemImage: "chart.bar.horizontal.page.fill",
                value: "Transactions".localized()) {
                TransactionsListView(store: store)
            }
            Tab("Spendings".localized(),
                systemImage: "chart.pie.fill",
                value: "Spendings".localized()) {
                SpendingsStatisticsView(store: scoped)
            }
        }
        .navigationTitle(tabSelection.localized())
    }
}
