//
//  AppScoreFeature.swift
//  wallet
//
//  Created by Артём Зайцев on 03.05.2025.
//

import ComposableArchitecture

@Reducer
public struct AppScoreFeature {
    @ObservableState
    public struct State: Equatable {
        var score: Int = 0
        var review: String = ""
        var presented: Bool = false
        
        static let initial: Self = .init()
    }
    
    public enum Action: Sendable {
        case presentedChanged(Bool)
        case scoreChanged(Int)
        case reviewChanged(String)
        case sendReview(Int, String)
    }
    
    @Dependency(\.appScoreService) var appScoreService
    @Dependency(\.analytics) var analytics
    @Dependency(\.defaultAppStorage) var appStorage
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentedChanged(presented):
                state.presented = presented
                return .run { _ in
                    analytics.logEvent(.scoreScreenTransition)
                }
            case let .scoreChanged(score):
                state.score = score
                return .none
            case let .reviewChanged(review):
                state.review = review
                return .none
            case let .sendReview(rating, message):
                return .run { send in
                    try await appScoreService.sendPersonalReview(rating: rating, review: message)
                    if rating > 3 {
                        await appScoreService.requestAppStoreRating()
                    }
                    await send(.presentedChanged(false))
                }
            }
        }
    }
}
