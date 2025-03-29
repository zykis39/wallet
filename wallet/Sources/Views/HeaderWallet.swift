//
//  HeaderWallet.swift
//  wallet
//
//  Created by Артём Зайцев on 29.03.2025.
//
import SwiftUI

struct HeaderWallet: View {
    let balance: Int
    let expenses: Int
    
    let leftSystemImageName: String
    let rightSystemImageName: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    let imageSize: CGFloat
    
    init(balance: Int, expenses: Int, leftSystemImageName: String, rightSystemImageName: String, leftAction: @escaping () -> Void, rightAction: @escaping () -> Void, imageSize: CGFloat) {
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
                Text("Баланс")
                    .opacity(0.54)
                Text("\(Currency.RUB.representation) \(balance)")
            }
            
            Spacer()
            
            VStack {
                Text("Расходы")
                    .opacity(0.54)
                Text("\(Currency.RUB.representation) \(expenses)")
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
