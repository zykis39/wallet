//
//  SpendingsFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 15.04.2025.
//

import ComposableArchitecture
import SwiftUI

@Reducer
public struct SpendingsFeature: Reducer {
    @ObservableState
    public struct State: Equatable {
        var presented: Bool
        var period: Period
        var currency: Currency
        var spendings: [Spending]
        var chartSections: [PieChartSection]
        
        static let initial: Self = .init(presented: false, period: .month, currency: .USD, spendings: [], chartSections: [])
    }
    
    public enum Action: Sendable {
        case recalculateAndPresentSpendings(Period)
        case presentSpendings(Currency, [Spending], [PieChartSection])
        case presentedChanged(Bool)
        case chartSectionsChanged([PieChartSection])
        case periodChanged(Period)
    }
    
    public var body: some Reducer <State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentSpendings(currency, spendings, chartSections):
                state.currency = currency
                state.spendings = spendings
                // initial angles are equal
                state.chartSections = chartSections.map {
                    PieChartSection(name: $0.name, angle: 1, icon: $0.icon, color: $0.color, opacity: $0.opacity)
                }
                return .run { [chartSections] send in
                    await send(.presentedChanged(true))
                    // then animating to actual angles
                    try? await Task.sleep(for: .seconds(0.3))
                    await send(.chartSectionsChanged(chartSections))
                }
            case let .presentedChanged(presented):
                state.presented = presented
                return .none
            case let .chartSectionsChanged(chartSections):
                state.chartSections = chartSections
                return .none
            case let .periodChanged(period):
                state.period = period
                return .run { send in
                    await send(.recalculateAndPresentSpendings(period))
                }
            case .recalculateAndPresentSpendings:
                return .none
            }
        }
    }
}

public struct PieChartSection: Hashable, Sendable {
    let name: String
    let angle: Double
    let icon: String
    let color: Color
    let opacity: Double
}

public struct Spending: Hashable, Sendable {
    let name: String
    let icon: String
    let expenses: Double
    let percent: Double
    let currency: Currency
    let color: Color
    
    static var preferredColors: [Color] = [
        .cyan,
        .orange,
        .brown,
        .pink,
        .mint,
        .teal,
        .yellow,
    ]
}
