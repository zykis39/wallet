//
//  WalletFeatureTests.swift
//  wallet
//
//  Created by Артём Зайцев on 10.04.2025.
//

import Foundation
import ComposableArchitecture
import Testing
import SwiftData

@testable import wallet

@MainActor
struct WalletFeatureTests {
    
    @Test
    func testUpdateWalletItemBalance() async {
        // setup
        let testState = WalletFeature.State(transaction: .initial,
                                            walletItemEdit: .initial,
                                            spendings: .initial,
                                            appScore: .initial,
                                            balance: 0,
                                            monthExpenses: 0,
                                            accounts: [.card, .cash],
                                            expenses: [.cafe],
                                            transactions: [])
        let store = TestStore(initialState: testState) {
            WalletFeature()
        }
        
        let item = store.state.accounts.first(where: { $0.name == "Cash" })!
        let updatedItem = WalletItem(id: item.id,
                                     order: item.order,
                                     type: item.type,
                                     name: item.name,
                                     icon: item.icon,
                                     currency: item.currency,
                                     balance: 15)
        
        await store.send(.walletItemEdit(.updateWalletItem(updatedItem))) {
            let itemIndex = $0.accounts.firstIndex(where: { $0.id == item.id })!
            $0.accounts[itemIndex] = updatedItem
        }
        
        await store.receive(\.saveWalletItems)
    }
}
