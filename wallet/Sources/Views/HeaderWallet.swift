//
//  HeaderWallet.swift
//  wallet
//
//  Created by Артём Зайцев on 29.03.2025.
//
import SwiftUI

struct HeaderWallet: View {
    let balance: Double
    let expenses: Double
    
    let leftSystemImageName: String
    let rightSystemImageName: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    let imageSize: CGFloat
    
    init(balance: Double, expenses: Double, leftSystemImageName: String, rightSystemImageName: String, leftAction: @escaping () -> Void, rightAction: @escaping () -> Void, imageSize: CGFloat) {
        self.balance = balance
        self.expenses = expenses
        self.leftSystemImageName = leftSystemImageName
        self.rightSystemImageName = rightSystemImageName
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.imageSize = imageSize
    }
    
    var body: some View {
        HStack {
            Button {
                leftAction()
            } label: {
                Image(systemName: leftSystemImageName)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
            Divider()
            
            Spacer()
            
            VStack {
                Text("Balance")
                    .opacity(0.54)
                Text((CurrencyFormatter.formatter.string(for: balance) ?? "0") + " " + (Currency.RUB.representation))
            }
            
            Spacer()
            
            VStack {
                Text("Expenses")
                    .opacity(0.54)
                Text((CurrencyFormatter.formatter.string(for: expenses) ?? "0") + " " + (Currency.RUB.representation))
            }
            
            Spacer()
            
            Divider()
            Button {
                rightAction()
            } label: {
                Image(systemName: rightSystemImageName)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
        }
        .tint(.gray)
        .padding()
    }
}
