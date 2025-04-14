//
//  PieChartsView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import SwiftUI
import Charts

struct PieChartsView: View {
    let data: [CircleItemInfo]
    
    var body: some View {
        Chart(data, id: \.id) { dataItem in
            SectorMark(angle: .value("Type", dataItem.percent * 100 * 360),
                       innerRadius: .ratio(0.7),
                       angularInset: 1.5)
            .foregroundStyle(dataItem.color)
            .cornerRadius(5)
            .opacity(dataItem.expenses == 0 ? 0.5: 1)
        }
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
        .mint,
        .teal,
        .yellow,
    ]
}
