//
//  Extensions.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
