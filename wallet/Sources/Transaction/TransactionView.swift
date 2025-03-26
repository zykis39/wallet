//
//  TransactionView.swift
//  wallet
//
//  Created by Артём Зайцев on 23.03.2025.
//

import ComposableArchitecture
import SwiftUI

struct TransactionView: View {
    var store: StoreOf<TransactionFeature>
    init(store: StoreOf<TransactionFeature>) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    store.send(.presentedChanged(false))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Spacer()
                Button {
                    store.send(.presentedChanged(false))
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }
            Spacer()
            HStack {
                Text(store.state.transaction.source.name)
                Text(store.state.transaction.destination.name)
            }
            Text("\(store.state.transaction.amount)")
            Spacer()
        }
        .padding()
        .tint(.gray)
    }
}
