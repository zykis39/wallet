//
//  WalletItemEditView.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import ComposableArchitecture
import SwiftUI

struct WalletItemEditView: View {
    @Bindable var store: StoreOf<WalletItemEditFeature>
    @State var balance: String
    
    var headerText: String {
        switch store.editType {
        case .new:
            store.item.type == .account ? "Новый кошелек, карта или счет" : "На что вы тратите деньги?"
        case .edit:
            "Измените параметры \(store.item.type == .account ? "счета" : "расхода")"
        }
    }
    
    init(store: StoreOf<WalletItemEditFeature>) {
        self.store = store
        self.balance = CurrencyFormatter.representation(for: store.state.item.balance)
    }
    
    var body: some View {
        VStack {
            HeaderCancelConfirm(leftSystemImageName: "xmark.circle.fill",
                   rightSystemImageName: "checkmark.circle.fill",
                   leftAction: { store.send(.cancelTapped) },
                   rightAction: { store.send(.confirmedTapped) },
                   imageSize: 32)
            Spacer()
                .frame(height: 24)
            Text(headerText)
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 0.5)
                    .foregroundStyle(Color.walletItemColor(for: store.item.type))
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(width: 64, height: 64)
            Form {
                TextField(text: $store.item.name.sending(\.nameChanged)) {
                    Text("Введите название")
                }
                
                if store.item.type == .account {
                    TextField("Баланс",
                              text: $balance,
                              prompt: Text("Остаток на счёте"))
                    .keyboardType(.decimalPad)
                    .onChange(of: balance) { oldValue, newValue in
                        let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                        self.balance = value
                        self.store.send(.balanceChanged(Double(value) ?? 0))
                    }
                }
                Picker("Валюта: ",
                       selection: $store.item.currency.sending(\.currencyChanged)) {
                    ForEach(Currency.allCases, id: \.id) { currency in
                        Text("\(currency.representation) (\(currency.rawValue))").tag(currency)
                    }
                }
            }
            .frame(maxHeight: store.item.type == .account ? 180 : 130)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .tint(.black)
            
            Form {
                Section("Транзакции") {
                    List {
                        ForEach(store.state.transactions) { transaction in
                            let isIncome = (transaction.destination.id == store.item.id) && (store.item.type == .account)
                            let amount = transaction.amount
                            let currency = transaction.currency.representation
                            let isItemSource = transaction.source.id == store.item.id
                            let to = isItemSource ? transaction.destination.name : transaction.source.name
                            
                            HStack {
                                Text(transaction.timestamp,
                                     format: .dateTime.day().month()
                                    .locale(Locale(identifier: "ru_RU")))
                                .foregroundStyle(.black)
                                Spacer()
                                Text((isIncome ? "+" : "-") + " \(amount) \(currency) (\(to))")
                                    .foregroundStyle(isIncome ? .green : .red)
                            }
                        }
                    }
                }
                .foregroundStyle(.white)
            }
            .submitLabel(.done)
            .scrollContentBackground(.hidden)
            .tint(.black)
            .opacity(store.state.transactions.count > 0 ? 1 : 0)
            
            if store.editType == .edit {
                Button {
                    store.send(.deleteWalletItem(store.item.id))
                } label: {
                    Text("Удалить")
                }
            }
            Spacer()
        }
        .padding()
        .tint(.white)
        .background(Color.walletItemColor(for: store.item.type))
        .ignoresSafeArea(.keyboard)
    }
}
