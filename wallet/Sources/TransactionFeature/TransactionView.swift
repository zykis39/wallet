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
            Header(leftSystemImageName: "xmark.circle.fill",
                   rightSystemImageName: "checkmark.circle.fill",
                   leftAction: { [store] in store.send(.cancelTapped) },
                   rightAction: { [store] in store.send(.confirmTapped) },
                   imageSize: 32,
                   middleSystemImageName: "arrow.right",
                   leftText: store.state.source.name,
                   rightText: store.state.destination.name)
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
