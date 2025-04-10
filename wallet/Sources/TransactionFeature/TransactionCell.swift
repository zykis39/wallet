//
//  TransactionCell.swift
//  wallet
//
//  Created by Артём Зайцев on 10.04.2025.
//
import SwiftUI

struct TransactionCell: View {
    let leftText: String
    let rightText: String
    let rightTextColor: Color
    init(leftText: String, rightText: String, rightTextColor: Color) {
        self.leftText = leftText
        self.rightText = rightText
        self.rightTextColor = rightTextColor
    }
    
    var body: some View {
        HStack {
            Text(leftText)
            .foregroundStyle(.black)
            .layoutPriority(1)
            Spacer()
            Text(rightText)
                .foregroundStyle(rightTextColor)
        }
        .frame(minHeight: 44)
    }
}
