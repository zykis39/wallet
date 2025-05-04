//
//  CurrencyFormatter.swift
//  wallet
//
//  Created by Артём Зайцев on 30.03.2025.
//
import SwiftUI

final class CurrencyFormatter {
    static func formattedTextField(_ oldValue: String, _ newValue: String) -> String {
        guard newValue != "0" else { return "" }
        
        var finalValue = newValue
        if newValue.count > oldValue.count {
            finalValue = self.processInsert(oldValue: oldValue, newValue: newValue)
        } else {
            finalValue = self.processDelete(oldValue: oldValue, newValue: newValue)
        }

        return finalValue
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
    }
    
    static func processInsert(oldValue: String, newValue: String) -> String {
        let value = newValue.split(separator: /[,.]/)
        if value.count == 2,
           let _ = value.first,
           let fractionalPart = value.last,
           fractionalPart.count > 2 {
            return oldValue
        } else {
            return newValue
        }
    }
    
    static func processDelete(oldValue: String, newValue: String) -> String {
        return newValue
    }
    
    static func representation(for value: Double) -> String {
        guard value != 0 else { return "" }
        return formatterWithoutSpaces.string(from: NSNumber(value: value)) ?? ""
    }
    
    static var formatterWithoutZeroSymbol: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    static var formatterWithoutSpaces: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        formatter.zeroSymbol = ""
        return formatter
    }()
    
    static var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.decimalSeparator = "."
        return formatter
    }()
}
