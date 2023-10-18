//
//  NSApp+Extension.swift
//
//
//  Created by Dove Zachary on 2023/10/18.
//

#if canImport(AppKit)
import AppKit

extension NSApplication {
    /// Set active policy to accessory if there is no valid window on screen.
    ///
    /// valid means has window  identifer, `canBecomeKey` == `true` and is visible.
    public func setAccessoryPolicyIfNecessary() {
        if NSApp.windows.filter({ $0.identifier != nil && $0.canBecomeKey && $0.isVisible }).isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

#endif

