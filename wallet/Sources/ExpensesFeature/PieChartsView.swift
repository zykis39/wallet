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
            Chart(data, id: \.name) { dataItem in
                SectorMark(angle: .value("Percent", dataItem.angle),
                           innerRadius: .ratio(0.6),
                           angularInset: 1.5)
                .foregroundStyle(dataItem.color)
                .cornerRadius(5)
                .opacity(dataItem.opacity)
                .annotation(position: .overlay, alignment: .center) {
                    if dataItem.angle > 30 {
                        Image(systemName: dataItem.icon)
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .animation(.easeInOut, value: data)
        }
    }
}
