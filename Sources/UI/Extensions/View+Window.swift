//
//  View+Window.swift
//
//
//  Created by Dove Zachary on 2023/8/22.
//

import SwiftUI
#if os(macOS)
/// Auto set `ActivationPolicy` for `UIElement` App..
/// When the view's window is opened, app will be `.regular`.
/// And when the last window is closed, the app will be `.accessory`
@available(macOS 10.15, *)
struct AutoActivationPolicyModifer: ViewModifier {
    @State private var window: NSWindow? = nil
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                NSApp.setActivationPolicy(.regular)
                activateApp()
                self.window?.makeKeyAndOrderFront(nil)
            }
            .introspect(.window, on: .macOS(.v14, .v13, .v12, .v11, .v10_15)) { window in
                DispatchQueue.main.async {
                    self.window = window
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { output in
                guard let window = output.object as? NSWindow else { return }
                if window == self.window {
                    NSApp.setActivationPolicy(.regular)
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: NSWindow.willCloseNotification,
                    object: window
                )
            ) { _ in
                DispatchQueue.main.async {
                    if NSApp.windows.filter({ $0.identifier != nil && $0.canBecomeKey && $0.isVisible }).isEmpty {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
            }
    }
}
#endif

public enum FakeNSWindowAnimationBehavior {
    case `default`
    case none, documentWindow, utilityWindow, alertPanel
}

extension View {
    @available(macOS 10.15, *)
    @ViewBuilder
    public func autoActivationPolicy() -> some View {
        self
#if os(macOS)
            .modifier(AutoActivationPolicyModifer())
#endif
    }
    
    
#if os(macOS)
    @available(macOS 10.15, *)
    @ViewBuilder
    public func windowAnimationBehavior(_ behavior: NSWindow.AnimationBehavior) -> some View {
        introspect(.window, on: .macOS(.v14, .v13, .v12, .v11, .v10_15)) { window in
            window.animationBehavior = behavior
        }
    }
#elseif os(iOS)
    public func windowAnimationBehavior(_ behavior: FakeNSWindowAnimationBehavior) -> some View {
        self
    }
#endif
    
#if os(macOS)
    @ViewBuilder
    public func window(perform action: @escaping (NSWindow) -> Void) -> some View {
        introspect(.window, on: .macOS(.v14, .v13, .v12, .v11, .v10_15)) { window in
            action(window)
        }
    }
    
    @ViewBuilder
    public func bindWindow(_ windowBinding: Binding<NSWindow?>) -> some View {
        introspect(.window, on: .macOS(.v14, .v13, .v12, .v11, .v10_15)) { window in
            DispatchQueue.main.async {
                windowBinding.wrappedValue = window
            }
        }
    }
#endif
}



