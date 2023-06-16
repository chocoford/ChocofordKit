//
//  Responsive.swift
//  
//
//  Created by Dove Zachary on 2023/5/14.
//

import SwiftUI

public enum UISizeClass: CaseIterable, Identifiable, Hashable {
    case compact
    case regular
    
    var maxWidth: CGFloat {
        switch self {
            case .compact:
                return 500
            case .regular:
                return 10000
        }
    }
    
    public  var id: CGFloat {
        return maxWidth
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
                .environment(\.uiSizeClass, width < UISizeClass.compact.maxWidth ? .compact : .regular)
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


// MARK: - Local Breakpoint
#if os(macOS)
/// Get the device class of the specific view
public struct Responsive<Content: View>: View {
    var content: (_ breakpoint: UISizeClass) -> Content
    
    public init(@ViewBuilder content: @escaping (_ breakpoint: UISizeClass) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        SingleAxisGeometryReader(axis: .horizontal) { width in
            if width < UISizeClass.compact.maxWidth {
                content(.compact)
            } else {
                content(.regular)
            }
        }
    }
}
#elseif os(iOS)
/// Get the device class of the specific view
public struct Responsive<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var content: (_ breakpoint: UISizeClass) -> Content
    
    public init(@ViewBuilder content: @escaping (_ breakpoint: UISizeClass) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        switch sizeClass {
            case .compact:
                content(.compact)
            case .regular:
                content(.regular)
            default:
                content(.regular)
        }
    }
}
#endif
