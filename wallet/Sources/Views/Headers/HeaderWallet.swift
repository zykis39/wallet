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
    let budget: Double
    let currency: Currency
    
    let leftSystemImageName: String
    let rightSystemImageName: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    let imageSize: CGFloat
    
    init(balance: Double, expenses: Double, budget: Double, currency: Currency, leftSystemImageName: String, rightSystemImageName: String, leftAction: @escaping () -> Void, rightAction: @escaping () -> Void, imageSize: CGFloat) {
        self.balance = balance
        self.expenses = expenses
        self.budget = budget
        self.currency = currency
        self.leftSystemImageName = leftSystemImageName
        self.rightSystemImageName = rightSystemImageName
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.imageSize = imageSize
    }
    
    var body: some View {
        let showBudget: Bool = budget > 0
        
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
                Text((CurrencyFormatter.formatter.string(for: balance) ?? "0") + " " + (currency.fixedSymbol))
                    .font(showBudget ? .footnote : .body)
            }
            
            Spacer()
            
            VStack {
                Text("Expenses")
                    .opacity(0.54)
                Text((CurrencyFormatter.formatter.string(for: expenses) ?? "0") + " " + (currency.fixedSymbol))
                    .font(showBudget ? .footnote : .body)
            }
            
            Spacer()
            
            if showBudget {
                VStack {
                    Text("Planned")
                        .opacity(0.54)
                    Text((CurrencyFormatter.formatter.string(for: budget) ?? "0") + " " + (currency.fixedSymbol))
                        .font(showBudget ? .footnote : .body)
                }
                
                Spacer()
            }
            
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
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}
