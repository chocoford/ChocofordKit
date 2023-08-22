//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/8/23.
//

#if canImport(AppKit)
import AppKit
public func activateApp() {
    if #available(macOS 14.0, *) {
        NSApp.activate()
    } else {
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
