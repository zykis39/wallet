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
    
    enum FocusField {
        case sourceTextField, destinationTextField
    }
    @FocusState var focused: FocusField?
    @State var amountInSourceCurrency: String = ""
    @State var amountInDestinationCurrency: String = ""
    let generator = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(alignment: .trailing) {
            HeaderCancelConfirm(leftSystemImageName: "xmark.circle.fill",
                                rightSystemImageName: "checkmark.circle.fill",
                                leftAction: { [store] in store.send(.cancelTapped) },
                                rightAction: {
                [store, generator] in store.send(.confirmTapped)
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
                    .onChange(of: amountInSourceCurrency) { oldValue, newValue in
                        guard focused == .sourceTextField else { return }
                        
                        let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                        self.amountInSourceCurrency = value
                        store.send(.amountChanged(Double(value) ?? 0))
                        
                        let destinationAmount: Double = (Double(value) ?? 0) * store.state.sourceDestinationRate
                        let destinationString = CurrencyFormatter.formatter.string(from: .init(value: destinationAmount))
                        amountInDestinationCurrency = destinationString ?? ""
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
                        .onChange(of: amountInDestinationCurrency) { oldValue, newValue in
                            guard focused == .destinationTextField else { return }
                            
                            let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                            self.amountInDestinationCurrency = value
                            
                            let sourceAmount: Double = (Double(value) ?? 0) / store.state.sourceDestinationRate
                            let sourceString = CurrencyFormatter.formatter.string(from: .init(value: sourceAmount))
                            amountInSourceCurrency = sourceString ?? ""
                            store.send(.amountChanged(sourceAmount))
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
    }
}

#Preview {
    TransactionView(store:
            .init(initialState:
                    TransactionFeature.State(presented: true,
                                             amount: 240.03,
                                             source: .card,
                                             destination: .groceries,
                                             sourceDestinationRate: 1.0,
                                             commentary: ""),
                  reducer: {
        TransactionFeature()
    }))
}
