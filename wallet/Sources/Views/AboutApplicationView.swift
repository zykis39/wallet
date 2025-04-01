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
        "Persistant Storage"
    ]
    let plans = [
        "Localization",
        "Currency Converter",
        "Adaptive interface",
    ]
    let contacts = [
        "Author: Artem Zaitsev",
        "Telegram: @zykis",
        "WhatsApp: +7(915)369-50-22",
    ]
    
    var body: some View {
        VStack(alignment: .center) {
            Form {
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
