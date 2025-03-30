//
//  CurrencyFormatter.swift
//  wallet
//
//  Created by Артём Зайцев on 30.03.2025.
//
import SwiftUI

final class CurrencyFormatter {
    static func formattedTextField(_ oldValue: String, _ newValue: String) -> String {
        var finalValue = newValue
        if newValue.count > oldValue.count {
            finalValue = self.processInsert(oldValue: oldValue, newValue: newValue)
        } else {
            finalValue = self.processDelete(oldValue: oldValue, newValue: newValue)
        }

        return finalValue.replacingOccurrences(of: ",", with: ".")
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
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let result = formatter.string(from: NSNumber(value: value))?.replacingOccurrences(of: ",", with: ".") ?? ""
        return result
    }
}
