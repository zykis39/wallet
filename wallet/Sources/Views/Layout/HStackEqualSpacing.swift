//
//  HStackEqualSpacing.swift
//  wallet
//
//  Created by Артём Зайцев on 10.03.2025.
//
import SwiftUI

struct HStackEqualSpacing: Layout {
    private let pageWidth: CGFloat
    private let columnsNumber: Int
    private let minElementWidth: CGFloat
    private let maxElementWidth: CGFloat
    private let alignment: VerticalAlignment
    private let offset: CGFloat
    
    init(pageWidth: CGFloat, columnsNumber: Int, minElementWidth: CGFloat, maxElementWidth: CGFloat, alignment: VerticalAlignment = .center, offset: CGFloat = 0) {
        self.pageWidth = pageWidth
        self.columnsNumber = columnsNumber
        self.minElementWidth = minElementWidth
        self.maxElementWidth = maxElementWidth
        self.alignment = alignment
        self.offset = offset
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let initialHeight = proposal.replacingUnspecifiedDimensions().height
        let _ = proposal.replacingUnspecifiedDimensions().width
        let resultWidth = (floor(CGFloat(subviews.count) / CGFloat(columnsNumber)) + 1) * pageWidth
        
        return CGSize(width: resultWidth, height: initialHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let initialHeight = proposal.replacingUnspecifiedDimensions().height
            let _ = proposal.replacingUnspecifiedDimensions().width
        let maxSubviewWidth = pageWidth / CGFloat(columnsNumber)
        
        for (index, subview) in subviews.enumerated() {
            let size: CGSize = subview.sizeThatFits(ProposedViewSize(width: maxSubviewWidth, height: initialHeight))
            let x = (CGFloat(index) * maxSubviewWidth + (maxSubviewWidth - size.width) / 2)
            
            let y: CGFloat = {
                switch alignment {
                case .top:
                    return 0
                case .center:
                    return (initialHeight - size.height) / 2
                default:
                    return (initialHeight - size.height) / 2
                }
            }() + offset
            let position = CGPoint(x: x + bounds.origin.x, y: y + bounds.origin.y)
            let proposal = ProposedViewSize(size)
            subview.place(at: position, proposal: proposal)
        }
    }
}
