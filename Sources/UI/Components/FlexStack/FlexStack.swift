import SwiftUI
//
//  FlexStack.swift
//  SearchMart
//
//  Created by Tanshow on 2022/9/25.
//
//  FlexStack Layout

@available(iOS 16.0, macOS 13.0, *)
public struct FlexStack: Layout {
    
    public var verticalSpacing = 8.0
    public var horizontalSpacing = 8.0
    
    public init(verticalSpacing: Double = 8.0, horizontalSpacing: Double = 8.0) {
        self.verticalSpacing = verticalSpacing
        self.horizontalSpacing = horizontalSpacing
    }
    
    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .none
        return properties
    }
    
    public struct CacheData {
        var matrix: [[Subviews.Element]] = [[]]
        var maxHeight: CGFloat = 0.0
    }
    
    public func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
    
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        
        let matrix = getMetrix(from: subviews, in: proposal)
        
        cache.matrix = matrix
        
        let maxHeight = matrix.reduce(0) { $0 + getMaxHeight(of: $1) + verticalSpacing } - verticalSpacing
        
        cache.maxHeight = maxHeight
        
        return CGSize(width: proposal.width ?? .infinity, height: maxHeight)
        
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        var pointer = CGPoint(x: bounds.minX, y: bounds.minY)
        for line in cache.matrix {
            line.forEach { subview in
                subview.place(at: pointer, proposal: .unspecified)
                pointer.x += subview.sizeThatFits(.unspecified).width + horizontalSpacing
            }
            pointer.x = bounds.minX
            pointer.y += getMaxHeight(of: line) + verticalSpacing
        }
    }
    
    /// Caculate the matrix of subviews
    func getMetrix(from subviews: Subviews, in proposal: ProposedViewSize) -> [[Subviews.Element]] {
        var matrixBuffer = [[]] as [[Subviews.Element]]
        
        // Flags
        let maxLineWidth = proposal.width ?? .infinity
        var lineWidthBuffer = 0.0
        var outterIndexBuffer = 0
        var isFirstOfLine = false
        
        for (_, subview) in subviews.enumerated() {
            
            lineWidthBuffer += subview.sizeThatFits(.unspecified).width
            
            // Handle with that the width of the first of line is wider than fmaxLineWidth
            if isFirstOfLine && lineWidthBuffer >= maxLineWidth {
                // Break line
                outterIndexBuffer += 1
                matrixBuffer.append([subview])
                lineWidthBuffer = 0.0
                isFirstOfLine = true
                continue
            }
            
            // Normal handle
            if lineWidthBuffer > maxLineWidth {
                // Break line
                outterIndexBuffer += 1
                lineWidthBuffer = subview.sizeThatFits(.unspecified).width + horizontalSpacing
                matrixBuffer.append([subview])
                isFirstOfLine = true
            } else {
                // Not break line
                matrixBuffer[outterIndexBuffer].append(subview)
                lineWidthBuffer += horizontalSpacing
                isFirstOfLine = false
            }
            
        }
        
        // print(matrixBuffer.map {$0.map { $0.sizeThatFits(.unspecified).width }})
        return matrixBuffer
    }
    
    /// Calculate max height of subviews
    func getMaxHeight(of subviews: [Subviews.Element]) -> CGFloat{
        return subviews.reduce(0) { max($0, $1.sizeThatFits(.unspecified).height) }
    }
    
}
