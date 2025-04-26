//
//  TestData.swift
//  wallet
//
//  Created by Артём Зайцев on 26.04.2025.
//
import Foundation

private extension Date {
    static func makeDate(granularity: Calendar.Component) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        
        let hours = Int.random(in: 0...23)
        let minutes = Int.random(in: 0...59)
        let seconds = Int.random(in: 0...59)
        
        let day = calendar.component(.day, from: .now)
        let month = calendar.component(.month, from: .now)
        let year = calendar.component(.year, from: .now)
        
        switch granularity {
        case .day:
            return calendar.date(from: .init(year: year, month: month, day: day, hour: hours, minute: minutes, second: seconds)) ?? .now
        case .weekday:
            return calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: .now).date ?? .now
        case .month:
            return calendar.date(from: .init(year: year, month: month, hour: hours, minute: minutes, second: seconds)) ?? .now
        default:
            return .now
        }
    }
}

extension WalletTransaction {
    static func testTransactions(_ currency: Currency) -> [Self] {
        let dayTransactions: [WalletTransaction] = [
            .init(id: UUID(),
                  timestamp: .makeDate(granularity: .day),
                  currency: currency,
                  amount: 150,
                  commentary: "day 1",
                  rate: 1.0,
                  source: WalletItem.defaultAccounts[1],
                  destination: WalletItem.defaultExpenses[0])
        ]
        
        let weekTransactions: [WalletTransaction] = [
            .init(id: UUID(),
                  timestamp: .makeDate(granularity: .weekday),
                  currency: currency,
                  amount: 200,
                  commentary: "week 1",
                  rate: 1.0,
                  source: WalletItem.defaultAccounts[0],
                  destination: WalletItem.defaultExpenses[1])
        ]
        let monthTransactions: [WalletTransaction] = [
            .init(id: UUID(),
                  timestamp: .makeDate(granularity: .month),
                  currency: currency,
                  amount: 125,
                  commentary: "month 1",
                  rate: 1.0,
                  source: WalletItem.defaultAccounts[0],
                  destination: WalletItem.defaultExpenses[0])
        ]
        
        return [dayTransactions, weekTransactions, monthTransactions].flatMap { $0 }
    }
}
