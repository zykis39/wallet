//
//  ExpensesStatisticsView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//

import ComposableArchitecture
import SwiftUI

struct ExpensesStatisticsView: View {
    let store: StoreOf<WalletFeature>
    @State var circleItems: [CircleItemInfo] = []
    @State var period: Period = .month
    var hasTransactions: Bool {
        circleItems.count > 0 ? true : false
    }
    var total: Double {
        circleItems.reduce(0) { $0 + $1.expenses }
    }
    
    init(store: StoreOf<WalletFeature>) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            ZStack {
                ProgressCircle(items: circleItems)
                    .padding(.horizontal, 64)
                    .padding(.vertical, ProgressCircle.Constants.lineWidth + 12)
                    .aspectRatio(1.0, contentMode: .fit)
                VStack {
                    Text("Total:")
                        .foregroundStyle(.secondary)
                    Text((CurrencyFormatter.formatter.string(from: .init(value: total)) ?? "") + " " + store.state.selectedCurrency.fixedSymbol)
                        .font(.system(size: 24))
                }
            }
            Picker("Period", selection: $period) {
                ForEach(Period.allCases, id: \.self) { period in
                    Text(period.representation)
                }
            }
            .pickerStyle(.segmented)
            if hasTransactions {
                List {
                    Grid {
                        GridRow {
                            Text("Category")
                            Text("%")
                            Text("Total")
                        }
                        Divider()
                        ForEach(circleItems) { item in
                            GridRow {
                                Text(LocalizedStringKey(item.name))
                                Text((CurrencyFormatter.formatter.string(from: .init(value: item.percent * 100)) ?? "") + "%")
                                Text((CurrencyFormatter.formatter.string(from: .init(value: item.expenses)) ?? "") + " " + item.currency.fixedSymbol)
                            }
                            .background(item.color)
                            .foregroundStyle(.white)
                            
                            if item != circleItems.last {
                                Divider()
                            }
                        }
                    }
                }
                Spacer()
            } else {
                Spacer()
                Text("Statistics.Zeroscreen.description")
                    .font(.system(size: 32))
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .padding()
        .navigationTitle("Expenses")
        .onChange(of: period, initial: true) { _, newValue in
            self.circleItems = calculateCircleItems(store.state.transactions, expenses: store.state.expenses, period: newValue, rates: store.state.rates, currency: store.state.selectedCurrency)
        }
    }
    
    // TODO: converting all transaction currencies into selected currency
    private func calculateCircleItems(_ transactions: [WalletTransaction], expenses: [WalletItem], period: Period, rates: [ConversionRate], currency: Currency) -> [CircleItemInfo] {
        let granularity: Calendar.Component = {
            switch period {
            case .day: .day
            case .week: .weekOfMonth
            case .month: .month
            }
        }()
        let expensesIDs: [UUID: Double] = transactions
            .filter { $0.destination.type == .expenses }
            .filter { $0.timestamp.isEqual(to: .now, toGranularity: granularity) }
            .reduce(into: [:]) { (result: inout [UUID: Double], transaction: WalletTransaction) in
                if transaction.currency.code == currency.code {
                    result[transaction.destination.id, default: 0] += transaction.amount
                } else {
                    let rate = ConversionRate.rate(for: transaction.currency, destination: currency, rates: rates)
                    result[transaction.destination.id, default: 0] += transaction.amount * rate
                }
            }
        let overallExpenses: Double = expensesIDs.values.reduce(0) { $0 + $1 }
        
        let items = expensesIDs.sorted { $0.value > $1.value }.enumerated().compactMap { (index, item) -> CircleItemInfo? in
            guard let walletItem = expenses.first(where: { $0.id == item.key }) else { return nil }
            return CircleItemInfo(name: walletItem.name,
                                  icon: walletItem.icon,
                                  expenses: item.value,
                                  percent: item.value / overallExpenses,
                                  currency: currency,
                                  color: CircleItemInfo.preferredColors[safe: index] ?? .yellow)
        }
        
        return items
    }
}
