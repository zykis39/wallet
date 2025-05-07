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
    @State var budget: String

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
        self.budget = CurrencyFormatter.representation(for: store.state.item.monthBudget ?? 0)
    }
    
    var body: some View {
        VStack {
            HeaderCancelConfirm(leftSystemImageName: "xmark.circle.fill",
                   rightSystemImageName: "checkmark.circle.fill",
                   leftAction: { store.send(.cancelTapped) },
                   rightAction: { store.send(.confirmedTapped) },
                   imageSize: 32)
            .padding()
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
                } else {
                    TextField("Budget",
                              text: $budget,
                              prompt: Text("MonthBudget"))
                    .keyboardType(.decimalPad)
                    .onChange(of: budget) { oldValue, newValue in
                        let value = CurrencyFormatter.formattedTextField(oldValue, newValue)
                        self.budget = value
                        self.store.send(.budgetChanged(Double(value) ?? 0))
                    }
                }
                if store.state.editType == .new {
                    Picker("Currency",
                           selection: $store.item.currencyCode.sending(\.currencyCodeChanged)) {
                        ForEach(store.state.currencies, id: \.code) { currency in
                            Text("\(currency.code) (\(currency.fixedSymbol))").tag(currency.code)
                        }
                    }
                }
            }
            .frame(maxHeight: store.item.type == .account ? 180 : 130)
            .scrollDisabled(true)
            .scrollContentBackground(.hidden)
            .tint(.black)
            
            if store.state.transactions.count > 0 {
                List {
                    Section {
                        ForEach(store.state.transactionsForCurrentPeriod) { transaction in
                            let isIncome = (transaction.destinationID == store.item.id) && (store.item.type == .account)
                            let currencies = store.state.currencies
                            let source: WalletItem = store.state.items.first(where: { $0.id == transaction.sourceID }) ?? .none
                            let destination: WalletItem = store.state.items.first(where: { $0.id == transaction.destinationID }) ?? .none
                            
                            TransactionCell(amount: transaction.representation(for: store.item, currencies: currencies),
                                            date: transaction.timestamp.formatted(date: .numeric, time: .omitted),
                                            source: source.name,
                                            destination: destination.name,
                                            commentary: transaction.commentary,
                                            amountTextColor: isIncome ? .green : .red)
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                if let transaction = store.state.transactionsForCurrentPeriod[safe: i] {
                                    store.send(.deleteTransaction(transaction))
                                }
                            }
                        }
                    } header: {
                        Picker("TransactionPeriod", selection: $store.transactionsPeriod.sending(\.periodChanged)) {
                            ForEach(TransactionPeriod.allCases, id: \.self) { period in
                                Text(period.representation)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .listStyle(.plain)
                .tint(.black)
            }
            
            if store.editType == .edit {
                Button {
                    store.send(.showAlertChanged(true))
                } label: {
                    Text("Delete")
                }
            }
            Spacer()
        }
        .submitLabel(.done)
        .tint(.white)
        .background(Color.walletItemColor(for: store.item.type))
        .ignoresSafeArea(.keyboard)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .alert("Delete %@?".localized(with: ["\"\(store.item.name.localized())\""]), isPresented: $store.showAlert.sending(\.showAlertChanged), actions: {
            Button {
                let deleteTransactions = false
                store.send(.deleteWalletItem(store.item.id, deleteTransactions))
                store.send(.showAlertChanged(false))
                store.send(.presentedChanged(false))
            } label: { Text("Delete only icon") }
            Button {
                let deleteTransactions = true
                store.send(.deleteWalletItem(store.item.id, deleteTransactions))
                store.send(.showAlertChanged(false))
                store.send(.presentedChanged(false))
            } label: { Text("Delete all transactions") }
            Button {
                store.send(.showAlertChanged(false))
            } label: { Text("Cancel") }
        }, message: {
            let name = "\"\(store.item.name.localized())\""
            Text("Deleting %@, you want:".localized(with: [name]))
        })
    }
}
