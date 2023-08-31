//
//  NSScreen+Extension.swift
//  
//
//  Created by Dove Zachary on 2023/8/31.
//

#if canImport(AppKit)
import AppKit

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
}
#endif
