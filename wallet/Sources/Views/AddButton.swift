//
//  AddButton.swift
//  wallet
//
//  Created by Артём Зайцев on 29.03.2025.
//
import SwiftUI

struct AddButton: View {
    let color: Color
    let action: () -> Void
    init(color: Color, action: @escaping () -> Void) {
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "plus.square.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundStyle(color)
                .background(.white)
        }

    }
}
