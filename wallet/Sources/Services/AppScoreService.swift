//
//  AppScoreService.swift
//  wallet
//
//  Created by Артём Зайцев on 03.05.2025.
//
import Alamofire
import Foundation
import StoreKit

enum AppScoreServiceError: Error {
    case common(String)
}

public protocol AppScoreServiceProtocol {
    func sendPersonalReview(rating: Int, review: String) async throws
    @MainActor func requestAppStoreRating()
}

final class AppScoreService: AppScoreServiceProtocol {
    private let telegramBotToken = "7988386918:AAFL6XCasZAnPPAC9GxK-aF2P9I4DJ3hEls"
    private let chatID = "249299014"
    private let sessionManager = Alamofire.Session(configuration: .default)
    private func sendMessageEndpoint(token: String, chatID: String, message: String) -> URL? {
        guard !message.isEmpty else { return nil }
        let urlString = "https://api.telegram.org/bot\(token)/sendMessage?chat_id=\(chatID)&text=\(message)"
        return URL(string: urlString)
    }
    
    func sendPersonalReview(rating: Int, review: String) async throws {
        let message = "RATING: \(rating), MESSAGE: \(review)"
        guard let url = sendMessageEndpoint(token: telegramBotToken,
                                            chatID: chatID,
                                            message: message) else {
            throw AppScoreServiceError.common("wrong url for telegramm message")
        }
        
        let request = sessionManager.request(url)
        let result = await request
            .validate(statusCode: 200..<300)
            .serializingResponse(using: .string)
            .response
        
        switch result.result {
        case let .success(res):
            print(res)
        case let .failure(error):
            print(error.localizedDescription)
        }
    }
    
    func requestAppStoreRating() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        }
    }
}
