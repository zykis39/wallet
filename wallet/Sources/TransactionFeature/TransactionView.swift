//
//  TransactionView.swift
//  wallet
//
//  Created by Артём Зайцев on 23.03.2025.
//

import ComposableArchitecture
import SwiftUI
import CurrencyField

struct TransactionView: View {
    @Bindable var store: StoreOf<TransactionFeature>
    init(store: StoreOf<TransactionFeature>) {
        self.store = store
    }
    
    @FocusState var focused: Bool
    private var formatter: NumberFormatter {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        fmt.locale = Locale(identifier: "ru_RU")
        return fmt
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    store.send(.cancelTapped)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                Text(store.state.source.name)
                Spacer()
                
                Image(systemName: "arrow.right")
                    .resizable()
                    .frame(width: 16, height: 16)
                
                Spacer()
                Text(store.state.destination.name)
                Spacer()
                
                Button {
                    store.send(.confirmTapped)
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }
            Divider()
            CurrencyField(value: $store.amount.sending(\.amountChanged), formatter: formatter)
            .font(Font.system(size: 60, design: .default))
            .keyboardType(.decimalPad)
            .focused($focused)

            Spacer()
        }
        .padding()
        .tint(.gray)
        .onAppear {
            focused = true
        }
    }
}
