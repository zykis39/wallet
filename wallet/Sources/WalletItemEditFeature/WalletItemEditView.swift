//
//  WalletItemEditView.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import ComposableArchitecture
import SwiftUI

struct WalletItemEditView: View {
    @Bindable var store: StoreOf<WalletItemEditFeature>
    @State private var formContentHeight: CGFloat?
    
    init(store: StoreOf<WalletItemEditFeature>) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            Header(leftSystemImageName: "xmark.circle.fill",
                   rightSystemImageName: "checkmark.circle.fill",
                   leftAction: { store.send(.presentedChanged(false)) },
                   rightAction: { store.send(.presentedChanged(false)) },
                   imageSize: 32)
            Spacer()
                .frame(height: 24)
            Text("Измените параметр \(store.item.type == .account ? "счета" : "расхода")")
                .font(.system(size: 24))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 0.5)
                    .foregroundStyle(Color.walletItemColor(for: store.item.type))
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(width: 64, height: 64)
            Form {
                TextField(text: $store.item.name.sending(\.nameChanged)) {
                    Text("Введите название")
                }
                .tint(.blue)
                Picker("Валюта: \(store.item.currency.representation) (\(store.item.currency.rawValue))",
                       selection: $store.item.currency.sending(\.currencyChanged)) {
                    ForEach(Currency.allCases, id: \.id) { currency in
                        Text("\(currency.representation) (\(currency.rawValue))").tag(currency)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            Button {} label: {
                Text("Удалить")
            }
            Spacer()
        }
        .padding()
        .tint(.white)
        .background(Color.walletItemColor(for: store.item.type))
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
    }
}
