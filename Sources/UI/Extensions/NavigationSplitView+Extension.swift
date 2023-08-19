//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/8/20.
//

import SwiftUI

/// Copied and modified from [Swiftcord](https://github.com/SwiftcordApp/Swiftcord)
@available(macOS 13.0, iOS 16.0, *)
extension NavigationSplitView {
    public func removeSidebarToggle(windowModifier: @escaping (NSWindow) -> Void = { _ in }) -> some View {
        modifier(RemoveSidebarToggleModifier(windowModifier: windowModifier))
    }
}

private struct RemoveSidebarToggleModifier: ViewModifier {
    let windowModifier: (NSWindow) -> Void

    func body(content: Content) -> some View {
        content.task {
            guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "com_apple_SwiftUI_Settings_window" }) else { return }
            windowModifier(window)
            let sidebaritem = "com.apple.SwiftUI.navigationSplitView.toggleSidebar"
            if let index = window.toolbar?.items.firstIndex(where: { $0.itemIdentifier.rawValue == sidebaritem }) {
                window.toolbar?.removeItem(at: index)
            }
        }
    }
}

