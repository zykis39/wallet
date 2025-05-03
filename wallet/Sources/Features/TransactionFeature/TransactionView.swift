//
//  TransactionView.swift
//  wallet
//
//  Created by Артём Зайцев on 23.03.2025.
//

import ComposableArchitecture
import SwiftUI

struct TransactionView: View {
    @Bindable var store: StoreOf<TransactionFeature>
    init(store: StoreOf<TransactionFeature>) {
        self.store = store
    }
    
    enum FocusField {
        case sourceTextField, destinationTextField
    }
    @FocusState var focused: FocusField?
    @State var amountInSourceCurrency: String = ""
    @State var amountInDestinationCurrency: String = ""
    @State var restrictCurrencyChange: Bool = false
    let generator = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(alignment: .trailing) {
            HeaderCancelConfirm(leftSystemImageName: "xmark.circle.fill",
                                rightSystemImageName: "checkmark.circle.fill",
                                leftAction: { [weak store] in store?.send(.cancelTapped) },
                                rightAction: {
                [weak store, generator] in
                if restrictCurrencyChange,
                   let sourceAmount = Double(amountInSourceCurrency),
                   let destinationAmount = Double(amountInDestinationCurrency) {
                    let rate = destinationAmount / sourceAmount
                    store?.send(.sourceDestinationRateChanged(rate))
                }
                store?.send(.confirmTapped)
                generator.notificationOccurred(.success)
            },
                                imageSize: 32,
                                middleSystemImageName: "arrow.right",
                                leftText: LocalizedStringKey(store.state.source.name),
                                rightText: LocalizedStringKey(store.state.destination.name))
            Divider()
            
            HStack {
                TextField("", text: $amountInSourceCurrency)
                    .textFieldStyle(.roundedBorder)
                    .font(Font.system(size: 60, design: .default))
                    .keyboardType(.decimalPad)
                    .focused($focused, equals: .sourceTextField)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: amountInSourceCurrency) { [weak store] oldValue, newValue in
                        guard focused == .sourceTextField else { return }
                        
                        let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                        self.amountInSourceCurrency = value
                        store?.send(.amountChanged(Double(value) ?? 0))
                        
                        if !restrictCurrencyChange, let store {
                            let destinationAmount: Double = (Double(value) ?? 0) * store.state.sourceDestinationRate
                            let destinationString = CurrencyFormatter.formatterWithoutZeroSymbol.string(from: .init(value: destinationAmount))
                            amountInDestinationCurrency = destinationString ?? ""
                        }
                    }
                Text(store.state.source.currency.fixedSymbol)
                    .font(Font.system(size: 60, design: .default))
                    .foregroundStyle(.secondary)
            }
            
            if store.state.source.currency.code != store.state.destination.currency.code {
                HStack {
                    TextField("", text: $amountInDestinationCurrency)
                        .textFieldStyle(.roundedBorder)
                        .font(Font.system(size: 60, design: .default))
                        .keyboardType(.decimalPad)
                        .focused($focused, equals: .destinationTextField)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: amountInDestinationCurrency) { [weak store] oldValue, newValue in
                            guard focused == .destinationTextField else { return }
                            
                            let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                            self.amountInDestinationCurrency = value
                            
                            if !restrictCurrencyChange {
                                let sourceAmount: Double = (Double(value) ?? 0) / (store?.state.sourceDestinationRate ?? 1.0)
                                let sourceString = CurrencyFormatter.formatterWithoutZeroSymbol.string(from: .init(value: sourceAmount))
                                amountInSourceCurrency = sourceString ?? ""
                                store?.send(.amountChanged(sourceAmount))
                            }
                        }
                    Text(store.state.destination.currency.fixedSymbol)
                        .font(Font.system(size: 60, design: .default))
                        .foregroundStyle(.secondary)
                }
            }
            
            // commentary
            HStack {
                TextField("Commentary", text: $store.commentary.sending(\.commentaryChanged))
                    .textFieldStyle(.roundedBorder)
            }
            
            Spacer()
        }
        .padding()
        .tint(.gray)
        .onAppear {
            focused = .sourceTextField
        }
        /// letting user to choose his own conversion rate
        .onChange(of: focused) { oldValue, newValue in
            guard amountInSourceCurrency.isEmpty && amountInDestinationCurrency.isEmpty else {
                if newValue == .destinationTextField {
                    restrictCurrencyChange = true
                }
                return
            }
        }
    }
}

//#Preview {
//    TransactionView(store:
//            .init(initialState:
//                    TransactionFeature.State(presented: true,
//                                             amount: 240.03,
//                                             source: .card,
//                                             destination: .groceries,
//                                             sourceDestinationRate: 1.0,
//                                             commentary: ""),
//                  reducer: {
//        TransactionFeature()
//    }))
//}
