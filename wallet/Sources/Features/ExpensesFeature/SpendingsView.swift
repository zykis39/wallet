//
//  SpendingsView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//

import ComposableArchitecture
import SwiftUI

struct SpendingsView: View {
    @Bindable var store: StoreOf<SpendingsFeature>
    let animation = Animation.easeInOut(duration: 0.3)
    
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
                let s = abs(proxy.size.width - 96)
                ZStack {
                    PieChartsView(data: $store.chartSections.sending(\.chartSectionsChanged), animation: animation, size: s)
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
                    ScrollView(.vertical) {
                        Grid(alignment: .center) {
                            ForEach(store.state.spendings, id: \.name) { item in
                                Divider()
                                GridRow {
                                    SmallColorView(color: item.color)
                                    Text(LocalizedStringKey(item.name))
                                        .gridColumnAlignment(.leading)
                                    Text((CurrencyFormatter.formatter.string(from: .init(value: item.percent * 100)) ?? "") + "%")
                                        .gridColumnAlignment(.trailing)
                                    Text((CurrencyFormatter.formatter.string(from: .init(value: item.expenses)) ?? "") + " " + item.currency.fixedSymbol)
                                        .gridColumnAlignment(.trailing)
                                }
                                .foregroundStyle(.secondary)
                                Divider()
                            }
                        }
                        .animation(animation, value: store.state.spendings)
                        .padding(.horizontal, 24)
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
            .navigationTitle("Expenses")
        }
    }
}

struct SmallColorView: View {
    let color: Color
    
    var body: some View {
        color
            .frame(width: 20, height: 20)
//            .clipShape(.rect)
            .cornerRadius(8)
    }
}
