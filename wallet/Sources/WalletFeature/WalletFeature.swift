//
//  WalletFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 09.03.2025.
//

import ComposableArchitecture

@Reducer
struct WalletFeature {
    
    @ObservableState
    struct State: Equatable {
        let accounts: [WalletItem]
        let expences: [WalletItem]
    }
    
    enum Action {
        case createTransaction(WalletTransaction)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
//            switch action {
//            case let .createTransaction(transaction):
//                break
//            }
            
            return .none
        }
    }
}
