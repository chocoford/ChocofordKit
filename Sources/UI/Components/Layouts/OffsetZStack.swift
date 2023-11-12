//
//  OffsetZStack.swift
//  TrickleClips
//
//  Created by Dove Zachary on 2023/11/11.
//

import SwiftUI

@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public struct OffsetZStack: Layout {
    var direction: UnitPoint
    var spacing: CGFloat
    var scaleEffect: CGFloat
    
    /// - Parameters:
    ///   - direction: The direction of subviews
    ///   - spacing: The spacing betwwen subviews' center
    public init(
        direction: UnitPoint = .bottomTrailing,
        spacing: CGFloat = 10,
        scaleEffect: CGFloat = 1.0
    ) {
        self.direction = direction
        self.spacing = spacing
        self.scaleEffect = scaleEffect
    }
    
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var finalSize: CGSize = .zero
        let maxWidth = subviews.reversed().enumerated().reduce(.zero, { maxWidth, element in
            let (i, subview) = element
            let width = subview.sizeThatFits(.unspecified).width * pow(scaleEffect, Double(i)) + Double(i) * self.spacing
            return max(maxWidth, width)
        })
        let maxHeight = subviews.reversed().enumerated().reduce(.zero, { maxHeight, element in
            let (i, subview) = element
            
            let height = subview.sizeThatFits(.unspecified).height * pow(scaleEffect, Double(i)) + Double(i) * self.spacing
            return max(maxHeight, height)
        })
        
        switch direction {
            case .top, .bottom:
                finalSize.height = maxHeight
                finalSize.width = subviews.enumerated().reduce(.zero, { width, element in
                    let (i, subview) = element
                    return max(width, subview.sizeThatFits(.unspecified).width * pow(scaleEffect, Double(i)))
                })
            case .leading, .trailing:
                finalSize.height = subviews.enumerated().reduce(.zero, { width, element in
                    let (i, subview) = element
                    return max(width, subview.sizeThatFits(.unspecified).height * pow(scaleEffect, Double(i)))
                })
                finalSize.width = maxWidth
            case .topLeading, .topTrailing, .bottomLeading, .bottomTrailing:
                finalSize.height = maxHeight
                finalSize.width = maxWidth
                
            default:
                break
        }
        return finalSize
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews, cache: inout ()
    ) {
        guard let firstSubview = subviews.first else { return }
        var basePoint: CGPoint
        let anchor: UnitPoint
        let offsetX, offsetY: CGFloat
        switch direction {
            case .topLeading:
                anchor = .bottomTrailing
                basePoint = CGPoint(x: bounds.maxX, y: bounds.maxY)
                offsetX = -self.spacing
                offsetY = -self.spacing

            case .top:
                anchor = .bottom
                basePoint = CGPoint(x: bounds.midX, y: bounds.maxY)
                offsetX = 0
                offsetY = -self.spacing
            
            case .topTrailing:
                anchor = .bottomLeading
                basePoint = CGPoint(x: bounds.minX, y: bounds.maxY)
                offsetX = self.spacing
                offsetY = -self.spacing
                
            case .leading:
                anchor = .trailing
                basePoint = CGPoint(x: bounds.maxX, y: bounds.midY)
                offsetX = -self.spacing
                offsetY = 0
                
            case .center:
                anchor = .center
                basePoint = bounds.origin
                offsetX = 0
                offsetY = 0
                
            case .trailing:
                anchor = .leading
                basePoint = CGPoint(x: bounds.minX, y: bounds.midY)
                offsetX = self.spacing
                offsetY = 0
                
            case .bottomLeading:
                anchor = .topTrailing
                basePoint = CGPoint(x: bounds.maxX, y: bounds.minY)
                offsetX = -self.spacing
                offsetY = self.spacing
                
            case .bottom:
                anchor = .top
                basePoint = CGPoint(x: bounds.midX, y: bounds.maxY)
                offsetX = 0
                offsetY = -self.spacing
                
            case .bottomTrailing:
                anchor = .topLeading
                basePoint = bounds.origin
                offsetX = self.spacing
                offsetY = self.spacing
                
            default:
                anchor = .topLeading
                basePoint = bounds.origin
                offsetX = 0
                offsetY = 0
        }
        
        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
                .applying(
                    .identity
                        .scaledBy(
                            x: pow(self.scaleEffect, Double(i-1)),
                            y: pow(self.scaleEffect, Double(i-1))
                        )
                )
            subview.place(at: basePoint, anchor: anchor, proposal: .init(size))
            basePoint = basePoint.applying(.identity.translatedBy(x: offsetX, y: offsetY))
        }
    }
    

}

//@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
//public struct OffsetZStack: _VariadicView_UnaryViewRoot {
//    var direction: UnitPoint
//    var spacing: CGFloat
//    var scaleEffect: CGFloat
//    
//    /// - Parameters:
//    ///   - direction: The direction of subviews
//    ///   - spacing: The spacing betwwen subviews' center
//    public init(
//        direction: UnitPoint = .bottomTrailing,
//        spacing: CGFloat = 10,
//        scaleEffect: CGFloat = 1.0
//    ) {
//        self.direction = direction
//        self.spacing = spacing
//        self.scaleEffect = scaleEffect
//    }
//    
//    
//    @ViewBuilder
//    public func body(children: _VariadicView.Children) -> some View {
//        OffsetZStackLayout(direction: direction, spacing: spacing, scaleEffect: scaleEffect) {
//            ForEach(Array(children.enumerated()), id: \.element) { i, child in
//                child
//                    .zIndex(Double(children.count - i))
//                    .scaleEffect(pow(scaleEffect, Double(i)))
//            }
//        }
//    }
//}

#if DEBUG
#Preview {
    Group {
        if #available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
            ScrollView {
                VStack {
                    OffsetZStack(direction: .bottomLeading) {
                        ForEach(0..<5, id: \.self) { i in
                            Center {
                                Text("\(i)")
                                    .font(.largeTitle)
                            }
                            .background(.background, in: RoundedRectangle(cornerRadius: 4))
                            .compositingGroup()
                            .shadow(radius: 2)
                            .frame(width: 200, height: 200)
                            .zIndex(5-Double(i))
                        }
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
#endif
