//
//  TransactionsListView.swift
//  wallet
//
//  Created by Артём Зайцев on 07.05.2025.
//

import ComposableArchitecture
import SwiftUI

struct TransactionsListView: View {
    @Bindable var store: StoreOf<TransactionsListFeature>
    var hasTransactions: Bool {
        !store.state.transactions.allSatisfy { $0.value.isEmpty }
    }
    
    var body: some View {
        VStack {
            if hasTransactions {
                List {
                    let items = store.state.items
                    let currencies = store.state.currencies
                    TSection(name: "Today",
                             transactions: store.state.transactions[.today, default: []],
                             items: items,
                             currencies: currencies,
                             store: store)
                    TSection(name: "Yesterday",
                             transactions: store.state.transactions[.yesterday, default: []],
                             items: items,
                             currencies: currencies,
                             store: store)
                    TSection(name: "This week",
                             transactions: store.state.transactions[.thisWeek, default: []],
                             items: items,
                             currencies: currencies,
                             store: store)
                    TSection(name: "This month",
                             transactions: store.state.transactions[.thisMonth, default: []],
                             items: items,
                             currencies: currencies,
                             store: store)
                    TSection(name: "All",
                             transactions: store.state.transactions[.all, default: []],
                             items: items,
                             currencies: currencies,
                             store: store)
                }
                .listStyle(.plain)
                .tint(.black)
            } else {
                TransactionsZeroScreen()
                Spacer()
            }
        }
        .navigationTitle("Transactions")
    }
}

struct TSection: View {
    let name: LocalizedStringKey
    let transactions: [WalletTransaction]
    let items: [WalletItem]
    let currencies: [Currency]
    weak var store: StoreOf<TransactionsListFeature>?
    
    var body: some View {
        if !transactions.isEmpty {
            Section(name) {
                ForEach(transactions) { transaction in
                    TView(transaction: transaction, items: items, currencies: currencies)
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        if let transaction = transactions[safe: i] {
                            store?.send(.deleteTransaction(transaction.id))
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}

struct TView: View {
    let transaction: WalletTransaction
    let items: [WalletItem]
    let currencies: [Currency]
    
    var body: some View {
        
        let source: WalletItem = items.first(where: { $0.id == transaction.sourceID }) ?? .none
        let destination: WalletItem = items.first(where: { $0.id == transaction.destinationID }) ?? .none
        let isExpense = destination.type == .expenses
        
        TransactionCell(amount: transaction.representation(isIncome: false, currencies: currencies),
                        date: transaction.timestamp.formatted(date: .numeric, time: .omitted),
                        source: source.name,
                        destination: destination.name,
                        commentary: transaction.commentary,
                        amountTextColor: isExpense ? .red : .secondary)
    }
}
