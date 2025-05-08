//
//  Arc.swift
//  wallet
//
//  Created by Артём Зайцев on 07.05.2025.
//

import SwiftUI

struct Arc: View {
    let angle: Double
    let color: Color
    
    var body: some View {
        ZStack {
            ArcShape(angle: angle, lineWidth: 2)
                .stroke(Color.black, lineWidth: 3.5)
            ArcShape(angle: angle, lineWidth: 2)
                .stroke(color, lineWidth: 2)
        }
    }
}

struct ArcShape : Shape {
    let angle: Double
    let lineWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let centerX = rect.width / 2 - lineWidth / 8
        let centerY = rect.height / 2 - lineWidth / 4

        p.addArc(center: CGPoint(x: centerX, y: centerY),
                 radius: rect.width / 2 - lineWidth / 4,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + angle),
                 clockwise: false)

        return p.strokedPath(.init(lineWidth: lineWidth))
    }
}
