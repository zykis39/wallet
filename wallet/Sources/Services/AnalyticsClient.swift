//
//  AnalyticsClient.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import FirebaseAnalytics
import FirebaseCrashlytics

public enum Event {
    case error(String)
    case appStarted(firstLaunch: Bool)
    case draggingStopped(source: String, destination: String)
    case itemTapped(itemName: String)
    case itemCreated(itemName: String, currency: String)
    case transactionCreated(source: String, destination: String, amount: Double)
    case aboutScreenTransition
    case expensesStatisticsScreenTransition
}

public protocol AnalyticsClient {
    func logEvent(_ event: Event)
}

final class FirebaseAnalyticsClient: AnalyticsClient {
    func logEvent(_ event: Event) {
        switch event {
        case let .error(message):
            Analytics.logEvent("error", parameters: ["message": message])
            Crashlytics.crashlytics().log(message)
        case let .appStarted(firstLaunch):
            Analytics.logEvent("AppStarted", parameters: ["firstLaunch": firstLaunch])
        case let .draggingStopped(source, destination):
            Analytics.logEvent("DraggingStopped", parameters: ["source": source,
                                                               "destination": destination])
        case let .itemTapped(itemName):
            Analytics.logEvent("ItemTapped", parameters: ["itemName": itemName])
        case let .itemCreated(itemName, currency):
            Analytics.logEvent("ItemCreated", parameters: ["itemName": itemName,
                                                           "currency": currency])
        case let .transactionCreated(source, destination, amount):
            Analytics.logEvent("TransactionCreated", parameters: ["source": source,
                                                                  "destination": destination,
                                                                  "amount": amount])
        case .aboutScreenTransition:
            Analytics.logEvent("AboutScreenTransition", parameters: nil)
        case .expensesStatisticsScreenTransition:
            Analytics.logEvent("ExpensesStatisticsScreenTransition", parameters: nil)
        }
    }
}
