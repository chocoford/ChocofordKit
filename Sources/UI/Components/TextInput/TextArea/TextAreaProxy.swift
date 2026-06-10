//
//  TextAreaProxy.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2026/05/06.
//

import SwiftUI

// MARK: - Proxy

/// A handle that lets callers drive a `TextArea` imperatively from outside —
/// e.g. opening a trigger menu in response to a button tap.
///
/// Obtain a proxy by wrapping the `TextArea` in a ``TextAreaReader``:
///
/// ```swift
/// TextAreaReader { proxy in
///     TextArea(text: $text, placeholder: Text("…"))
///         .trigger(MenuTrigger("@", …))
///
///     Button("Mention") {
///         proxy.openMenu(for: "@")
///     }
/// }
/// ```
//@available(macOS 14.0, iOS 17.0, *)
public final class TextAreaProxy: ObservableObject {
    weak var controller: TextAreaController?

    public init() {}

    /// Open the menu registered for `character` programmatically.
    ///
    /// The character is inserted at the current caret position (mimicking
    /// the user typing it), then the trigger's menu is opened. Boundary
    /// checks (whitespace before the character) are skipped, so this works
    /// mid-word.
    ///
    /// If no trigger is registered for `character`, the character is still
    /// inserted but no menu opens.
    @MainActor
    public func openMenu(for character: Character) {
        controller?.programmaticOpenTrigger(character)
    }

    /// Dismiss any currently open trigger menu without modifying the editor.
    @MainActor
    public func dismissMenu() {
        controller?.dismiss()
    }

    /// Resign focus from the underlying platform text view.
    ///
    /// Useful when a surrounding scroll view wants keyboard-dismiss behavior:
    /// the scroll view can call this proxy instead of relying on global
    /// responder-chain actions that may miss custom UIKit/AppKit wrappers.
    @MainActor
    public func dismissKeyboard() {
        controller?.dismissKeyboard()
    }
}

public extension View {
    /// Supplies an externally-owned proxy to descendant ``TextArea`` views.
    ///
    /// `TextAreaReader` is still the convenient local form. Use this modifier
    /// when a sibling view, such as an enclosing scroll view, needs to drive
    /// the text area's focus state.
    @MainActor
    func textAreaProxy(_ proxy: TextAreaProxy) -> some View {
        environment(\.textAreaProxy, proxy)
    }
}

// MARK: - Reader

/// A view that vends a ``TextAreaProxy`` to its content, similar in spirit to
/// `ScrollViewReader` / `ScrollViewProxy`.
///
/// Place a ``TextArea`` inside the closure to make it controllable through
/// the proxy.
public struct TextAreaReader<Content: View>: View {
    @StateObject private var proxy = TextAreaProxy()
    let content: (TextAreaProxy) -> Content

    public init(@ViewBuilder content: @escaping (TextAreaProxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(proxy)
            .environment(\.textAreaProxy, proxy)
    }
}

// MARK: - Environment

//@available(macOS 14.0, iOS 17.0, *)
private struct TextAreaProxyKey: EnvironmentKey {
    static let defaultValue: TextAreaProxy? = nil
}

extension EnvironmentValues {
//    @available(macOS 14.0, iOS 17.0, *)
    var textAreaProxy: TextAreaProxy? {
        get { self[TextAreaProxyKey.self] }
        set { self[TextAreaProxyKey.self] = newValue }
    }
}
