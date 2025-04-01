//
//  Extensions.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Date {
    func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, equalTo: date, toGranularity: component)
    }
}

extension Color {
    static func walletItemColor(for type: WalletItem.WalletItemType) -> Color {
        switch type {
        case .account: .yellow
        case .expenses: .green
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension CGPoint {
    static func pointOnCircle(radius: CGFloat, angle: CGFloat) -> CGPoint {
        let radians = angle * Double.pi / 180
        let x = radius * cos(radians)
        let y = radius * sin(radians)
        
        return CGPoint(x: x, y: y)
    }
}
