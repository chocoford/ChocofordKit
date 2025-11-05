//
//  TextFieldKeyDownHandler.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 4/3/25.
//

import SwiftUI
#if canImport(AppKit)
public struct TextFieldKeyDownEventHandler {
    public static func selection(_ selection: Binding<Int?>, maxIndex: Int) -> TextFieldKeyDownEventHandler {
        TextFieldKeyDownEventHandler { event in
            if event.keyCode == 125 { // arrow down
                selection.wrappedValue = max(0, min(maxIndex, (selection.wrappedValue ?? -1) + 1))
            } else if event.keyCode == 126 { // arrow up
                if selection.wrappedValue == 0 {
                    selection.wrappedValue = nil
                } else if let s = selection.wrappedValue {
                    selection.wrappedValue = max(s - 1, 0)
                }
            }
            
            return event
        }
    }
    public static func enter(
        with specialKey: NSEvent.ModifierFlags? = nil,
        action: @escaping () -> Void
    ) -> TextFieldKeyDownEventHandler {
        TextFieldKeyDownEventHandler { event in
            if event.keyCode == 36 {
                if let specialKey, event.modifierFlags.contains(specialKey) {
                    action()
                } else if specialKey == nil {
                    action()
                }
            }
            return event
        }
    }
    public static func escape(
        with specialKey: NSEvent.ModifierFlags? = nil,
        action: @escaping () -> Void
    ) -> TextFieldKeyDownEventHandler {
        TextFieldKeyDownEventHandler { event in
            if event.keyCode == 53 {
                if let specialKey, event.modifierFlags.contains(specialKey) {
                    action()
                } else if specialKey == nil {
                    action()
                }
            }
            return event
        }
    }
     
    public init(_ action: @escaping (_ event: NSEvent) -> NSEvent) {
        self.actions = [action]
    }
    
    private init(actions: [(_ event: NSEvent) -> NSEvent]) {
        self.actions = actions
    }
    
    var actions: [(_ event: NSEvent) -> NSEvent]
    
    public func callAsFunction(_ event: NSEvent) -> NSEvent {
        var resultEvent = event
        for action in actions {
            resultEvent = action(resultEvent)
        }
        return resultEvent
    }
    
    public mutating func append(action: @escaping (_ event: NSEvent) -> NSEvent) {
        self.actions.append(action)
    }
    
    public func combine(with action: @escaping (_ event: NSEvent) -> NSEvent) -> Self {
        TextFieldKeyDownEventHandler(actions: self.actions + [action])
    }
    
    public mutating func append(handler: TextFieldKeyDownEventHandler) {
        self.actions.append(contentsOf: handler.actions)
    }
    
    public func combine(with handler: TextFieldKeyDownEventHandler) -> Self {
        TextFieldKeyDownEventHandler(actions: self.actions + handler.actions)
    }
}

struct TextFieldKeyDownEventMonitorModifier: ViewModifier {
    var handler: TextFieldKeyDownEventHandler
    var isEnabled: Bool
    
    init(handler: TextFieldKeyDownEventHandler, isEnabled: Bool = true) {
        self.handler = handler
        self.isEnabled = isEnabled
    }
    
    @FocusState var isFocused: Bool
    @State private var window: NSWindow?
    @State private var keydownListener: Any?

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .bindWindow($window)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if let window = notification.object as? NSWindow, window == self.window {
                    removeKeyDownListener()
                }
            }
            .onChange(of: isFocused) { newValue in
                if newValue, isEnabled {
                    addKeyDownListener()
                } else {
                    removeKeyDownListener()
                }
            }
            .onChange(of: isEnabled) { newValue in
                if newValue {
                    addKeyDownListener()
                } else {
                    removeKeyDownListener()
                }
            }
    }
    
    private func addKeyDownListener() {
        keydownListener = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isFocused else { return event }
            return self.handler(event)
        }
    }
    
    private func removeKeyDownListener() {
        if let keydownListener {
            NSEvent.removeMonitor(keydownListener)
        }
    }
}

extension View {
    @MainActor @ViewBuilder
    public func keyDownHandler(_ handler: TextFieldKeyDownEventHandler, isEnabled: Bool = true) -> some View {
        modifier(TextFieldKeyDownEventMonitorModifier(handler: handler))
    }
}
#endif
