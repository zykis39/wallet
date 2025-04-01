//
//  ProgressCircle.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import SwiftUI

struct ProgressCircle: View {
    struct Constants {
        static let lineWidth: CGFloat = 48
        static let imageSize: CGFloat = 40
    }
    struct Angles {
        let start: Double
        let middle: Double
        
        static let zero: Self = .init(start: 0, middle: 0)
    }
    
    let items: [CircleItemInfo]
    var angles: [CircleItemInfo: Angles] = [:]
    
    init(items: [CircleItemInfo]) {
        let sortedItems = items.sorted { $0.percent > $1.percent }
        self.items = sortedItems
        self.angles = calculateStartAngles(sortedItems)
    }
    
    private func calculateStartAngles(_ items: [CircleItemInfo]) -> [CircleItemInfo: Angles] {
        // -90 angle to start on top of the view
        var startAngle: Double = -90
        var angles: [CircleItemInfo: Angles] = [:]
        for item in items {
            let angle = Angles(start: startAngle,
                               middle: startAngle + item.percent * 360 / 2)
            startAngle += item.percent * 360
            angles[item] = angle
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
                            .rotationEffect(.degrees(angles[item, default: .zero].start))
                        let offset = CGPoint.pointOnCircle(radius: proxy.size.width / 2,
                                                           angle: angles[item, default: .zero].middle)
                        Circle()
                            .stroke(.white, lineWidth: 1)
                            .fill(.clear)
                            .background {
                                Image(systemName: item.icon)
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .padding(8)
                            }
                            .offset(x: offset.x, y: offset.y)
                            .frame(width: Constants.imageSize,
                                   height: Constants.imageSize)
                    }
                }
            }
        }
    }
}
