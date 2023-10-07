//
//  SettingsButton.swift
//
//
//  Created by Dove Zachary on 2023/10/7.
//

#if canImport(SwiftUI)
import SwiftUI

public struct SettingsButton<Label: View>: View {
    
    var label: () -> Label
    
    public init(@ViewBuilder label: @escaping () -> Label) {
        self.label = label
    }
    
    public var body: some View {
        if #available(macOS 14.0, *) {
            SettingsLink(label: label)
        } else if #available(macOS 10.15, *) {
            Button(action: togglePreferenceView, label: label)
        }
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
