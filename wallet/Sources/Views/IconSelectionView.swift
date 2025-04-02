//
//  IconSelectionView.swift
//  wallet
//
//  Created by Артём Зайцев on 02.04.2025.
//
import ComposableArchitecture
import SwiftUI

struct IconSelectionView: View {
    let accountsSystemIconNames: [String] = [
        "creditcard", 
        "wallet.bifold",
        "banknote",
        "rublesign.bank.building.fill",
        "eurosign.bank.building.fill",
        "dollarsign.bank.building.fill",
        "dollarsign",
    ]
    let expensesSystemIconNames: [String] = [
        // home
        "house",
        "house.fill",
        
        // food
        "carrot",
        "fork.knife",
        
        // transport
        "car",
        "bus.fill",
        "airplane",
        
        // healthcare
        "figure.run",
        "cross",
        
        // services
        "network",
        "cellularbars",
        
        // shopping
        "handbag",
        
        // entertainment
        "party.popper",
        "popcorn",
        "movieclapper",
        "birthday.cake",
    ]
    
    var store: StoreOf<WalletItemEditFeature>
    init(store: StoreOf<WalletItemEditFeature>) {
        self.store = store
    }
    
    var icons: [String] {
        switch store.item.type {
        case .account:
            accountsSystemIconNames
        case .expenses:
            expensesSystemIconNames
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64, maximum: 80))]) {
                ForEach(icons, id: \.self) { icon in
                    ZStack {
                        Circle()
                            .fill(Color.walletItemColor(for: store.item.type))
                        Image(systemName: icon)
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                            .foregroundStyle(.white)
                            .padding(16)
                    }.onTapGesture {
                        store.send(.iconSelected(icon))
                    }
                }
            }
        }
        .padding(12)
        .navigationTitle("Выбор иконки")
    }
}
