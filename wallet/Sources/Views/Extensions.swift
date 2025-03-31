//
//  Extensions.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import SwiftUI
import SwiftData
import ComposableArchitecture

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Date {
    func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, equalTo: date, toGranularity: component)
    }
}

extension Color {
    static func walletItemColor(for type: WalletItem.WalletItemType) -> Color {
        switch type {
        case .account: .yellow
        case .expenses: .green
        }
    }
}

extension DependencyValues {
    public var modelContext: ModelContext {
        get { self[ModelContextKey.self].value }
        set { self[ModelContextKey.self].value = newValue }
    }
    
    static let shared: ModelContainer = try! ModelContainer(for: WalletItemModel.self, WalletTransactionModel.self)
    private enum ModelContextKey: DependencyKey {
        static var liveValue: UncheckedSendable<ModelContext> {
            return UncheckedSendable(ModelContext(shared))
        }
    }
}
