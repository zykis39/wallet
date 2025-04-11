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
        let testState = WalletFeature.State(transaction: .initial, walletItemEdit: .initial, accounts: WalletItem.defaultAccounts, expenses: WalletItem.defaultExpenses, transactions: [])
        let store = TestStore(initialState: testState) {
            WalletFeature()
        }
        
        var item = store.state.accounts.first(where: { $0.name == "Cash" })!
        item.balance = 15
        
        await store.send(.walletItemEdit(.updateWalletItem(item))) {
            let itemIndex = $0.accounts.firstIndex(where: { $0.id == item.id })!
            $0.accounts[itemIndex].balance = 15
        }
        
        await store.receive(\.saveWalletItems)
    }
    
    @Test
    func testItemUpdateUpdateItemInDatabase() async {
        // setup
        let database = Database.testValue
        let testState = WalletFeature.State(transaction: .initial, walletItemEdit: .initial, accounts: WalletItem.defaultAccounts, expenses: WalletItem.defaultExpenses, transactions: [])
        let store = TestStore(initialState: testState) {
            WalletFeature()
        } withDependencies: { dependencyValues in
            dependencyValues.database = database
        }
        
        await store.send(.saveWalletItems)
        let itemDescriptor = FetchDescriptor<WalletItemModel>(predicate: #Predicate<WalletItemModel> { _ in true }, sortBy: [ .init(\.timestamp, order: .reverse) ])
        
        let models = try! database.context().fetch(itemDescriptor)
        let hasChanges = try! database.context().hasChanges
        print("models: \(models.map { $0.valueType.name })")
    }
}
