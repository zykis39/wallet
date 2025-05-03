//
//  AboutApplicationView.swift
//  wallet
//
//  Created by Артём Зайцев on 01.04.2025.
//
import SwiftUI

struct AboutApplicationView: View {
    let stack = [
        "SwiftUI",
        "SwiftData",
        "swift-composable-architecture",
        "Firebase",
    ]
    let features = [
        "Custom Drag-n-Drop",
        "Animated Swift Charts",
        "Persistant Storage",
        "Localization (8 languages)",
        "Accounts/Expenses rearrangment",
        "Currency Converter",
        "Multi-currency custom transaction rate, depending on the entering currency",
        "Adaptive interface",
    ]
    let plans = [
        "Drag-n-Drop animations",
        "double-currency TextField",
    ]
    let contacts = [
        "Author: Artem Zaitsev",
        "Telegram: @zykis",
        "WhatsApp: +7(915)369-50-22",
        "Sources: https://github.com/zykis39/wallet",
    ]
    
    var body: some View {
        VStack(alignment: .center) {
            Form {
                if let appVersion = UIApplication.appVersion {
                    Section("Version:") {
                        Text(appVersion)
                    }
                }
                Section("Stack:") {
                    ForEach(stack, id: \.self) { framework in
                        Text("•" + framework)
                    }
                }
                Section("Features:") {
                    ForEach(features, id: \.self) { feature in
                        Text("•" + feature)
                    }
                }
                Section("Plans:") {
                    ForEach(plans, id: \.self) { plan in
                        Text("•" + plan)
                    }
                }
                Section("Contacts:") {
                    ForEach(contacts, id: \.self) { contact in
                        Text(contact)
                    }
                }
            }
            .navigationTitle("Wallet App")
        }
    }
}

#Preview {
    AboutApplicationView()
}
