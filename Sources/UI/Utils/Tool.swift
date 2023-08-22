//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/20.
//


#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif


public func resignAllFirstResponder() {
#if canImport(UIKit)
    UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil);
#endif
}

public func togglePreferenceView() {
#if canImport(AppKit)
    if #available(macOS 13, *) {
      NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
      NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
    activateApp()
#endif
}


public func openNotificationSettings() {
#if os(iOS)
    if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
        UIApplication.shared.open(appSettings)
    }
#elseif os(macOS)
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
    NSWorkspace.shared.open(url)
#endif
}

public func openSecuritySettings() {
#if os(iOS)
    if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
        UIApplication.shared.open(appSettings)
    }
#elseif os(macOS)
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
    NSWorkspace.shared.open(url)
#endif
}


public func activateApp() {
#if canImport(AppKit)
    if #available(macOS 14.0, *) {
//        NSApp.activate()
    } else {
        NSApp.activate(ignoringOtherApps: true)
    }
#endif
}
