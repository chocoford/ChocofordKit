//
//  GalleryLayout.swift
//  TrickleClips
//
//  Created by Dove Zachary on 2023/11/8.
//

import SwiftUI

@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
struct ScrollGallery<Content: View>: View {
    public typealias RowHeight = GalleryLayout.RowHeight
    
    var axis: Axis.Set.Element
    var animation: Animation? = nil
    
    var spacing: CGFloat = 10
    var rowSpacing: CGFloat = 10
    var rowHeight: RowHeight
    
    var content: Content
        
    public init(
        _ axis: Axis.Set.Element = .vertical,
        animation: Animation? = nil,
        rowHeight: RowHeight,
        spacing: CGFloat = 10,
        rowSpacing: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        
        self.animation = animation
        self.content = content()
        
        self.rowHeight = rowHeight
        self.spacing = spacing
        self.rowSpacing = rowSpacing
    }
    
    public init(
        _ axis: Axis.Set.Element = .vertical,
        animation: Animation? = nil,
        rowHeight: CGFloat,
        spacing: CGFloat = 10,
        rowSpacing: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            axis,
            animation: animation,
            rowHeight: .fixed(rowHeight),
            spacing: spacing,
            rowSpacing: rowSpacing,
            content: content
        )
    }
    
    @State private var width: CGFloat? = .zero
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollView(axis) {
                GalleryLayout(
                    rowHeight: rowHeight,
                    spacing: spacing,
                    rowSpacing: rowSpacing
                ) {
                    content
                }
                .animation(animation, value: geometry.size)
            }
        }
    }
}



/// Arrange items row by row.
/// Each item has same height, and their width are flexible
@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public struct GalleryLayout: Layout {
    var subviewsFrame: Binding<[CGRect]>?
    
    var spacing: CGFloat = 10
    var rowSpacing: CGFloat = 10
    var rowHeight: RowHeight
    
    public init(rowHeight: RowHeight, spacing: CGFloat = 10, rowSpacing: CGFloat = 10) {
        self.rowHeight = rowHeight
        self.spacing = spacing
        self.rowSpacing = rowSpacing
    }
    
    public init(rowHeight: CGFloat, spacing: CGFloat = 10, rowSpacing: CGFloat = 10) {
        self.rowHeight = .fixed(rowHeight)
        self.spacing = spacing
        self.rowSpacing = rowSpacing
    }
    
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        subviews.reduce(CGSize.zero) { result, subview in
            let size = subview.sizeThatFits(.unspecified)
            let width = proposal.replacingUnspecifiedDimensions().width
            var height = CGFloat.zero
            
            var point = CGPoint.zero
            for (i, subview) in subviews.enumerated() {
                let idealSize = subview.sizeThatFits(.unspecified)
                let aspectRatio = idealSize.height / idealSize.width
                var newWidth = idealSize.width
                var newHeight = idealSize.height

                switch self.rowHeight {
                    case .fixed(let height):
                        newHeight = height
                        newWidth = newHeight / aspectRatio
                    default:
                        //                    case .flexible(let minHeight, let maxHeight):
                        break
                }
                
                // avoid width to be larger than container's
                if newWidth > width {
                    newWidth = width
                    newHeight = aspectRatio * newWidth
                }
                
                if point.x > .zero && point.x + newWidth > width {
                    point.x = .zero
                    point.y += newHeight + self.rowSpacing
                } 
                if point.x == .zero {
                    switch self.rowHeight {
                        case .fixed(let rowHeight):
                            height += (i > 0 ? self.spacing : 0) + rowHeight
                        default:
                            break
                    }
                }
                point.x += newWidth + self.spacing
            }
            
            return CGSize(
                width: width,
                height: height
            )
        }
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var point = bounds.origin
        var previousHeight: CGFloat = .zero
        for subview in subviews {
            let idealSize = subview.sizeThatFits(.unspecified)
            let aspectRatio = idealSize.height / idealSize.width
            var newWidth = idealSize.width
            var newHeight = idealSize.height
            
            switch self.rowHeight {
                case .fixed(let height):
                    newHeight = height
                    newWidth = newHeight / aspectRatio
                default:
                    //                    case .flexible(let minHeight, let maxHeight):
                    break
            }
            
            // avoid width to be larger than container's
            if newWidth > bounds.width {
                newWidth = bounds.width
                newHeight = aspectRatio * newWidth
            }
            
            
            if point.x + newWidth > bounds.width {
                point.x = bounds.origin.x
                point.y += previousHeight + self.rowSpacing
            }
            
            subview.place(
                at: point,
                anchor: .topLeading,
                proposal: .init(width: newWidth, height: newHeight)
            )
            
            // update subviewsFrame
//            self.subviewsFrame.
            
            point.x += newWidth + self.spacing
            previousHeight = newHeight
        }
    }
}

@available(macOS 13.0, iOS 16.0, *)
extension GalleryLayout {
    public enum RowHeight: Hashable {
        case fixed(CGFloat)
        case flexible(_ min: CGFloat, _ max: CGFloat)
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ScrollView {
            if #available(macOS 13.0, *)  {
                GalleryLayout(rowHeight: .fixed(150)) {
                    ForEach(0..<20, id: \.self) { i in
                        Image("testimg\(i % 10)")
                            .resizable()
                    }
                }
                .animation(.bouncy, value: geometry.size)
                .padding()
                //        .border(.red)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
#endif
