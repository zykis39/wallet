//
//  SettingsView.swift
//  wallet
//
//  Created by Артём Зайцев on 07.04.2025.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<WalletFeature>
    let currencies: [Currency]
    let locales: [Locale]
    @State var selectedLocale: Locale
    @State var selectedCurrency: Currency
    @State var isReorderButtonHidden: Bool
    @Dependency(\.defaultAppStorage) var appStorage
    
    init(store: StoreOf<WalletFeature>, selectedLocale: Locale, selectedCurrency: Currency, isReorderButtonVisible: Bool) {
        self.store = store
        self.selectedLocale = selectedLocale
        self.selectedCurrency = selectedCurrency
        self.isReorderButtonHidden = isReorderButtonVisible
        self.currencies = store.state.currencies
        self.locales = store.state.supportedLocales
    }
    
    private func languageText(_ locale: Locale) -> String {
        if let language = locale.localizedString(forLanguageCode: locale.identifier) {
            return "\(language.capitalized) - \(locale.identifier)"
        } else {
            return locale.identifier
        }
    }
    
    private func currencyText(_ currency: Currency) -> String {
        return "\(currency.code) - \(currency.fixedSymbol)"
    }
    
    var body: some View {
        Form {
            Section("Locale") {
                Picker("Language", selection: $selectedLocale) {
                    ForEach(locales, id: \.self) { locale in
                        Text(languageText(locale))
                    }
                }
            }
            
            Section("Currency") {
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(currencies, id: \.self) { currency in
                        Text(currencyText(currency))
                    }
                }
            }
            
            Section("Common") {
                Toggle(isOn: $isReorderButtonHidden) {
                    Text("Hide reorder button")
                }
                Button("Leave a review") { store.send(.appScore(.presentedChanged(true))) }
            }
            
            #if DEBUG
            Section("DEBUG") {
            }
            #endif
            
            Button("Settings.About.ButtonTitle") {
                store.send(.aboutAppPresentedChanged(true))
            }
        }
        .toolbar {
            Button("Save") {
                store.send(.selectedLocaleChanged(selectedLocale))
                store.send(.selectedCurrencyChanged(selectedCurrency))
                store.send(.isReorderButtonHiddenChanged(isReorderButtonHidden))
                store.send(.settingsPresentedChanged(false))
                
                appStorage.set(isReorderButtonHidden, forKey: AppStorageKey.isReorderButtonHidden)
            }
        }
    }
}
