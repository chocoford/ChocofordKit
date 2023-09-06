//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/9/6.
//

#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI

public extension NSEvent.ModifierFlags {
    var eventModifiers: SwiftUI.EventModifiers {
        var modifiers: SwiftUI.EventModifiers = []
        
        if self.contains(NSEvent.ModifierFlags.command) {
            modifiers.update(with: EventModifiers.command)
        }
        
        if self.contains(NSEvent.ModifierFlags.control) {
            modifiers.update(with: EventModifiers.control)
        }
        
        if self.contains(NSEvent.ModifierFlags.option) {
            modifiers.update(with: EventModifiers.option)
        }
        
        if self.contains(NSEvent.ModifierFlags.shift) {
            modifiers.update(with: EventModifiers.shift)
        }
        
        if self.contains(NSEvent.ModifierFlags.capsLock) {
            modifiers.update(with: EventModifiers.capsLock)
        }
        
        if self.contains(NSEvent.ModifierFlags.numericPad) {
            modifiers.update(with: EventModifiers.numericPad)
        }
        
        return modifiers
    }
}
#endif
