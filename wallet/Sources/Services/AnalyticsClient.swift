//
//  AnalyticsClient.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import FirebaseAnalytics
import FirebaseCrashlytics
import AppsFlyerLib

public enum Event {
    case error(String)
    case appStarted(firstLaunch: Bool)
    case draggingStopped(source: String, destination: String)
    case itemTapped(itemName: String)
    case itemCreated(itemName: String, currency: String)
    case transactionCreated(source: String, destination: String, amount: Double)
    case aboutScreenTransition
    case scoreScreenTransition
    case expensesStatisticsScreenTransition
}

public protocol AnalyticsClient {
    func logEvent(_ event: Event)
}

final class FirebaseAnalyticsClient: AnalyticsClient {
    func logEvent(_ event: Event) {
        switch event {
        case let .error(message):
            let name = "error"
            let parameters = ["message": message]
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
            Crashlytics.crashlytics().log(message)
        case let .appStarted(firstLaunch):
            let name = "AppStarted"
            let parameters = ["firstLaunch": firstLaunch]
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case let .draggingStopped(source, destination):
            let name = "DraggingStopped"
            let parameters = ["source": source,
                              "destination": destination]
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case let .itemTapped(itemName):
            let name = "ItemTapped"
            let parameters = ["itemName": itemName]
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case let .itemCreated(itemName, currency):
            let name = "ItemCreated"
            let parameters = ["itemName": itemName,
                              "currency": currency]
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case let .transactionCreated(source, destination, amount):
            let name = "TransactionCreated"
            let parameters = ["source": source,
                              "destination": destination,
                              "amount": amount] as [String : Any]
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case .aboutScreenTransition:
            let name = "AboutScreenTransition"
            let parameters: [String: Any]? = nil
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case .scoreScreenTransition:
            let name = "ScoreScreenTransition"
            let parameters: [String: Any]? = nil
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        case .expensesStatisticsScreenTransition:
            let name = "ExpensesStatisticsScreenTransition"
            let parameters: [String: Any]? = nil
            
            Analytics.logEvent(name, parameters: parameters)
            AppsFlyerLib.shared().logEvent(name, withValues: parameters)
        }
    }
}
