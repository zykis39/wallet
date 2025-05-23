//
//  AccountsView.swift
//  wallet
//
//  Created by Артём Зайцев on 13.04.2025.
//
import ComposableArchitecture
import SwiftUI

struct AccountsView: View {
    private struct Constants {
        static let itemsInRow: Int = 4
        static let minElementWidth: CGFloat = 80
        static let maxElementWidth: CGFloat = 120
    }
    
    @Bindable var store: StoreOf<WalletFeature>

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading) {
                ScrollView(.horizontal) {
                    HStackEqualSpacing(pageWidth: proxy.size.width,
                                       columnsNumber: Constants.itemsInRow,
                                       minElementWidth: Constants.minElementWidth,
                                       maxElementWidth: Constants.maxElementWidth,
                                       offset: -10) {
                        ForEach(store.state.accounts, id: \.self) { item in
                            WalletItemView(store: store,
                                           item: item)
                        }
                        AddButton(color: .yellow) { [weak store] in
                            store?.send(.createNewItemTapped(.account))
                        }
                    }
                }
                .scrollDisabled(store.state.accounts.count < Constants.itemsInRow)
                .scrollClipDisabled(true)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition($store.accountsScrollPosition.sending(\.accountsScrollPositionChanged))
            }
        }
    }
}

//#Preview {
//    AccountsView(store: .init(initialState: WalletFeature.State(transaction: .initial, walletItemEdit: .initial, spendings: .initial, balance: 0, monthExpenses: 0, accounts: [.card, .cash], expenses: [], transactions: []), reducer: {
//        WalletFeature()
//    }))
//}
