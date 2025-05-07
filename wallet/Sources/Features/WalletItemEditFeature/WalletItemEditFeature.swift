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
        var items: [WalletItem] // need for transactions source/destination names
        var currencies: [Currency]
        var rates: [ConversionRate]
        var transactions: [WalletTransaction]
        var transactionsForCurrentPeriod: [WalletTransaction]
        var transactionsPeriod: TransactionPeriod
        var iconSelectionPresented: Bool = false
        var showAlert: Bool = false
        
        static let initial: Self = .init(editType: .new, presented: false, item: .none, items: [], currencies: [], rates: [], transactions: [], transactionsForCurrentPeriod: [], transactionsPeriod: .today)
    }
    
    public enum Action: Sendable {
        case presentItem(WalletItem, [WalletItem], [WalletTransaction], [Currency], [ConversionRate])
        case presentNewItem(WalletItem.WalletItemType, Currency, [Currency])
        
        case confirmedTapped
        case cancelTapped
        case presentedChanged(Bool)
        case nameChanged(String)
        case balanceChanged(Double)
        case budgetChanged(Double)
        case currencyCodeChanged(String)
        case createWalletItem(WalletItem)
        case updateWalletItem(WalletItem)
        case deleteWalletItem(UUID, Bool)
        case iconSelectionPresentedChanged(Bool)
        case iconSelected(String)
        case deleteTransaction(WalletTransaction)
        case periodChanged(TransactionPeriod)
        case showAlertChanged(Bool)
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentItem(item, items, transactions, currencies, conversionRates):
                state.editType = .edit
                state.item = item
                state.items = items
                state.transactions = transactions
                state.currencies = currencies
                state.rates = conversionRates
                
                return .run { send in
                    await send(.periodChanged(.today))
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
                                         order: 0,
                                         type: type,
                                         name: "",
                                         icon: randomIcon,
                                         currencyCode: currency.code,
                                         balance: 0,
                                         monthBudget: nil)
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
                                            order: item.order,
                                            type: item.type,
                                            name: name,
                                            icon: item.icon,
                                            currencyCode: item.currencyCode,
                                            balance: item.balance,
                                            monthBudget: item.monthBudget)
                state.item = editedItem
                return .none
            case let .balanceChanged(balance):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            order: item.order,
                                            type: item.type,
                                            name: item.name,
                                            icon: item.icon,
                                            currencyCode: item.currencyCode,
                                            balance: balance,
                                            monthBudget: item.monthBudget)
                state.item = editedItem
                return .none
            case let .budgetChanged(budget):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            order: item.order,
                                            type: item.type,
                                            name: item.name,
                                            icon: item.icon,
                                            currencyCode: item.currencyCode,
                                            balance: item.balance,
                                            monthBudget: budget)
                state.item = editedItem
                return .none
            case let .currencyCodeChanged(code):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            order: item.order,
                                            type: item.type,
                                            name: item.name,
                                            icon: item.icon,
                                            currencyCode: code,
                                            balance: item.balance,
                                            monthBudget: item.monthBudget)
                state.item = editedItem
                return .none
            case let .iconSelectionPresentedChanged(presented):
                state.iconSelectionPresented = presented
                return .none
            case let .iconSelected(icon):
                let item = state.item
                let editedItem = WalletItem(id: item.id,
                                            order: item.order,
                                            type: item.type,
                                            name: item.name,
                                            icon: icon,
                                            currencyCode: item.currencyCode,
                                            balance: item.balance,
                                            monthBudget: item.monthBudget)
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
                state.transactionsForCurrentPeriod = state.transactionsForCurrentPeriod.filter { $0.id != transaction.id }
                return .none
            case let .periodChanged(period):
                state.transactionsPeriod = period
                state.transactionsForCurrentPeriod = state.transactions.filter { t in
                    switch period {
                    case .today:
                        return Calendar.current.isDateInToday(t.timestamp)
                    case .yesterday:
                        return Calendar.current.isDateInYesterday(t.timestamp)
                    case .all:
                        return true
                    }
                }.sorted(by: { $0.timestamp > $1.timestamp })
                return .none
            case let .showAlertChanged(show):
                state.showAlert = show
                return .none
            }
        }
    }
}
