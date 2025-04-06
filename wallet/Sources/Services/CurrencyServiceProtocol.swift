//
//  CurrencyService.swift
//  wallet
//
//  Created by Артём Зайцев on 05.04.2025.
//
import Alamofire
import Foundation

public protocol CurrencyServiceNetworkProtocol {
    func currencies(codes: [String]) async throws -> [Currency]
    func conversionRates(base baseCurrency: Currency, to: [Currency]) async throws -> [ConversionRate]
}

public protocol CurrencyServiceStorageProtocol {
    func save(_ currencies: [Currency])
    func save(_ conversionRates: [ConversionRate])
    func readCurrencies() throws -> [Currency]
    func readConversionRates() throws -> [ConversionRate]
}

public protocol CurrencyServiceProtocol: CurrencyServiceNetworkProtocol, CurrencyServiceStorageProtocol {}

final class CurrencyService: CurrencyServiceProtocol {
    enum Paths {
        static let currencies = "currencies"
        static let coversionRates = "latest"
    }
    
    enum ParamKeys {
        static let apikey = "apikey"
        static let currencies = "currencies"
        static let baseCurrency = "base_currency"
    }
    
    let base = "https://api.freecurrencyapi.com/v1/"
    let APIKey = "fca_live_YLZQGJ50z3Ucc0ozfOszHN9ST2WqS7S6cpyuGHrZ"
    
    func currencies(codes: [String]) async throws -> [Currency] {
        let requestString = base + Paths.currencies
        let params = [
            ParamKeys.apikey: APIKey,
            ParamKeys.currencies: codes.joined(separator: ",")
        ]
        let request = AF.request(requestString, parameters: params)
        let result = await request
            .validate()
            .serializingDecodable(CurrencyResponse.self)
            .response.result
        
        switch result {
        case let .success(currencyResponse):
            return currencyResponse.data.values.map { $0 }
        case let .failure(afError):
            throw afError
        }
    }
    
    func conversionRates(base baseCurrency: Currency = .USD, to: [Currency]) async throws -> [ConversionRate] {
        let requestString = base + Paths.coversionRates
        let params = [
            ParamKeys.apikey: APIKey,
            ParamKeys.baseCurrency: baseCurrency.code,
            ParamKeys.currencies: to.map { $0.code }.joined(separator: ",")
        ]
        
        let request = AF.request(requestString, parameters: params)
        let result = await request
            .validate()
            .serializingDecodable(CurrecyRatesResponse.self)
            .response.result
        
        switch result {
        case let .success(currecyRatesResponse):
            return currecyRatesResponse.data.compactMap { rate in
                guard let destination = to.first(where: { rate.key == $0.code }) else { return nil }
                return ConversionRate(source: baseCurrency, destination: destination, rate: rate.value)
            }
        case let .failure(afError):
            throw afError
        }
    }
}

extension CurrencyService: CurrencyServiceStorageProtocol {
    func save(_ currencies: [Currency]) {}
    
    func save(_ conversionRates: [ConversionRate]) {}
    
    func readCurrencies() throws -> [Currency] {
        []
    }
    
    func readConversionRates() throws -> [ConversionRate] {
        []
    }
}

struct CurrencyResponse: Decodable {
    let data: [String: Currency]
}

struct CurrecyRatesResponse: Decodable {
    let data: [String: Double]
}
