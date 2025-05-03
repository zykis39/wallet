//
//  AppScore.swift
//  wallet
//
//  Created by Артём Зайцев on 03.05.2025.
//
import ComposableArchitecture
import SwiftUI

struct AppScore: View {
    @Bindable var store: StoreOf<AppScoreFeature>
    
    var body: some View {
        VStack(spacing: 24) {
            Section("Write a review") {
                RatingView(rating: $store.score.sending(\.scoreChanged))
                TextEditor(text: $store.review.sending(\.reviewChanged))
                    .frame(maxHeight: 120)
                    .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.primary, lineWidth: 2 / 3)
                                    .fill(Color.secondary.gradient.opacity(0.075))
                                    .opacity(0.3)
                            )
                Button { [weak store] in
                    guard let store else { return }
                    store.send(.sendReview(store.state.score, store.state.review))
                } label: {
                    Text("Send")
                }.buttonStyle(.bordered)
                Spacer()
            }
        }
        .padding()
    }
}

//#Preview {
//    AppScore(rating: .constant(4),
//             review: .constant("Pretty okay application"))
//}
