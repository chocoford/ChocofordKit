//
//  NSScreen+Extension.swift
//
//
//  Created by Dove Zachary on 2023/8/31.
//

#if canImport(AppKit)
import AppKit

extension NSScreen {
    public var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
    
    /// Get the screen according to mosue position
    public static var current: NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
        return screenWithMouse
    }
}
#endif
