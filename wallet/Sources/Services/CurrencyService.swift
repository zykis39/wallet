//
//  CurrencyService.swift
//  wallet
//
//  Created by Артём Зайцев on 05.04.2025.
//
import Alamofire
import Foundation

enum CurrencyServiceError: Error {
    case common(String)
}

enum CurrencyFilePaths {
    static let currencies = "currencies"
    static let conversionRates = "usd_rates"
    static let format = "json"
}

public protocol CurrencyServiceNetworkProtocol {
    func currencies(codes: [String]) async throws -> [Currency]
    func conversionRates(base baseCurrency: Currency, to: [Currency]) async throws -> [ConversionRate]
}

public protocol CurrencyServiceStorageProtocol {
    func save(_ currencies: [Currency]) throws
    func save(_ conversionRates: [ConversionRate]) throws
    func readCurrencies() throws -> [Currency]
    func readConversionRates(currencies: [Currency]) throws -> [ConversionRate]
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
    
    private let base = "https://api.freecurrencyapi.com/v1/"
    private let sessionManager = Alamofire.Session(configuration: .startupConfiguration)
//    private let APIKey = "fca_live_YLZQGJ50z3Ucc0ozfOszHN9ST2WqS7S6cpyuGHrZ"
    private let APIKey = "fca_live_IbfxWhf2Wj5luTg9EXKbdX2RKe2aiTmAKbxW2z3G"
    
    func currencies(codes: [String]) async throws -> [Currency] {
        let requestString = base + Paths.currencies
        let params = [
            ParamKeys.apikey: APIKey,
            ParamKeys.currencies: codes.joined(separator: ",")
        ]
        
        let request = sessionManager.request(requestString, parameters: params)
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
        
        let request = sessionManager.request(requestString, parameters: params)
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
    func save(_ currencies: [Currency]) throws {
        let documentsPath = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(CurrencyFilePaths.currencies, conformingTo: .json)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(currencies)
            try data.write(to: documentsPath)
        } catch {
            throw CurrencyServiceError.common("error writing to: currencies.json")
        }
    }
    
    func save(_ conversionRates: [ConversionRate]) throws {
        let documentsPath = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(CurrencyFilePaths.conversionRates, conformingTo: .json)
        do {
            let encoder = JSONEncoder()
            let ratesDictionary: [String: Double] = conversionRates.reduce(into: [:]) {
                $0[$1.destination.code] = $1.rate
            }
            let data = try encoder.encode(ratesDictionary)
            try data.write(to: documentsPath)
        } catch {
            throw CurrencyServiceError.common("error writing to: usd_rates.json")
        }
    }
    
    func readCurrencies() throws -> [Currency] {
        do {
            let documentsPath = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent(CurrencyFilePaths.currencies, conformingTo: .json)
            let data = try Data(contentsOf: documentsPath)
            let decoder = JSONDecoder()
            let currencies = try decoder.decode([Currency].self, from: data)
            return currencies
        } catch {
            guard let resourcesPath = Bundle.main.path(forResource: CurrencyFilePaths.currencies, ofType: CurrencyFilePaths.format) else {
                throw CurrencyServiceError.common("no file found: currencies.json")
            }
            let data = try Data(contentsOf: URL(fileURLWithPath: resourcesPath))
            let decoder = JSONDecoder()
            let currencies = try decoder.decode([Currency].self, from: data)
            return currencies
        }
    }
    
    func readConversionRates(currencies: [Currency]) throws -> [ConversionRate] {
        do {
            let documentsPath = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent(CurrencyFilePaths.conversionRates, conformingTo: .json)
            let data = try Data(contentsOf: documentsPath)
            let decoder = JSONDecoder()
            let ratesDictionary = try decoder.decode([String: Double].self, from: data)
            return try readRates(ratesDictionary)
        } catch {
            guard let resourcesPath = Bundle.main.path(forResource: CurrencyFilePaths.conversionRates, ofType: CurrencyFilePaths.format) else {
                throw CurrencyServiceError.common("no file found: usd_rates.json")
            }
            let data = try Data(contentsOf: URL(fileURLWithPath: resourcesPath))
            let decoder = JSONDecoder()
            let ratesDictionary = try decoder.decode([String: Double].self, from: data)
            return try readRates(ratesDictionary)
        }
        
        func readRates(_ ratesDictionary: [String: Double]) throws -> [ConversionRate] {
            guard let source: Currency = currencies.first(where: { $0.code == Currency.USD.code })  else {
                throw CurrencyServiceError.common("no USD currency found in currencies")
            }

            let rates = try ratesDictionary.map { rate in
                guard let destination: Currency = currencies.first(where: { currency in
                    currency.code == rate.key
                })  else {
                    throw CurrencyServiceError.common("no \(rate.key) currency found in currencies")
                }
                return ConversionRate(source: source, destination: destination, rate: rate.value)
            }
            return rates
        }
    }
}

struct CurrencyResponse: Decodable {
    let data: [String: Currency]
}

struct CurrecyRatesResponse: Decodable {
    let data: [String: Double]
}
