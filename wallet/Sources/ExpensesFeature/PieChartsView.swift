//
//  PieChartsView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import SwiftUI
import Charts

struct PieChartsView: View {
    @Binding var data: [PieChartSection]
    
    var body: some View {
        ZStack {
            Chart(data, id: \.self) { dataItem in
                SectorMark(angle: .value("Type", dataItem.angle),
                           innerRadius: .ratio(0.7),
                           angularInset: 1.5)
                .foregroundStyle(dataItem.color)
                .cornerRadius(5)
                .opacity(dataItem.opacity)
            }
        }
    }
}
