//
//  Responsive.swift
//  
//
//  Created by Dove Zachary on 2023/5/14.
//

import SwiftUI

//public protocol ResponsiveRule {
//    var compact: CGFloat { get }
//    var regular: CGFloat { get }
//}

/// The rule of responsive, in which are max-width.
public struct ResponsiveRule {
    public static var `default` = ResponsiveRule(compact: 500, regular: 1200)
    
    public var compact: CGFloat
    public var regular: CGFloat
    
    init(compact: CGFloat, regular: CGFloat) {
        self.compact = compact
        self.regular = regular
    }
}

internal func getSizeClass(_ width: CGFloat, with rule: ResponsiveRule = .default) -> UISizeClass {
    switch width {
        case 0..<rule.compact:
            return .compact
        case rule.compact..<rule.regular:
            return .regular
        default:
            return .regular
    }
}

public enum UISizeClass: String, CaseIterable, Identifiable, Hashable {
    case compact
    case regular
    
    public var id: String {
        self.rawValue
    }
}
// MARK: - Envrionment Key
struct UISizeClassKey: EnvironmentKey {
  #if os(macOS)
    static var defaultValue: UISizeClass = .compact
  #else
    static var defaultValue: UISizeClass = .compact
  #endif
}

public extension EnvironmentValues {
    var uiSizeClass: UISizeClass {
        get { self[UISizeClassKey.self] }
        set { self[UISizeClassKey.self] = newValue }
    }
}

public extension View {
    @ViewBuilder
    func responsive() -> some View {
        self
            .modifier(ResponsiveModifier())
    }
}


struct ResponsiveModifier: ViewModifier {
    func body(content: Content) -> some View {
#if os(macOS)
        SingleAxisGeometryReader(axis: .horizontal) { width in
            content
                .environment(\.uiSizeClass, getSizeClass(width))
        }
#elseif os(iOS)
        content
            .modifier(GetSizeClassModifier())
#endif
    }
}


#if os(iOS)
struct GetSizeClassModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State var currentSizeClass: UISizeClass = .compact
    func body(content: Content) -> some View {
        content
            .task(id: sizeClass) {
                if let sizeClass {
                    switch sizeClass {
                        case .compact:
                            currentSizeClass = .compact
                        case .regular:
                            currentSizeClass = .regular
                        default:
                            currentSizeClass = .compact
                    }
                }
            }
            .environment(\.uiSizeClass, currentSizeClass)
    }
}
#endif


/// Get the device class of the specific view
internal struct ResponsiveView<Content: View>: View {
    @Environment(\.uiSizeClass) private var uiSize

    var content: (_ breakpoint: UISizeClass) -> Content
    
    public init(@ViewBuilder content: @escaping (_ breakpoint: UISizeClass) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(uiSize)
    }
}

public struct Responsive<Content: View>: View {
    var content: (_ breakpoint: UISizeClass) -> Content
    public init(@ViewBuilder content: @escaping (_ breakpoint: UISizeClass) -> Content) {
        self.content = content
    }
    public var body: some View {
        ResponsiveView { breakpoint in
            content(breakpoint)
        }
        .responsive()
    }
}


@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public struct ResponsiveHStack: Layout {
    var rule: ResponsiveRule
    
    init(rule: ResponsiveRule = .default) {
        self.rule = rule
    }
    
    public struct CacheData {}
    
    public func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
    
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        // Calculate and return the size of the layout container.
        let sizeClass: UISizeClass = getSizeClass(proposal.width ?? 0, with: rule)
//        switch sizeClass {
//            case .compact:
//            case .regular:
//        }
        
        return CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }
    
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        // Tell each subview where to appear.
        var point = bounds.origin
        for subview in subviews {
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
            point.x += subview.dimensions(in: .unspecified).width
        }
    }
}



#if DEBUG
struct Responsive_Previews: PreviewProvider {
    static var previews: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            ResponsiveHStack {
                Text("ResponsiveHStack")
                
                Text("ResponsiveHStack")
                
                Text("ResponsiveHStack")
                
            }
        } else {
            // Fallback on earlier versions
            Text("Not support")
        }
    }
}
#endif
