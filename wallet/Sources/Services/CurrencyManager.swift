//
//  CurrencyManager.swift
//  wallet
//
//  Created by Артём Зайцев on 05.04.2025.
//
import Foundation

public protocol CurrencyManager {
    var currencies: [Currency] { get set }
    func defaultCurrency(for locale: Locale, from currencies: [Currency]) -> Currency
}

final class CurrencyManagerImpl: CurrencyManager {
    static let shared: CurrencyManagerImpl = CurrencyManagerImpl()
    
    var currencies: [Currency] = []
    func defaultCurrency(for locale: Locale, from currencies: [Currency]) -> Currency {
        switch locale.language.languageCode {
        case .english:
            return .USD
        case .italian, .french, .spanish, .german:
            return currencies.filter { $0.code == "EUR" }.first ?? .USD
        case .hebrew:
            return currencies.filter { $0.code == "ILS" }.first ?? .USD
        case .hindi:
            return currencies.filter { $0.code == "INR" }.first ?? .USD
        case .russian:
            return currencies.filter { $0.code == "RUB" }.first ?? .USD
        default:
            return .USD
        }
    }
}
