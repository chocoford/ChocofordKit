//
//  View+Window.swift
//
//
//  Created by Dove Zachary on 2023/8/22.
//

#if canImport(SwiftUI)
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
                activateApp()
                self.window?.makeKeyAndOrderFront(nil)
            }
            .introspect(.window, on: .macOS(.v26, .v15, .v14, .v13, .v12, .v11, .v10_15)) { window in
                DispatchQueue.main.async {
                    self.window = window
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { output in
                guard let window = output.object as? NSWindow else { return }
                DispatchQueue.main.async {
                    if window == self.window {
                        NSApp.setActivationPolicy(.regular)
                    }
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
    @MainActor @ViewBuilder
    public func autoActivationPolicy() -> some View {
        self
#if os(macOS)
            .modifier(AutoActivationPolicyModifer())
#endif
    }
    
    
#if os(macOS)
    @available(macOS 10.15, *)
    @MainActor @ViewBuilder
    public func windowAnimationBehavior(_ behavior: NSWindow.AnimationBehavior) -> some View {
        introspect(.window, on: .macOS(.v26, .v15, .v14, .v13, .v12, .v11, .v10_15)) { window in
            window.animationBehavior = behavior
        }
    }
#elseif os(iOS)
    public func windowAnimationBehavior(_ behavior: FakeNSWindowAnimationBehavior) -> some View {
        self
    }
#endif
    
#if os(macOS)
    @MainActor @ViewBuilder
    public func window(perform action: @escaping (NSWindow) -> Void) -> some View {
        introspect(.window, on: .macOS(.v26, .v15, .v14, .v13, .v12, .v11, .v10_15)) { window in
            action(window)
        }
    }
    
    @MainActor @ViewBuilder
    public func bindWindow(_ windowBinding: Binding<NSWindow?>) -> some View {
        introspect(.window, on: .macOS(.v26, .v15, .v14, .v13, .v12, .v11, .v10_15)) { window in
            if windowBinding.wrappedValue != window {
                DispatchQueue.main.async {
                    windowBinding.wrappedValue = window
                }
            }
        }
    }
#elseif os(iOS)
    @MainActor @ViewBuilder
    public func window(perform action: @escaping (UIWindow) -> Void) -> some View {
        introspect(.window, on: .iOS(.v26, .v13, .v14, .v15, .v16, .v17, .v18)) { window in
            action(window)
        }
    }
    
    @MainActor @ViewBuilder
    public func bindWindow(_ windowBinding: Binding<UIWindow?>) -> some View {
        introspect(.window, on: .iOS(.v26, .v13, .v14, .v15, .v16, .v17, .v18)) { window in
            DispatchQueue.main.async {
                windowBinding.wrappedValue = window
            }
        }
    }
#endif
}



#endif
