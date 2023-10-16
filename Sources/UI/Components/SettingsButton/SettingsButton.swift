//
//  SettingsButton.swift
//
//
//  Created by Dove Zachary on 2023/10/7.
//

#if canImport(SwiftUI) && os(macOS)
import SwiftUI

public struct SettingsButton<Label: View>: View {
    
    var useDefaultLabel: Bool
    var action: () -> Void
    var label: () -> Label
    
    /// Create a Settings Button
    /// - Parameters:
    ///   - useDefaultLabel: Tell `SettingsLink` to use default label. This parameter will be ignore before macOS Sonoma
    ///   - followingAction: Perform action when button appear
    ///   - label: The label of Settings button
    public init(
        useDefaultLabel: Bool = false,
        followingAction: @escaping () -> Void = {},
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.useDefaultLabel = useDefaultLabel
        self.action = followingAction
        self.label = label
    }
    
    public var body: some View {
        Group {
            if #available(macOS 14.0, *) {
                if useDefaultLabel {
                    SettingsLink()
                } else {
                    SettingsLink(label: label)
                }
            } else if #available(macOS 10.15, *) {
                Button(action: togglePreferenceView, label: label)
            }
        }
        .onAppear(perform: action)
    }
    
    public func togglePreferenceView() {
    #if canImport(AppKit)
        if #available(macOS 14, *) {
            
        } else if #available(macOS 13, *) {
          NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
          NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        activateApp()
    #endif
    }
}
#endif
