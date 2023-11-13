//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/13.
//

#if canImport(SwiftUI)
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
public typealias Window = NSWindow
#elseif canImport(UIKit)
public typealias Window = UIWindow
#endif

// 1. Create the key with a default value
private struct WindowKey: EnvironmentKey {
    static let defaultValue: Window? = nil
}

// 2. Extend the environment with our property
extension EnvironmentValues {
  public var window: Window? {
    get { self[WindowKey.self] }
    set { self[WindowKey.self] = newValue }
  }
}

struct WindowViewModifier: ViewModifier {
    @State private var window: Window?
    
    func body(content: Content) -> some View {
        content
            .bindWindow($window)
            .environment(\.window, window)
    }
}

// 3. Optional convenience view modifier
extension View {
  public func injectWindow() -> some View {
      modifier(WindowViewModifier())
  }
}
#endif
