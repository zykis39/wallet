//
//  TransactionsZeroScreen.swift
//  wallet
//
//  Created by Артём Зайцев on 25.05.2025.
//

import SwiftUI

struct TransactionsZeroScreen: View {
    var body: some View {
        VStack {
            Image(ImageResource(name: "zeroscreen_no_transactions", bundle: .main))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 24)
            Text("No transactions yet")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
        }
    }
}
