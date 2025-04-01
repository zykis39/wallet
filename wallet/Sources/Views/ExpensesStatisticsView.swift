//
//  ExpensesStatisticsView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//

import ComposableArchitecture
import SwiftUI

struct ExpensesStatisticsView: View {
    enum Period: CaseIterable {
        case day, week, month
        var representation: String {
            switch self {
            case .day: "День"
            case .week: "Неделя"
            case .month: "Месяц"
            }
        }
    }
    @State var period: Period = .month
    let transactions: [WalletTransaction]
    var store: StoreOf<WalletFeature>
    var circleItems: [CircleItemInfo] = []
    
    init(store: StoreOf<WalletFeature>) {
        self.store = store
        let transactions = store.state.transactions
        self.transactions = transactions
        self.circleItems = calculateCircleItems(transactions, period: period)
    }
    
    private func calculateCircleItems(_ transactions: [WalletTransaction], period: Period) -> [CircleItemInfo] {
        let granularity: Calendar.Component = {
            switch period {
            case .day: .day
            case .week: .weekOfMonth
            case .month: .month
            }
        }()
        let expenses: [UUID: Double] = transactions
            .filter { $0.destination.type == .expenses }
            .filter { $0.timestamp.isEqual(to: .now, toGranularity: granularity) }
            .reduce(into: [:]) { (result: inout [UUID: Double], transaction: WalletTransaction) in
                result[transaction.destination.id, default: 0] += transaction.amount
            }
        let overallExpenses: Double = expenses.values.reduce(0) { $0 + $1 }
        
        let items = expenses.sorted { $0.value > $1.value }.enumerated().compactMap { (index, item) -> CircleItemInfo? in
            guard let walletItem = store.state.expenses.first(where: { $0.id == item.key }) else { return nil }
            return CircleItemInfo(name: walletItem.name,
                                  icon: walletItem.icon,
                                  expenses: item.value,
                                  percent: item.value / overallExpenses,
                                  currency: walletItem.currency,
                                  color: CircleItemInfo.preferredColors[safe: index] ?? .yellow)
        }
        
        return items
    }
    
    var body: some View {
        VStack {
            ProgressCircle(items: circleItems)
                .padding(.horizontal, 56)
                .padding(.vertical, ProgressCircle.Constants.lineWidth + 12)
                .aspectRatio(1.0, contentMode: .fit)
            Picker("Период", selection: $period) {
                ForEach(Period.allCases, id: \.self) { period in
                    Text(period.representation)
                }
            }
            .pickerStyle(.segmented)
            List {
                Grid {
                    GridRow {
                        Text("Категория")
                        Text("%")
                        Text("Всего")
                    }
                    Divider()
                    ForEach(circleItems) { item in
                        GridRow {
                            Text(item.name)
                            Text((CurrencyFormatter.formatter.string(from: .init(value: item.percent * 100)) ?? "") + "%")
                            Text((CurrencyFormatter.formatter.string(from: .init(value: item.expenses)) ?? "") + " " + item.currency.representation)
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
        }.padding()
    }
}

struct CircleItemInfo: Hashable, Identifiable {
    var id = UUID()
    let name: String
    let icon: String
    let expenses: Double
    let percent: Double
    let currency: Currency
    let color: Color
    
    static var preferredColors: [Color] = [
        .cyan,
        .orange,
        .brown,
        .pink,
        .mint
    ]
}

struct ProgressCircle: View {
    struct Constants {
        static let lineWidth: CGFloat = 48
        static let imageSize: CGFloat = 40
    }
    
    let items: [CircleItemInfo]
    var startAngles: [CircleItemInfo: Double] = [:]
    var middleAngles: [Double] = []
    var imagesPoints: [CGPoint] = []
    init(items: [CircleItemInfo]) {
        self.items = items.sorted { $0.percent > $1.percent }
        self.startAngles = calculateStartAngles(self.items)
    }
    
    private mutating func calculateStartAngles(_ items: [CircleItemInfo]) -> [CircleItemInfo: Double] {
        var startAngle: Double = 0
        var angles: [CircleItemInfo: Double] = [:]
        for item in items {
            angles[item] = startAngle
            self.middleAngles.append(startAngle + item.percent * 360 / 2)
            startAngle += item.percent * 360
        }
        
        return angles
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .stroke(.red.opacity(0.2), lineWidth: Constants.lineWidth)
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ZStack {
                        Circle()
                            .trim(from: 0, to: item.percent)
                            .stroke(item.color, style: StrokeStyle(lineWidth: Constants.lineWidth,
                                                                   lineCap: .butt))
                            .rotationEffect(.degrees(startAngles[item, default: 0] - 90))
                        let r = proxy.size.width / 2 - Constants.lineWidth / 2 + Constants.imageSize / 2
                        let p = CGPoint.pointOnCircle(radius: r,
                                                      angle: middleAngles[index] - 90)
                        Circle()
                            .stroke(.white, lineWidth: 1)
                            .fill(.clear)
                            .background {
                                Image(systemName: item.icon)
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .padding(8)
                            }
                            .offset(x: p.x, y: p.y)
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                    }
                }
            }
        }
    }
}
