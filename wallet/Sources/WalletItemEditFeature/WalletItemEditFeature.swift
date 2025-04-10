//
//  WalletItemEditFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import ComposableArchitecture
import SwiftUI

@Reducer
public struct WalletItemEditFeature {
    @ObservableState
    public struct State: Equatable {
        var editType: EditType
        var presented: Bool
        var item: WalletItem
        var currencies: [Currency]
        var rates: [ConversionRate]
        var transactions: [WalletTransaction]
        var iconSelectionPresented: Bool = false
        
        static let initial: Self = .init(editType: .new, presented: false, item: .none, currencies: [], rates: [], transactions: [])
    }
    
    public enum Action: Sendable {
        case presentItem(WalletItem, [WalletTransaction], [Currency], [ConversionRate])
        case presentNewItem(WalletItem.WalletItemType, Currency, [Currency])
        
        case confirmedTapped
        case cancelTapped
        case presentedChanged(Bool)
        case nameChanged(String)
        case balanceChanged(Double)
        case currencyChanged(Currency)
        case createWalletItem(WalletItem)
        case updateWalletItem(WalletItem)
        case deleteWalletItem(UUID)
        case iconSelectionPresentedChanged(Bool)
        case iconSelected(String)
        case deleteTransaction(WalletTransaction)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentItem(item, transactions, currencies, conversionRates):
                state.editType = .edit
                state.item = item
                state.transactions = transactions
                state.currencies = currencies
                state.rates = conversionRates
                
                return .run { send in
                    await send(.presentedChanged(true))
                }
            case let .presentNewItem(type, currency, currencies):
                let randomIcon: String = {
                    switch type {
                    case .account:
                        WalletItem.accountsSystemIconNames.randomElement() ?? ""
                    case .expenses:
                        WalletItem.expensesSystemIconNames.randomElement() ?? ""
                    }
                }()
                
                let newItem = WalletItem(id: UUID(),
                                         timestamp: .now,
                                         type: type,
                                         name: "",
                                         icon: randomIcon,
                                         currency: currency,
                                         balance: 0)
                state.editType = .new
                state.item = newItem
                state.transactions = []
                state.currencies = currencies
                state.rates = []
                
                return .run { send in
                    await send(.presentedChanged(true))
                }
            case .confirmedTapped:
                return .run { [editType = state.editType, item = state.item] send in
                    switch editType {
                    case .edit: await send(.updateWalletItem(item))
                    case .new: await send(.createWalletItem(item))
                    }
                    await send(.presentedChanged(false))
                }
            case .cancelTapped:
                return .run { send in
                    await send(.presentedChanged(false))
                }
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            case let .nameChanged(name):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            timestamp: item.timestamp,
                                            type: item.type,
                                            name: name,
                                            icon: item.icon,
                                            currency: item.currency,
                                            balance: item.balance)
                state.item = editedItem
                return .none
            case let .balanceChanged(balance):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            timestamp: item.timestamp,
                                            type: item.type,
                                            name: item.name,
                                            icon: item.icon,
                                            currency: item.currency,
                                            balance: balance)
                state.item = editedItem
                return .none
            case let .currencyChanged(currency):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            timestamp: item.timestamp,
                                            type: item.type,
                                            name: item.name,
                                            icon: item.icon,
                                            currency: currency,
                                            balance: item.balance)
                state.item = editedItem
                return .none
            case let .iconSelectionPresentedChanged(presented):
                state.iconSelectionPresented = presented
                return .none
            case let .iconSelected(icon):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            timestamp: item.timestamp,
                                            type: item.type,
                                            name: item.name,
                                            icon: icon,
                                            currency: item.currency,
                                            balance: item.balance)
                state.item = editedItem
                return .run { send in
                    await send(.iconSelectionPresentedChanged(false))
                }
            case .deleteWalletItem:
                return .none
            case .createWalletItem:
                return .none
            case .updateWalletItem:
                return .none
            case let .deleteTransaction(transaction):
                state.transactions = state.transactions.filter { $0.id != transaction.id }
                return .none
            }
        }
    }
}
