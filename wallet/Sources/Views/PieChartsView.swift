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
    let animation: Animation
    let size: CGFloat
    let innerRadius: CGFloat = 0.6
    
    var body: some View {
        ZStack {
            Chart(data, id: \.name) { dataItem in
                SectorMark(angle: .value("Percent", dataItem.angle),
                           innerRadius: .ratio(innerRadius),
                           angularInset: 1.5)
                .foregroundStyle(dataItem.color)
                .cornerRadius(5)
                .annotation(position: .overlay, alignment: .center) {
                    let offset = CGPoint.pointOnCircle(radius: size / 2 * ((1 - innerRadius) / 2 + innerRadius), angle: dataItem.middleAngle)
                    let opacity = (dataItem.angle > 30) ? 1.0 : 0.0
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 1)
                            .frame(width: 50, height: 50)
                        Image(systemName: dataItem.icon)
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                    }
                    .opacity(opacity)
                    // offsetting icon 5% closer to center
                    .offset(x: -offset.x * 0.05,
                            y: -offset.y * 0.05)
                }
            }
            .animation(animation, value: data)
        }
    }
}

//#Preview {
//    PieChartsView(data:
//        Binding.constant([
//            PieChartSection(name: "Cafe", angle: 200, middleAngle: 100-90, icon: "fork.knife", color: .blue),
//            PieChartSection(name: "Groceries", angle: 160, middleAngle: 280-90, icon: "carrot.fill", color: .green)
//        ]),
//                  animation: .easeInOut, size: 360)
//}
