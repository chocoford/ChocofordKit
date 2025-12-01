//
//  View+Window.swift
//
//
//  Created by Dove Zachary on 2023/8/22.
//

import SwiftUI
#if canImport(SwiftUI)

struct WindowWillCloseModifier: ViewModifier {
    @Environment(\.window) private var window
    
    var action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { output in
                if let window = output.object as? NSWindow, window == self.window {
                    action()
                }
            }
    }
}

extension View {
    @MainActor @ViewBuilder
    public func onWindowWillClose(_ action: @escaping () -> Void) -> some View {
        modifier(WindowWillCloseModifier(action: action))
    }
}

#endif
