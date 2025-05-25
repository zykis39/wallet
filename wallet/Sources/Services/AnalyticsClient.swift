//
//  AnalyticsClient.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import FirebaseAnalytics
import AppsFlyerLib

public enum Event {
    case error(String)
    case appStarted(firstLaunch: Bool, currencyCode: String, locale: String)
    case itemTapped(name: String)
    case itemCreated(name: String, icon: String, currency: String)
    case itemDeleted(name: String, hasTransactions: Bool, deleteTransactions: Bool)
    case transactionCreated(source: String, destination: String, amount: Double, rate: Double)
    case transactionDeleted(source: String, destination: String, amount: Double, rate: Double)
    
    /// wallet item edit
    case itemNameChanged(oldName: String, newName: String)
    case itemCurrencyChanged(name: String, oldCurrency: String, newCurrency: String)
    case itemBudgetChanged(name: String, oldBudget: Double?, newBudget: Double?)
    case itemIconChanged(name: String, oldIcon: String, newIcon: String)
    case itemBalanceChanged(name: String, oldBalance: Double, newBalance: Double)
    
    /// transitions
    case transactionScreenTransition(source: String, destination: String, rate: Double)
    case iconSelectionScreenTransition(item: String)
    case aboutScreenTransition
    case scoreScreenTransition
    case statisticsScreenTransition
}

public protocol AnalyticsClient {
    func logEvent(_ event: Event)
}

final class FirebaseAnalyticsClient: AnalyticsClient {
    func logEvent(_ event: Event) {
        var eventName: String?
        var parameters: [String: Any]?
        
        switch event {
        case let .error(message):
            eventName = "error"
            parameters = [
                "message": message
            ]
        case let .appStarted(firstLaunch, currencyCode, locale):
            eventName = "app_started"
            parameters = [
                "firstLaunch": firstLaunch,
                "currencyCode": currencyCode,
                "locale": locale
            ]
        case let .itemTapped(itemName):
            eventName = "item_tapped"
            parameters = [
                "itemName": itemName
            ]
        case let .itemCreated(name, icon, currency):
            eventName = "item_created"
            parameters = [
                "name": name,
                "icon": icon,
                "currency": currency
            ]
        case let .itemDeleted(name, hasTransactions, deleteTransactions):
            eventName = "item_deleted"
            parameters = [
                "name": name,
                "hasTransactions": hasTransactions,
                "deleteTransactions": deleteTransactions
            ]
        case let .transactionCreated(source, destination, amount, rate):
            eventName = "transaction_created"
            parameters = [
                "source": source,
                "destination": destination,
                "amount": amount,
                "rate": rate
            ]
        case let .transactionDeleted(source, destination, amount, rate):
            eventName = "transaction_deleted"
            parameters = [
                "source": source,
                "destination": destination,
                "amount": amount,
                "rate": rate
            ]
        case let .itemNameChanged(oldName, newName):
            eventName = "item_name_changed"
            parameters = [
                "old_name": oldName,
                "new_name": newName
            ]
        case let .itemCurrencyChanged(name, oldCurrency, newCurrency):
            eventName = "item_currency_changed"
            parameters = [
                "name": name,
                "old_currency": oldCurrency,
                "new_currency": newCurrency
            ]
        case let .itemBudgetChanged(name, oldBudget, newBudget):
            eventName = "item_budget_changed"
            parameters = [
                "name": name,
                "old_budget": oldBudget ?? 0,
                "new_budget": newBudget ?? 0
            ]
        case let .itemIconChanged(name, oldIcon, newIcon):
            eventName = "item_icon_changed"
            parameters = [
                "name": name,
                "old_icon": oldIcon,
                "new_icon": newIcon
            ]
        case let .itemBalanceChanged(name, oldBalance, newBalance):
            eventName = "item_balance_changed"
            parameters = [
                "name": name,
                "old_balance": oldBalance,
                "new_balance": newBalance
            ]

        /// transitions
        case let .transactionScreenTransition(source, destination, rate):
            eventName = "transaction_screen_transition"
            parameters = [
                "source": source,
                "destination": destination,
                "rate": rate
            ]
        case let .iconSelectionScreenTransition(name):
            eventName = "icon_selection_screen_transition"
            parameters = [
                "name": name
            ]
        case .aboutScreenTransition:
            eventName = "about_screen_transition"
            parameters = nil
        case .scoreScreenTransition:
            eventName = "score_screen_transition"
            parameters = nil
        case .statisticsScreenTransition:
            eventName = "statistics_screen_transition"
            parameters = nil
        }
        
        guard let eventName else {
            Analytics.logEvent("logError: no event name", parameters: nil)
            AppsFlyerLib.shared().logEvent("logError: no event name", withValues: nil)
            return
        }
        
        Analytics.logEvent(eventName, parameters: parameters)
        AppsFlyerLib.shared().logEvent(eventName, withValues: parameters)
    }
}
