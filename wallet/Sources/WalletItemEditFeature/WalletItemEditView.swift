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

    var name: Binding<String> {
        Binding<String>(
            get: { store.item.name.localized() },
            set: { store.send(.nameChanged($0)) }
        )
    }
    
    
    var headerText: LocalizedStringKey {
        switch store.editType {
        case .new:
            switch store.item.type {
            case .account:
                return "WalletItem.Create.Account.Title"
            case .expenses:
                return "WalletItem.Create.Expense.Title"
            }
        case .edit:
            switch store.item.type {
            case .account:
                return "WalletItem.Edit.Account.Title"
            case .expenses:
                return "WalletItem.Edit.Expense.Title"
            }
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
                Image(systemName: store.item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(width: 64, height: 64)
            .onTapGesture {
                store.send(.iconSelectionPresentedChanged(true))
            }
            Form {
                TextField(text: name) {
                    Text("EnterName")
                }
                
                if store.item.type == .account {
                    TextField("Balance",
                              text: $balance,
                              prompt: Text("AccountBalance"))
                    .keyboardType(.decimalPad)
                    .onChange(of: balance) { oldValue, newValue in
                        let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                        self.balance = value
                        self.store.send(.balanceChanged(Double(value) ?? 0))
                    }
                }
                Picker("Currency",
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
                Section("Transactions") {
                    List {
                        ForEach(store.state.transactions) { transaction in
                            let isIncome = (transaction.destination.id == store.item.id) && (store.item.type == .account)
                            HStack {
                                Text(transaction.timestamp.formatted(date: .numeric, time: .omitted))
                                .foregroundStyle(.black)
                                .layoutPriority(1)
                                Spacer()
                                Text(transaction.representation(for: store.item))
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
                    Text("Delete")
                }
            }
            Spacer()
        }
        .padding()
        .tint(.white)
        .background(Color.walletItemColor(for: store.item.type))
        .ignoresSafeArea(.keyboard)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
