//
//  HStackEqualSpacing.swift
//  wallet
//
//  Created by Артём Зайцев on 10.03.2025.
//
import SwiftUI

struct HStackEqualSpacing<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        HStack {
            content()
        }
    }
}

struct HStackEqualSpacingLayout: Layout {
    private let columnsNumber: Int
    private let minElementWidth: CGFloat
    private let maxElementWidth: CGFloat
    
    init(columnsNumber: Int, minElementWidth: CGFloat, maxElementWidth: CGFloat) {
        self.columnsNumber = columnsNumber
        self.minElementWidth = minElementWidth
        self.maxElementWidth = maxElementWidth
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let initialHeight = proposal.replacingUnspecifiedDimensions().height
            let initialWidth = proposal.replacingUnspecifiedDimensions().width
        
        return CGSize(width: initialWidth, height: initialHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let initialHeight = proposal.replacingUnspecifiedDimensions().height
            let initialWidth = proposal.replacingUnspecifiedDimensions().width
        let maxSubviewWidth = initialWidth / CGFloat(columnsNumber)
        for (index, subview) in subviews.enumerated() {
            let size: CGSize = subview.sizeThatFits(ProposedViewSize(width: maxSubviewWidth, height: initialHeight))
            let x = CGFloat(index) * maxSubviewWidth + (maxSubviewWidth - size.width) / 2
            let y = (initialHeight - size.height) / 2
            let position = CGPoint(x: x + bounds.origin.x, y: y + bounds.origin.y)
            let proposal = ProposedViewSize(size)
            subview.place(at: position, proposal: proposal)
        }
    }
}
