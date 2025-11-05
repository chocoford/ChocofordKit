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
        TextFieldKeyDownEventHandler(triggers: [(125, nil), (126, nil)]) { event in
            guard let event else { return nil }
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
        custom(key: .enter, with: specialKey, action: action)
    }
    public static func escape(
        with specialKey: NSEvent.ModifierFlags? = nil,
        action: @escaping () -> Void
    ) -> TextFieldKeyDownEventHandler {
        custom(key: .escape, with: specialKey, action: action)
    }
    
    public static func custom(
        key: Key,
        with specialKey: NSEvent.ModifierFlags? = nil,
        action: @escaping () -> Void
    ) -> TextFieldKeyDownEventHandler {
        custom(keyCode: key.rawValue, with: specialKey, action: action)
    }
    public static func custom(
        keyCode: UInt16,
        with specialKey: NSEvent.ModifierFlags? = nil,
        action: @escaping () -> Void
    ) -> TextFieldKeyDownEventHandler {
        TextFieldKeyDownEventHandler(triggers: [(keyCode, specialKey)]) { event in
            guard let event else { return nil }
            if event.keyCode == keyCode {
                if let specialKey, event.modifierFlags.contains(specialKey) {
                    action()
                } else if specialKey == nil {
                    action()
                }
            }
            return event
        }
    }
     
    public init(triggers: [(UInt16, NSEvent.ModifierFlags?)] = [], _ action: @escaping (_ event: NSEvent?) -> NSEvent?) {
        self.triggers = triggers
        self.actions = [action]
    }
    
    private init(triggers: [(UInt16, NSEvent.ModifierFlags?)], actions: [(_ event: NSEvent?) -> NSEvent?]) {
        self.triggers = triggers
        self.actions = actions
    }
    
    var triggers: [(UInt16, NSEvent.ModifierFlags?)] = []
    var actions: [(_ event: NSEvent?) -> NSEvent?]
    
    public func callAsFunction(_ event: NSEvent?) -> NSEvent? {
        var resultEvent = event
        print("KeyDown handler triggered: \(String(describing: resultEvent))", terminator: "\n⬇️\n")
        for action in actions {
            resultEvent = action(resultEvent)
            print(String(describing: resultEvent), terminator: "\n⬇️\n")
        }
        return resultEvent
    }
    
    
    /// A handler that stops further processing of the key down event.
    public func stop(
        triggers: [(UInt16, NSEvent.ModifierFlags?)]? = [],
    ) -> TextFieldKeyDownEventHandler {
        print("KeyDown handler stop called with triggers: \(String(describing: triggers))")
        return TextFieldKeyDownEventHandler(
            triggers: self.triggers,
            actions: self.actions + [
                { event in
                    guard let event else { return nil }
                    if let triggers {
                        if triggers.isEmpty {
                            for trigger in triggers {
                                let (keyCode, specialKey) = trigger
                                if event.keyCode == keyCode {
                                    if let specialKey, event.modifierFlags.contains(specialKey) {
                                        return nil
                                    } else if specialKey == nil {
                                        return nil
                                    }
                                }
                            }
                        } else {
                            return nil
                        }
                    }
                    return event
                }
            ]
        )
        
    }
    
    
    public mutating func append(
        trigger: (UInt16, NSEvent.ModifierFlags?)? = nil,
        action: @escaping (_ event: NSEvent?) -> NSEvent?
    ) {
        if let trigger {
            self.triggers.append(trigger)
        }
        self.actions.append(action)
    }
    
    public func combine(
        trigger: (UInt16, NSEvent.ModifierFlags?)? = nil,
        with action: @escaping (_ event: NSEvent?) -> NSEvent?
    ) -> Self {
        TextFieldKeyDownEventHandler(
            triggers: trigger != nil ? [trigger!] : [],
            actions: self.actions + [action]
        )
    }
    
    public mutating func append(handler: TextFieldKeyDownEventHandler) {
        self.triggers.append(contentsOf: handler.triggers)
        self.actions.append(contentsOf: handler.actions)
    }
    
    public func combine(with handler: TextFieldKeyDownEventHandler) -> Self {
        TextFieldKeyDownEventHandler(
            triggers: self.triggers + handler.triggers,
            actions: self.actions + handler.actions
        )
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

extension TextFieldKeyDownEventHandler {
    public enum Key: UInt16 {
        case a = 0
        case s = 1
        case d = 2
        case f = 3
        case h = 4
        case g = 5
        case z = 6
        case x = 7
        case c = 8
        case v = 9
        case b = 11
        case q = 12
        case w = 13
        case e = 14
        case r = 15
        case y = 16
        case t = 17
        case one = 18
        case two = 19
        case three = 20
        case four = 21
        case six = 22
        case five = 23
        case equal = 24
        case nine = 25
        case seven = 26
        case minus = 27
        case eight = 28
        case zero = 29
        case rightBracket = 30
        case o = 31
        case u = 32
        case leftBracket = 33
        case i = 34
        case p = 35
        case l = 37
        case j = 38
        case quote = 39
        case k = 40
        case semicolon = 41
        case backslash = 42
        case comma = 43
        case slash = 44
        case n = 45
        case m = 46
        case period = 47
        case grave = 50

        case keypadDecimal = 65
        case keypadMultiply = 67
        case keypadPlus = 69
        case keypadClear = 71
        case keypadDivide = 75
        case keypadEnter = 76
        case keypadMinus = 78
        case keypadEquals = 81
        case keypad0 = 82
        case keypad1 = 83
        case keypad2 = 84
        case keypad3 = 85
        case keypad4 = 86
        case keypad5 = 87
        case keypad6 = 88
        case keypad7 = 89
        case keypad8 = 91
        case keypad9 = 92

        case enter = 36
        case tab = 48
        case space = 49
        case delete = 51
        case escape = 53
        case command = 55
        case shift = 56
        case capsLock = 57
        case option = 58
        case control = 59
        case rightShift = 60
        case rightOption = 61
        case rightControl = 62
        case function = 63
        case f17 = 64
        case volumeUp = 72
        case volumeDown = 73
        case mute = 74
        case f18 = 79
        case f19 = 80
        case f20 = 90
        case f5 = 96
        case f6 = 97
        case f7 = 98
        case f3 = 99
        case f8 = 100
        case f9 = 101
        case f11 = 103
        case f13 = 105
        case f16 = 106
        case f14 = 107
        case f10 = 109
        case f12 = 111
        case f15 = 113
        case help = 114
        case home = 115
        case pageUp = 116
        case forwardDelete = 117
        case f4 = 118
        case end = 119
        case f2 = 120
        case pageDown = 121
        case f1 = 122
        case leftArrow = 123
        case rightArrow = 124
        case downArrow = 125
        case upArrow = 126
    }
}
#endif

