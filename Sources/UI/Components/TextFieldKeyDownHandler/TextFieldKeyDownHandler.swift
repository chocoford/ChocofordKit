//
//  TextFieldKeyDownHandler.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 4/3/25.
//

import SwiftUI
#if canImport(AppKit)
public struct TextFieldKeyDownEventHandler: Equatable {
    public static func == (lhs: TextFieldKeyDownEventHandler, rhs: TextFieldKeyDownEventHandler) -> Bool {
        
        let lhsTriggersDescription: String = lhs.triggers.map { trigger in
            let (keyCode, specialKey) = trigger
            return String(describing: keyCode) + "-" + "\(specialKey?.rawValue ?? 0)"
        }.joined(separator: "") + lhs.equatableKeys.joined(separator: ",")
        let rhsTriggersDescription: String = rhs.triggers.map { trigger in
            let (keyCode, specialKey) = trigger
            return String(describing: keyCode) + "-" + "\(specialKey?.rawValue ?? 0)"
        }.joined(separator: "") + rhs.equatableKeys.joined(separator: ",")
        
        
        return lhsTriggersDescription == rhsTriggersDescription &&
        lhs.actions.count == rhs.actions.count
    }
    
    public static func selection(
        _ selection: Binding<Int?>,
        maxIndex: @autoclosure @escaping () -> Int
    ) -> TextFieldKeyDownEventHandler {
        TextFieldKeyDownEventHandler(triggers: [(125, nil), (126, nil)], equatableKeys: []) { event in
            guard let event else { return nil }
            if event.keyCode == 125 { // arrow down
                selection.wrappedValue = max(0, min(maxIndex(), (selection.wrappedValue ?? -1) + 1))
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
    
    var triggers: [(UInt16, NSEvent.ModifierFlags?)] = []
    var actions: [(_ event: NSEvent?) -> NSEvent?]
    var equatableKeys: [String] = []
    
    public init(
        triggers: [(UInt16, NSEvent.ModifierFlags?)] = [],
        equatableKeys: [String] = [],
        _ action: @escaping (_ event: NSEvent?) -> NSEvent?
    ) {
        self.triggers = triggers
        self.equatableKeys = equatableKeys
        self.actions = [action]
    }
    
    private init(
        triggers: [(UInt16, NSEvent.ModifierFlags?)],
        equatableKeys: [String] = [],
        actions: [(_ event: NSEvent?) -> NSEvent?]
    ) {
        self.triggers = triggers
        self.equatableKeys = equatableKeys
        self.actions = actions
    }


    /// A handler that stops further processing of the key down event.
    public func stop(
        triggers: [(UInt16, NSEvent.ModifierFlags?)]? = [],
    ) -> TextFieldKeyDownEventHandler {
        let triggers = triggers?.isEmpty == true ? self.triggers : triggers
        
        // print("KeyDown handler stop called with triggers: \(String(describing: triggers))")
        return TextFieldKeyDownEventHandler(
            triggers: triggers ?? [],
            equatableKeys: self.equatableKeys,
            actions: self.actions + [
                { event in
                    guard let event else { return nil }
                    if let triggers {
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
                    }
                    return event
                }
            ],
        )
    }
    
    
    public mutating func append(
        trigger: (UInt16, NSEvent.ModifierFlags?)? = nil,
        equitableKey: String? = nil,
        action: @escaping (_ event: NSEvent?) -> NSEvent?
    ) {
        if let trigger {
            self.triggers.append(trigger)
        }
        if let equitableKey {
            self.equatableKeys.append(equitableKey)
        }
        self.actions.append(action)
    }
    
    public func combine(
        trigger: (UInt16, NSEvent.ModifierFlags?)? = nil,
        equitableKey: String? = nil,
        with action: @escaping (_ event: NSEvent?) -> NSEvent?
    ) -> Self {
        TextFieldKeyDownEventHandler(
            triggers: self.triggers + (trigger != nil ? [trigger!] : []),
            equatableKeys: self.equatableKeys + (equitableKey != nil ? [equitableKey!] : []),
            actions: self.actions + [action]
        )
    }
    
    public mutating func append(handler: TextFieldKeyDownEventHandler) {
        self.triggers.append(contentsOf: handler.triggers)
        self.equatableKeys.append(contentsOf: handler.equatableKeys)
        self.actions.append(contentsOf: handler.actions)
    }
    
    public func combine(with handler: TextFieldKeyDownEventHandler) -> Self {
        TextFieldKeyDownEventHandler(
            triggers: self.triggers + handler.triggers,
            equatableKeys: self.equatableKeys + handler.equatableKeys,
            actions: self.actions + handler.actions
        )
    }
    
    public func callAsFunction(_ event: NSEvent?, log: Bool = false) -> NSEvent? {
        var resultEvent = event
        if log {
            print("KeyDown handler triggered: \(String(describing: resultEvent))", terminator: "\n⬇️\n")
        }
        for (i, action) in actions.enumerated() {
            resultEvent = action(resultEvent)
            if log {
                print(String(describing: resultEvent))
                if i < actions.endIndex - 1 {
                    print("⬇️")
                } else {
                    print("\n")
                }
            }
        }
        return resultEvent
    }

    
}

struct TextFieldKeyDownEventMonitorModifier: ViewModifier {
    @Environment(\.isPresented) private var isPresented
    
    var handler: TextFieldKeyDownEventHandler
    var isEnabled: Bool
    var log: Bool = false
    
    init(handler: TextFieldKeyDownEventHandler, isEnabled: Bool = true, log: Bool = false) {
        self.handler = handler
        self.isEnabled = isEnabled
        self.log = log
    }
    
    @FocusState var isFocused: Bool
    @State private var window: NSWindow?
    @State private var keydownListener: Any?
    @State private var isAppeared = false

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .bindWindow($window)
            .onWindowWillClose { isAppeared = false }
            .onChange(of: handler) { newValue in
                guard isPresented, isAppeared else { return }
                DispatchQueue.main.async {
                    print("KeyDown handler changed: \(newValue)")
                    addKeyDownListener(handler: newValue)
                }
            }
            .onChange(of: isAppeared) { newValue in
                if !newValue {
                    DispatchQueue.main.async {
                        removeKeyDownListener()
                    }
                }
            }
            .onAppear {
                isAppeared = true
                addKeyDownListener()
            }
            .onDisappear {
                isAppeared = false
            }
    }
    
    private func addKeyDownListener(handler: TextFieldKeyDownEventHandler? = nil) {
        removeKeyDownListener()
        keydownListener = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if log {
                // Seems always cature values...
                print("KeyDown event received: \(event), isFocused: \(isFocused), isEnabled: \(isEnabled)")
            }
            guard isFocused && isEnabled else { return event }
            return (handler ?? self.handler)(event, log: log)
        }
    }
    
    private func removeKeyDownListener() {
        if let keydownListener {
            NSEvent.removeMonitor(keydownListener)
        }
    }
}

extension View {
    /// Invoke only one handler per view.
    @MainActor @ViewBuilder
    public func keyDownHandler(
        _ handler: TextFieldKeyDownEventHandler,
        isEnabled: Bool = true,
        log: Bool = false
    ) -> some View {
        modifier(TextFieldKeyDownEventMonitorModifier(handler: handler, isEnabled: isEnabled, log: log))
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

