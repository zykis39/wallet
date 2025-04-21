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
                                     timestamp: item.timestamp,
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
    
    @Test
    func testItemUpdateUpdateItemInDatabase() async {
        // setup
        let testContext: () -> ModelContext = {
            ModelContext(SwiftDataContainerProvider.shared.container(inMemory: true))
        }
        let database = Database(context: testContext)
        
        let testState = WalletFeature.State(transaction: .initial,
                                            walletItemEdit: .initial,
                                            spendings: .initial,
                                            balance: 0,
                                            monthExpenses: 0,
                                            accounts: [.card],
                                            expenses: [.cafe],
                                            transactions: [])
        let store = TestStore(initialState: testState) {
            WalletFeature()
        } withDependencies: { dependencyValues in
            dependencyValues.database = database
        }
        
        let items = store.state.accounts + store.state.expenses
//        await store.send(.saveWalletItems(items))
        
        for item in items { try! database.insert(WalletItemModel(model: item)) }
        try! database.save()
        
        // expect database to have entities
        let itemDescriptor = FetchDescriptor<WalletItemModel>()
        let models = try! database.fetch(itemDescriptor)
        let hasChanges = try! database.context().hasChanges
        print("models: \(models.map { $0.valueType.name })")
    }
}
