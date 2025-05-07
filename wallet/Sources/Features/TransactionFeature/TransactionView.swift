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
    @State var sourceTextSelection: TextSelection?
    @State var destinationTextSelection: TextSelection?
    
    @State var restrictCurrencyChange: Bool = false
    let generator = UINotificationFeedbackGenerator()
    
    private var sourceCurrencySymbol: String {
        store.state.currencies.first(where: { $0.code == store.state.source.currencyCode })?.fixedSymbol ?? store.state.source.currencyCode
    }
    private var destinationCurrencySymbol: String {
        store.state.currencies.first(where: { $0.code == store.state.destination.currencyCode })?.fixedSymbol ?? store.state.destination.currencyCode
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            HeaderCancelConfirm(leftSystemImageName: "xmark.circle.fill",
                                rightSystemImageName: "checkmark.circle.fill",
                                leftAction: { [weak store] in store?.send(.cancelTapped) },
                                rightAction: { [weak store, generator] in
                store?.send(.confirmTapped)
                generator.notificationOccurred(.success)
            },
                                imageSize: 32,
                                middleSystemImageName: "arrow.right",
                                leftText: LocalizedStringKey(store.state.source.name),
                                rightText: LocalizedStringKey(store.state.destination.name))
            Divider()
            
            HStack {
                TextField("", text: $amountInSourceCurrency, selection: $sourceTextSelection, prompt: Text("0"))
                    .textSelection(.disabled)
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
                        
                        if restrictCurrencyChange {
                            guard let sourceAmount = Double(value),
                                  let destinationAmount = Double(amountInDestinationCurrency) else { return }
                            let newRate = destinationAmount / sourceAmount
                            store?.send(.sourceDestinationRateChanged(newRate))
                        } else {
                            guard let rate = store?.state.sourceDestinationRate else { return }
                            let destinationAmount: Double = (Double(value) ?? 0) * rate
                            let destinationString = CurrencyFormatter.formatterWithoutZeroSymbol.string(from: .init(value: destinationAmount))
                            amountInDestinationCurrency = destinationString ?? ""
                        }
                    }
                Text(sourceCurrencySymbol)
                    .font(Font.system(size: 60, design: .default))
                    .foregroundStyle(.secondary)
            }
            
            if store.state.source.currencyCode != store.state.destination.currencyCode {
                HStack {
                    TextField("", text: $amountInDestinationCurrency, selection: $destinationTextSelection, prompt: Text("0"))
                        .textSelection(.disabled)
                        .textFieldStyle(.roundedBorder)
                        .font(Font.system(size: 60, design: .default))
                        .keyboardType(.decimalPad)
                        .focused($focused, equals: .destinationTextField)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: amountInDestinationCurrency) { [weak store] oldValue, newValue in
                            guard focused == .destinationTextField else { return }
                            
                            let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                            self.amountInDestinationCurrency = value
                            
                            if restrictCurrencyChange {
                                guard let destinationAmount = Double(value),
                                      let sourceAmount = Double(amountInSourceCurrency) else { return }
                                let newRate = destinationAmount / sourceAmount
                                store?.send(.sourceDestinationRateChanged(newRate))
                            } else {
                                let sourceAmount: Double = (Double(value) ?? 0) / (store?.state.sourceDestinationRate ?? 1.0)
                                let sourceString = CurrencyFormatter.formatterWithoutZeroSymbol.string(from: .init(value: sourceAmount))
                                store?.send(.amountChanged(sourceAmount))
                                
                                amountInSourceCurrency = sourceString ?? ""
                            }
                        }
                    Text(destinationCurrencySymbol)
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
            destinationTextSelection = .init(insertionPoint: amountInDestinationCurrency.endIndex)
            sourceTextSelection = .init(insertionPoint: amountInSourceCurrency.endIndex)
            
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
