//
//  SpendingsStatisticsView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//

import ComposableArchitecture
import SwiftUI

struct SpendingsStatisticsView: View {
    @Bindable var store: StoreOf<SpendingsFeature>
    
    init(store: StoreOf<SpendingsFeature>) {
        self.store = store
    }
    
    var hasTransactions: Bool {
        guard store.state.spendings.count > 0,
              store.state.spendings.first?.expenses != 0 else { return false }
        return true
    }
    var total: Double {
        store.state.spendings.reduce(0) { $0 + $1.expenses }
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .center) {
                Picker("Period", selection: $store.period.sending(\.periodChanged)) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.representation)
                    }
                }
                .pickerStyle(.segmented)
                let s = abs(proxy.size.width - 48)
                ZStack {
                    PieChartsView(data: $store.chartSections.sending(\.chartSectionsChanged))
                    VStack {
                        Text("Total:")
                            .foregroundStyle(.secondary)
                        Text((CurrencyFormatter.formatter.string(from: .init(value: total)) ?? "") + " " + store.state.currency.fixedSymbol)
                            .font(.system(size: 24))
                    }
                }
                .frame(width: s, height: s)
                .padding(.vertical, 16)
                
                if hasTransactions {
                    Grid(alignment: .center) {
                        Divider()
                        ForEach(store.state.spendings, id: \.name) { item in
                            GridRow {
                                Text(LocalizedStringKey(item.name))
                                Text((CurrencyFormatter.formatter.string(from: .init(value: item.percent * 100)) ?? "") + "%")
                                Text((CurrencyFormatter.formatter.string(from: .init(value: item.expenses)) ?? "") + " " + item.currency.fixedSymbol)
                            }
                            .background {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.color)
                                    .padding(.horizontal, -10)
                                    .padding(.vertical, -2)
                            }
                            .foregroundStyle(.white)
                            
                            if item != store.state.spendings.last {
                                Divider()
                            }
                        }
                    }
                    .animation(.easeInOut, value: store.state.spendings)
                    
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
        }
    }
}
