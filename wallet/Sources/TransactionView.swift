//
//  TransactionView.swift
//  wallet
//
//  Created by Артём Зайцев on 23.03.2025.
//

import ComposableArchitecture
import SwiftUI

struct TransactionView: View {
    weak var store: StoreOf<WalletFeature>!
    init(store: StoreOf<WalletFeature>? = nil) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            /// Навигационный тулбар
            HStack {
                Button {
                    store.send(.closeTransaction(false))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Button {
                    store.send(.closeTransaction(true))
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }
            Spacer()
            HStack {
                Text(store.transactionState.transaction.source.name)
                Text(store.transactionState.transaction.destination.name)
            }
            Text("\(store.transactionState.transaction.amount)")
            Spacer()
        }
        .padding()
        .tint(.gray)
    }
}
