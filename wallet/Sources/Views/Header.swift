//
//  Header.swift
//  wallet
//
//  Created by Артём Зайцев on 28.03.2025.
//
import SwiftUI

struct Header: View {
    let leftSystemImageName: String
    let rightSystemImageName: String
    let leftAction: () -> Void
    let rightAction: () -> Void
    let imageSize: CGFloat
    let middleSystemImageName: String?
    let leftText: String?
    let rightText: String?
    
    init(leftSystemImageName: String, rightSystemImageName: String, leftAction: @escaping () -> Void, rightAction: @escaping () -> Void, imageSize: CGFloat, middleSystemImageName: String? = nil, leftText: String? = nil, rightText: String? = nil) {
        self.leftSystemImageName = leftSystemImageName
        self.rightSystemImageName = rightSystemImageName
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.imageSize = imageSize
        self.middleSystemImageName = middleSystemImageName
        self.leftText = leftText
        self.rightText = rightText
    }
    
    var body: some View {
        HStack {
            Button {
                leftAction()
            } label: {
                Image(systemName: leftSystemImageName)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
            
            Spacer()
            Text(leftText ?? "")
            Spacer()
            
            Image(systemName: middleSystemImageName ?? "")
                .resizable()
                .frame(width: imageSize / 2, height: imageSize / 2)
            
            Spacer()
            Text(rightText ?? "")
            Spacer()
            
            Button {
                rightAction()
            } label: {
                Image(systemName: rightSystemImageName)
                    .resizable()
                    .frame(width: imageSize, height: imageSize)
            }
        }
    }
}
