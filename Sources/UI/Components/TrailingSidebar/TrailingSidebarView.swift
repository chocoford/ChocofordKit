//
//  TrailingSidebarView.swift
//  
//
//  Created by Dove Zachary on 2023/8/15.
//

import SwiftUI

struct TrailingSidebarView<Master: View, Detail: View>: View {
    @Environment(\.uiSizeClass) var uiSize
    
    @Binding var sidebarVisibility: Bool
    var master: () -> Master
    var sidebar: () -> Detail
    
    init(
        sidebarVisibility: Binding<Bool>,
        @ViewBuilder master: @escaping () -> Master,
        @ViewBuilder sidebar: @escaping () -> Detail
    ) {
        self._sidebarVisibility = sidebarVisibility
        self.master = master
        self.sidebar = sidebar
    }
    
//    @State private var currentSize: UISizeClass = .regular
    
    var body: some View {
        let _ = print("[TrailingSidebarView] refresh")
        if #available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *) {
            TrailingSidebarContainer/*(currentSize: $currentSize)*/ {
                master()
                if sidebarVisibility {
                    sidebar()
                        .apply(sidebarTransition)
                }
            }
        } else {
        // This will reinit subviews.
            Responsive { sizeClass in
                switch sizeClass {
                    case .regular:
                        HStack(spacing: 0) {
                            master()
                            if sidebarVisibility {
                                sidebar()
                                    .apply(sidebarTransition)
                            }
                        }
                    case .compact:
                        VStack(spacing: 0) {
                            master()
                            if sidebarVisibility {
                                sidebar()
                                    .apply(sidebarTransition)
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    func sidebarTransition<Content: View>(content: Content) -> some View {
        content
            .transition(
                .move(edge: self.uiSize == .regular ? .trailing : .bottom)
                .combined(with: .fade)
                .animation(.default)
            )
    }
}

@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
struct TrailingSidebarContainer: Layout {
    var rule: ResponsiveRule
    var sidebarMinWidth: CGFloat = 300
    var compactMainViewMinHeight: CGFloat = 500
    
//    @Binding var currentSize: UISizeClass
    
    init(/*currentSize: Binding<UISizeClass>, */rule: ResponsiveRule = .default) {
        print("[TrailingSidebarContainer] init")
//        self._currentSize = currentSize
        self.rule = rule
    }
    
    public struct CacheData {}
    
    public func makeCache(subviews: Subviews) -> CacheData {
        CacheData()
    }
    
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        if subviews.count > 2 {
            print("[Warning]<TrailingSidebarContainer>: multiple views detected, ignore redundant views...")
        }
        // Tell each subview where to appear.
        var point = bounds.origin
        
        if subviews.count == 1, let subView = subviews.first {
            subView.place(
                at: bounds.origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
            )
            return
        }
        
        let sizeClass = getSizeClass(bounds.width)
        switch sizeClass {
            case .compact:
                for (i, subview) in subviews.enumerated() {
                    switch i {
                        case 0:
                            subview.place(
                                at: CGPoint(x: bounds.midX, y: bounds.minY + self.compactMainViewMinHeight / 2),
                                anchor: .center,
                                proposal: ProposedViewSize(width: bounds.width, height: self.compactMainViewMinHeight)
                            )
                            point.y += self.compactMainViewMinHeight
                        case 1:
                            subview.place(
                                at: CGPoint(x: bounds.midX, y: point.y + (bounds.height - self.compactMainViewMinHeight) / 2),
                                anchor: .center,
                                proposal: ProposedViewSize(width: bounds.width, height: (bounds.height - self.compactMainViewMinHeight))
                            )
                        default:
                            break
                    }
                }
            case .regular:
                for (i, subview) in subviews.enumerated() {
                    switch i {
                        case 0:
                            subview.place(
                                // bounds.minX is necessary
                                at: CGPoint(x: bounds.minX + (bounds.width - self.sidebarMinWidth) / 2, y: bounds.midY),
                                anchor: .center,
                                proposal: ProposedViewSize(width: bounds.width - self.sidebarMinWidth, height: bounds.height)
                            )
                            point.x += bounds.width - self.sidebarMinWidth
                        case 1:
                            subview.place(
                                at: CGPoint(x: point.x + self.sidebarMinWidth / 2, y: bounds.midY),
                                anchor: .center,
                                proposal: ProposedViewSize(width: self.sidebarMinWidth, height: bounds.height)
                            )
                        default:
                            break
                    }
                }
        }
//        self.currentSize = sizeClass
//        print(self.currentSize)
    }
    
    private func maxSize(subviews: Subviews) -> CGSize {
        let subviewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let maxSize: CGSize = subviewSizes.reduce(.zero) { currentMax, subviewSize in
            CGSize(
                width: max(currentMax.width, subviewSize.width),
                height: max(currentMax.height, subviewSize.height))
        }

        return maxSize
    }
}

extension View {
    @ViewBuilder
    public func trailingSidebar<Content: View>(
        isPresent: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        TrailingSidebarView(sidebarVisibility: isPresent) {
            self
        } sidebar: {
            content()
        }
        .responsive()
    }
}


#if DEBUG
struct TrailingSidebarMasterPreviewView: View {
    @State private var count = 0
    var body: some View {
        Stepper("", value: $count)
        Text(String(count))
    }
}

struct TrailingSidebarPreviewView: View {
    @State private var width: CGFloat = 500
    @State private var showSidebar: Bool = false
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(.red)
                .overlay {
//                    TrailingSidebarMasterPreviewView()
                    VStack {
                        Text("Master view")
                        Button("Toggle sidebar") {
                            withAnimation {
                                showSidebar.toggle()
                            }
                        }
                    }
                }
                .trailingSidebar(isPresent: $showSidebar) {
                    Rectangle()
                        .fill(.green)
                        .overlay {
                            Text("Side view")
                        }
                }
                .frame(width: width)
            
            Slider(value: $width, in: 200...800)
        }
    }
}


struct TrailingSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        TrailingSidebarPreviewView()
    }
}
#endif
