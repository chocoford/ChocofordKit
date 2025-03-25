//
//  OnChange+Extension.swift
//
//
//  Created by Dove Zachary on 2024/1/9.
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

struct DebounceOnChangeModifier<V: Equatable>: ViewModifier {
    var value: V
    var initial: Bool = false
    var interval: TimeInterval
    var action: (_ oldVal: V, _ newVal: V) -> Void
    
    @available(macOS 14.0, iOS 17.0, *)
    public init(
        value: V,
        initial: Bool,
        interval: TimeInterval,
        action: @escaping (_ oldVal: V, _ newVal: V) -> Void
    ) {
        self.value = value
        self.initial = initial
        self.action = action
        self.interval = interval
    }
    
    @available(macOS 11.0, iOS 13.0, *)
    public init(
        value: V,
        initial: Bool,
        interval: TimeInterval,
        action: @escaping (_ newVal: V) -> Void
    ) {
        self.value = value
        self.initial = initial
        self.action = { _, val in
            action(val)
        }
        self.interval = interval
    }
    
    @State private var passthroughSubject = PassthroughSubject<(V, V), Never>()
    
    func body(content: Content) -> some View {
        Group {
            if #available(macOS 14.0, iOS 17.0, *) {
                content
                    .onChange(of: value, initial: initial) { oldValue, newValue in
                        passthroughSubject.send((oldValue, newValue))
                    }
            } else {
                content
                    .onChange(of: value) { newValue in
                        passthroughSubject.send((newValue, newValue))
                    }
                    .onAppear {
                        if initial {
                            passthroughSubject.send((value, value))
                        }
                    }
            }
        }
        .onReceive(passthroughSubject.debounce(for: .nanoseconds(Int(interval * 1e+9)), scheduler: RunLoop.current)) { output in
            self.action(output.0, output.1)
        }
    }
}

struct ThrottleOnChangeModifier<V: Equatable>: ViewModifier {
    var value: V
    var initial: Bool = false
    var interval: TimeInterval
    var latest: Bool
    var action: (_ oldVal: V, _ newVal: V) -> Void
    
    @available(macOS 14.0, iOS 17.0, *)
    public init(
        value: V,
        initial: Bool,
        interval: TimeInterval,
        latest: Bool,
        action: @escaping (_ oldVal: V, _ newVal: V) -> Void
    ) {
        self.value = value
        self.initial = initial
        self.action = action
        self.latest = latest
        self.interval = interval
    }
    
    @available(macOS, deprecated: 14.0)
    @available(iOS, deprecated: 17.0)
    @available(visionOS, deprecated: 1.0)
    public init(
        value: V,
        initial: Bool,
        interval: TimeInterval,
        latest: Bool,
        action: @escaping (_ newVal: V) -> Void
    ) {
        self.value = value
        self.initial = initial
        self.action = { _, val in
            action(val)
        }
        self.interval = interval
        self.latest = latest
    }
    
    @State private var passthroughSubject = PassthroughSubject<(V, V), Never>()
    
    func body(content: Content) -> some View {
        Group {
            if #available(macOS 14.0, iOS 17.0, *) {
                content
                    .onChange(of: value, initial: initial) { oldValue, newValue in
                        passthroughSubject.send((oldValue, newValue))
                    }
            } else {
                content
                    .onChange(of: value) { newValue in
                        passthroughSubject.send((newValue, newValue))
                    }
            }
        }
        .onReceive(
            passthroughSubject.throttle(
                for: .nanoseconds(Int(interval * 1e+9)),
                scheduler: RunLoop.current,
                latest: latest
            )
        ) { output in
            if #available(macOS 14.0, iOS 17.0, *) {
                self.action(output.0, output.1)
            } else {
                self.action(output.0, output.1)
            }
        }
    }
}


extension View {
    // MARK: - Debounce
    
    @available(macOS 14.0, iOS 17.0, *)
    @ViewBuilder
    public func onChange<V: Equatable>(
        of value: V, 
        initial: Bool = false,
        debounce: TimeInterval,
        action: @escaping (_ oldVal: V, _ newVal: V) -> Void
    ) -> some View {
        modifier(DebounceOnChangeModifier(value: value, initial: initial, interval: debounce, action: action))
    }
    
    @ViewBuilder
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        debounce: TimeInterval,
        action: @escaping () -> Void
    ) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            modifier(
                DebounceOnChangeModifier(value: value, initial: initial, interval: debounce) { _, _ in
                    action()
                }
            )
        } else {
            modifier(
                DebounceOnChangeModifier(value: value, initial: initial, interval: debounce) { _ in
                    action()
                }
            )
        }
    }
    
//    @available(macOS, deprecated: 14.0)
//    @available(iOS, deprecated: 17.0)
//    @available(visionOS, deprecated: 1.0)
    @ViewBuilder
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        debounce: TimeInterval,
        action: @escaping (_ newVal: V) -> Void
    ) -> some View {
        modifier(
            DebounceOnChangeModifier(
                value: value,
                initial: initial,
                interval: debounce,
                action: action
            )
        )
    }
    
    // MARK: - Throttle
    
    @available(macOS 14.0, iOS 17.0, *)
    @ViewBuilder
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        throttle: TimeInterval,
        latest: Bool,
        action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> some View {
        modifier(ThrottleOnChangeModifier(value: value, initial: initial, interval: throttle, latest: latest, action: action))
    }
    
    @ViewBuilder
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        throttle: TimeInterval,
        latest: Bool,
        action: @escaping () -> Void
    ) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            modifier(
                ThrottleOnChangeModifier(value: value, initial: initial, interval: throttle, latest: latest) { _, _ in
                    action()
                }
            )
        } else {
            modifier(
                ThrottleOnChangeModifier(value: value, initial: initial, interval: throttle, latest: latest) { _ in
                    action()
                }
            )
        }
    }
    
    @available(macOS, deprecated: 14.0)
    @available(iOS, deprecated: 17.0)
    @available(visionOS, deprecated: 1.0)
    @ViewBuilder
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        throttle: TimeInterval,
        latest: Bool,
        action: @escaping (_ newVal: V) -> Void
    ) -> some View {
        modifier(
            ThrottleOnChangeModifier(value: value, initial: initial, interval: throttle, latest: latest, action: action)
        )
    }
}

#endif
