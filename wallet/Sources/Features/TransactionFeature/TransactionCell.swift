//
//  TransactionCell.swift
//  wallet
//
//  Created by Артём Зайцев on 10.04.2025.
//
import SwiftUI

struct TransactionCell: View {
    let amount: String
    let date: String
    let source: String
    let destination: String
    let commentary: String
    let amountTextColor: Color
    init(amount: String, date: String, source: String, destination: String, commentary: String, amountTextColor: Color) {
        self.amount = amount
        self.date = date
        self.source = source
        self.destination = destination
        self.commentary = commentary
        self.amountTextColor = amountTextColor
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(source))
                    .font(.system(size: 14))
                Text(LocalizedStringKey(destination))
                    .font(.system(size: 12))
                Spacer()
                    .frame(maxHeight: 8)
                Text(date)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
            }
            .padding(.trailing, 8)
            Text(commentary)
                .multilineTextAlignment(.leading)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(amount)
                .foregroundStyle(amountTextColor)
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 4)
        .frame(minHeight: 44)
    }
}
