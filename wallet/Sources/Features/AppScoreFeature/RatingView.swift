//
//  RatingView.swift
//  wallet
//
//  Created by Артём Зайцев on 03.05.2025.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    var label = ""
    
    var maximumRating = 5

    var offImage: Image?
    var onImage: Image = Image(systemName: "star.fill")

    var offColor = Color.gray
    var onColor = Color.yellow
    
    var body: some View {
        HStack {
            if label.isEmpty == false {
                Text(label)
            }

            ForEach(1..<maximumRating + 1, id: \.self) { number in
                Button {
                    rating = number
                } label: {
                    image(for: number)
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundStyle(number > rating ? offColor : onColor)
                }
            }
        }
    }
    
    func image(for number: Int) -> Image {
        if number > rating {
            offImage ?? onImage
        } else {
            onImage
        }
    }
}

#Preview {
    RatingView(rating: .constant(4))
}
