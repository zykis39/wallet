//
//  AnalyticsClient.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import FirebaseAnalytics

public enum Event {
    case appStarted(firstLaunch: Bool)
    case draggingStopped(source: String, destination: String)
    case itemTapped(itemName: String)
    case itemCreated(itemName: String, currency: String)
    case transactionCreated(source: String, destination: String, amount: Double)
}

public protocol AnalyticsClient {
    func logEvent(_ event: Event)
}

final class FirebaseAnalyticsClient: AnalyticsClient {
    func logEvent(_ event: Event) {
        switch event {
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
        }
    }
}
