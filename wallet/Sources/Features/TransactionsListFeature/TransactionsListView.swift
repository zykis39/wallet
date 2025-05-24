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
//    var todayTransactions: [WalletTransaction] {
//        store.state.transactions
//            .filter { $0.timestamp.isEqual(to: .now, toGranularity: .day) }
//            .sorted(by: { $0.timestamp > $1.timestamp })
//    }
//    var yesterdayTransactions: [WalletTransaction] {
//        store.state.transactions
//            .filter { t in
//                Calendar.current.isDateInYesterday(t.timestamp) &&
//                !todayTransactions.contains(where: { today in today.id == t.id })
//            }
//            .sorted(by: { $0.timestamp > $1.timestamp })
//    }
//    var weekTransactions: [WalletTransaction] {
//        store.state.transactions.filter { $0.timestamp.isEqual(to: .now, toGranularity: .weekOfYear) }
//            .filter { t in
//                !todayTransactions.contains(where: { today in today.id == t.id }) &&
//                !yesterdayTransactions.contains(where: { today in today.id == t.id })
//            }
//            .sorted(by: { $0.timestamp > $1.timestamp })
//    }
//    var monthTransactions: [WalletTransaction] {
//        store.state.transactions.filter { $0.timestamp.isEqual(to: .now, toGranularity: .month) }
//            .filter { t in
//                !todayTransactions.contains(where: { today in today.id == t.id }) &&
//                !yesterdayTransactions.contains(where: { today in today.id == t.id }) &&
//                !weekTransactions.contains(where: { today in today.id == t.id })
//            }
//            .sorted(by: { $0.timestamp > $1.timestamp })
//    }
//    var allTransactions: [WalletTransaction] {
//        store.state.transactions.filter { $0.timestamp.isEqual(to: .now, toGranularity: .month) }
//            .filter { t in
//                !todayTransactions.contains(where: { today in today.id == t.id }) &&
//                !yesterdayTransactions.contains(where: { today in today.id == t.id }) &&
//                !weekTransactions.contains(where: { today in today.id == t.id }) &&
//                !monthTransactions.contains(where: { today in today.id == t.id })
//            }
//            .sorted(by: { $0.timestamp > $1.timestamp })
//    }
    
    var body: some View {
        VStack {
            List {
//                let items = [store.state.accounts + store.state.expenses].flatMap { $0 }
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
