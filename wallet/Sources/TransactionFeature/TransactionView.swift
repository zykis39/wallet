//
//  TransactionView.swift
//  wallet
//
//  Created by Артём Зайцев on 23.03.2025.
//

import ComposableArchitecture
import SwiftUI
//import CurrencyField

struct TransactionView: View {
    @Bindable var store: StoreOf<TransactionFeature>
    init(store: StoreOf<TransactionFeature>) {
        self.store = store
    }
    
    @FocusState var focused: Bool
    @State var amount: String = ""
    
    var body: some View {
        VStack(alignment: .trailing) {
            HeaderCancelConfirm(leftSystemImageName: "xmark.circle.fill",
                   rightSystemImageName: "checkmark.circle.fill",
                   leftAction: { [store] in store.send(.cancelTapped) },
                   rightAction: { [store] in store.send(.confirmTapped) },
                   imageSize: 32,
                   middleSystemImageName: "arrow.right",
                   leftText: store.state.source.name,
                   rightText: store.state.destination.name)
            Divider()
            
            TextField("Сумма", text: $amount)
            .textFieldStyle(.roundedBorder)
            .font(Font.system(size: 60, design: .default))
            .keyboardType(.decimalPad)
            .focused($focused)
            .multilineTextAlignment(.trailing)
            .onChange(of: amount) { oldValue, newValue in
                let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                self.amount = value
                store.send(.amountChanged(Double(value) ?? 0))
            }
            Spacer()
        }
        .padding()
        .tint(.gray)
        .onAppear {
            focused = true
        }
    }
}
