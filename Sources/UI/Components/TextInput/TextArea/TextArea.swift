//
//  TextArea.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2026/05/06.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// A multi-line text input that grows with its content, with first-class
/// support for trigger menus, atomic tokens, and custom paste handling.
///
/// `TextArea` wraps an `NSTextView` (macOS) or `UITextView` (iOS) under
/// SwiftUI. It grows vertically as the user types, up to ``maxHeight(_:)``,
/// after which it scrolls internally. The placeholder is hidden correctly
/// during IME composition, so the first character of pinyin / kana
/// composition is never obscured.
///
/// ```swift
/// @State private var text: String = ""
///
/// TextArea(text: $text, placeholder: Text("Say something…"))
///     .maxHeight(160)
///     .background { Color(nsColor: .textBackgroundColor) }
///     .clipShape(RoundedRectangle(cornerRadius: 8))
/// ```
///
/// ## Triggers and atomic tokens
///
/// Register a ``trigger(_:)`` to open a menu when the user types a specific
/// character at a word boundary (`@`, `/`, `:`, …). The selected item is
/// resolved to a ``TextAreaInsertion`` that decides what happens to the
/// trigger range:
///
/// - ``TextAreaInsertion/text(_:)`` — replace with plain text
/// - ``TextAreaInsertion/token(_:)`` — replace with a styled atomic token
///   (rendered inline as an attachment)
/// - ``TextAreaInsertion/action(_:)`` — remove the trigger range and run
///   a closure (slash-command pattern)
/// - ``TextAreaInsertion/submenu(_:)`` — drill into a nested menu
/// - ``TextAreaInsertion/dismiss`` — close the menu, leave the editor
///   untouched
///
/// ```swift
/// TextArea(text: $text, placeholder: Text("Mention someone…"))
///     .trigger(MenuTrigger("@",
///         search: { q in await users.search(q) },
///         resolve: { user in .token(MentionToken(user: user)) }
///     ) { user, highlighted in
///         UserRow(user: user, highlighted: highlighted)
///     })
/// ```
///
/// Inside the menu, **↑** / **↓** navigates, **Return** commits, **Escape**
/// dismisses. Multiple triggers can be registered; if two share the same
/// character, the one registered later wins.
///
/// ## Pasting non-text content
///
/// Use ``onPaste(_:)`` to intercept image / file / URL paste. The handler
/// is called for each pasteboard item; return `nil` to fall back to
/// default behaviour (text inserts as-is, other types are ignored), or a
/// ``TextAreaInsertion`` to take over.
///
/// ```swift
/// TextArea(text: $text, placeholder: Text("Drop an image…"))
///     .onPaste { item in
///         switch item {
///         case .image(let img): return .token(ImageToken(image: img))
///         case .fileURL(let url): return .action { upload(url) }
///         default: return nil
///         }
///     }
/// ```
///
/// ## Submit / newline customization (macOS)
///
/// `TextArea` does not attach a key handler by default — Enter inserts a
/// newline like a normal editor. Use ``keyDownHandler(_:)`` to override
/// (e.g. *Enter* to send, *Shift+Enter* to newline):
///
/// ```swift
/// TextArea(text: $text, placeholder: Text("…"))
///     .keyDownHandler(
///         TextFieldKeyDownEventHandler(triggers: [(36, nil)]) { event in
///             guard let event else { return nil }
///             if event.keyCode == 36, !event.modifierFlags.contains(.shift) {
///                 send()
///                 return nil           // consume plain Enter
///             }
///             return event             // Shift+Enter passes through
///         }
///     )
/// ```
///
/// ## Topics
///
/// ### Creating a TextArea
/// - ``init(text:placeholder:)``
///
/// ### Sizing and styling
/// - ``maxHeight(_:)``
/// - ``background(_:)``
/// - ``clipShape(_:)``
///
/// ### Reacting to layout changes
/// - ``onSingleLineChanged(_:)``
///
/// ### Customizing keyboard input
/// - ``keyDownHandler(_:)``
///
/// ### Adding trigger menus
/// - ``trigger(_:)``
///
/// ### Pasting custom content
/// - ``onPaste(_:)``
public struct TextAreaReturnSubmitSources: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let softwareKeyboard = TextAreaReturnSubmitSources(rawValue: 1 << 0)
    public static let hardwareKeyboard = TextAreaReturnSubmitSources(rawValue: 1 << 1)
    public static let all: TextAreaReturnSubmitSources = [.softwareKeyboard, .hardwareKeyboard]
}

public struct TextArea: View {
    @Binding var inputText: String
    var placeholder: Text

    var config: Config = Config()

    @State private var contentHeight: CGFloat = 0
    @State private var oneLineHeight: CGFloat = 0
    @State private var isComposing: Bool = false
    @StateObject private var controller = TextAreaController()
    @Environment(\.textAreaProxy) private var proxy

    /// Creates a text area bound to a string.
    ///
    /// Tokens inserted via ``trigger(_:)`` or ``onPaste(_:)`` are still
    /// rendered inline as styled attachments, but the binding only sees
    /// each token's `plainText` representation. To preserve token identity
    /// across the binding, use the elements-based initializer (planned).
    ///
    /// - Parameters:
    ///   - text: A binding to the editable string. Updates flow in both
    ///     directions; external mutations that diverge from the editor's
    ///     plain-text view are written back into the editor.
    ///   - placeholder: A view displayed when the editor is empty and no
    ///     IME composition is in progress.
    public init(text: Binding<String>, placeholder: Text) {
        self._inputText = text
        self.placeholder = placeholder
    }

    public var body: some View {
        Representable(
            text: $inputText,
            config: config,
            controller: controller,
            contentHeight: $contentHeight,
            oneLineHeight: $oneLineHeight,
            isComposing: $isComposing
        )
        .frame(height: resolvedHeight)
        .if(config.clipShapeApplier != nil, transform: { content in
            config.clipShapeApplier!(AnyView(content))
        })
        .background {
            config.background
        }
        .overlay(alignment: .topLeading) {
            if inputText.isEmpty && !isComposing {
                placeholderStyled
                    .padding(config.textInsets)
                    .allowsHitTesting(false)
            }
        }
        .overlay(alignment: .topLeading) {
            if let state = controller.menuState, !state.items.isEmpty {
                TextAreaMenuView(state: state) { index in
                    guard state.items.indices.contains(index) else { return }
                    controller.applyInsertion(state.items[index].resolve())
                }
                .offset(x: state.anchorRect.minX, y: state.anchorRect.maxY + 4)
                .allowsHitTesting(true)
            }
        }
        .onAppear {
            proxy?.controller = controller
        }
    }

    private var resolvedHeight: CGFloat {
        // After the first measurement, contentHeight is the real value.
        if contentHeight > 0 {
            return min(contentHeight, config.maxHeight)
        }
        // Before the first measurement, fall back to the last known
        // one-line height. If that hasn't been recorded either (very first
        // frame), estimate from system font metrics so we never render
        // with an indeterminate height.
        if oneLineHeight > 0 {
            return oneLineHeight
        }
        return estimatedSingleLineHeight
    }

    private var estimatedSingleLineHeight: CGFloat {
        let verticalInset = config.textInsets.top + config.textInsets.bottom
#if canImport(AppKit)
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return ceil(font.boundingRectForFont.height) + verticalInset
#elseif canImport(UIKit)
        let font = UIFont.preferredFont(forTextStyle: .body)
        return ceil(font.lineHeight) + verticalInset
#else
        return 40
#endif
    }

    @ViewBuilder
    private var placeholderStyled: some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            placeholder.foregroundStyle(.placeholder)
        } else {
            placeholder.foregroundStyle(.secondary)
        }
    }

    class Config {
        var maxHeight: CGFloat = 200
        var textInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        var overflowTolerance: CGFloat = 1
        var background: AnyView = AnyView(EmptyView())
        var clipShapeApplier: ((AnyView) -> AnyView)?
        var onSingleLineChanged: ((_ isSingleLine: Bool) -> Void)?
        var linesOverflowBinding: Binding<Bool>?
        var autofocus: Bool = false
        var submitOnReturn: (() -> Void)?
        var submitOnReturnSources: TextAreaReturnSubmitSources = .all
        var triggers: [Character: AnyTextAreaTrigger] = [:]
        var pasteHandler: ((TextAreaPasteItem) -> TextAreaInsertion?)?
#if canImport(AppKit)
        var userKeyDownHandler: TextFieldKeyDownEventHandler?
#endif
    }

    /// Caps the vertical growth of the editor.
    ///
    /// The editor grows to fit its content up to `height`. Beyond that, it
    /// scrolls internally and tracks the caret automatically.
    ///
    /// - Parameter height: Maximum editor height in points. Default is 200.
    /// - Returns: A text area whose height is capped at `height`.
    @MainActor
    public func maxHeight(_ height: CGFloat) -> TextArea {
        self.config.maxHeight = height
        return self
    }

    /// Sets the editor's text container insets.
    ///
    /// This changes where text and placeholder content are laid out without
    /// changing the editor view's own width. It is useful when callers overlay
    /// controls inside the editor chrome: increase the trailing inset so text
    /// avoids the control while the internal scroll indicator can remain at the
    /// editor edge.
    ///
    /// - Parameter insets: Insets applied around text content. Default is
    ///   `12` points on every edge.
    /// - Returns: A text area whose text content uses the given insets.
    @MainActor
    public func textInsets(_ insets: EdgeInsets) -> TextArea {
        self.config.textInsets = insets
        return self
    }

    /// Clips the editor to the given shape.
    ///
    /// Use to give the editor rounded corners or a pill / capsule outline.
    /// Apply after ``background(_:)`` if both are used.
    ///
    /// - Parameter shape: The shape to clip to.
    /// - Returns: A text area clipped to `shape`.
    @MainActor
    public func clipShape<S: Shape>(_ shape: S) -> TextArea {
        config.clipShapeApplier = { content in AnyView(content.clipShape(shape)) }
        return self
    }

    /// Sets the background view rendered behind the editor's content.
    ///
    /// - Parameter content: A view builder that produces the background.
    /// - Returns: A text area with the given background.
    @MainActor
    public func background<Content: View>(@ViewBuilder _ content: () -> Content) -> TextArea {
        self.config.background = AnyView(content())
        return self
    }

    /// Calls `action` when the editor crosses the single-line boundary.
    ///
    /// The closure receives `true` when the editor returns to a single line
    /// (e.g. after deleting a newline) and `false` when it grows to two or
    /// more lines. Useful for switching between an inline send button and
    /// a multi-line layout.
    ///
    /// - Parameter action: A closure called with the new single-line state.
    /// - Returns: A modified text area.
    @MainActor
    public func onSingleLineChanged(_ action: @escaping (_ isSingleLine: Bool) -> Void) -> TextArea {
        self.config.onSingleLineChanged = action
        return self
    }

    /// Mirrors whether the editor's content has grown past ``maxHeight(_:)``
    /// into the given binding.
    ///
    /// The binding is set to `true` when content exceeds `maxHeight` (the
    /// editor switches to internal scrolling) and `false` when it shrinks
    /// back within. Useful for showing a "more content" hint or adjusting
    /// surrounding UI.
    ///
    /// - Parameter isOverflowing: A binding written whenever the overflow
    ///   state crosses the threshold.
    /// - Returns: A modified text area.
    @MainActor
    public func linesOverflow(_ isOverflowing: Binding<Bool>) -> TextArea {
        self.config.linesOverflowBinding = isOverflowing
        return self
    }

    /// Requests focus once when the underlying platform text view is ready.
    ///
    /// This is intentionally opt-in. Unlike SwiftUI's `.focused`, the request
    /// is fulfilled by the wrapped text view itself after it has entered a
    /// window, which avoids the common "focus before UIKit/AppKit is ready"
    /// race during animated presentation.
    ///
    /// - Parameter enabled: Pass `false` to keep the modifier in a conditional
    ///   chain without requesting focus. Defaults to `true`.
    /// - Returns: A text area that focuses itself once on appearance.
    @MainActor
    public func autofocus(_ enabled: Bool = true) -> TextArea {
        self.config.autofocus = enabled
        return self
    }

    /// Submits when the user presses Return without Shift.
    ///
    /// By default, this handles both software and hardware keyboard Return
    /// where the platform exposes them. Pass `sources` to choose a narrower
    /// policy, such as hardware-keyboard-only submission on iPad.
    @MainActor
    public func submitOnReturn(
        sources: TextAreaReturnSubmitSources = .all,
        _ action: @escaping () -> Void
    ) -> TextArea {
        self.config.submitOnReturn = action
        self.config.submitOnReturnSources = sources
        return self
    }

#if canImport(AppKit)
    /// Installs a key-down handler that runs before the underlying NSTextView.
    ///
    /// Return `nil` from the handler to consume the event, or return the
    /// event to let it pass through to the editor. The handler is bypassed
    /// during IME composition so that input methods can commit candidates
    /// uninterrupted.
    ///
    /// Typical use is the *Enter sends, Shift+Enter newline* pattern:
    ///
    /// ```swift
    /// .keyDownHandler(
    ///     TextFieldKeyDownEventHandler(triggers: [(36, nil)]) { event in
    ///         guard let event else { return nil }
    ///         if event.keyCode == 36, !event.modifierFlags.contains(.shift) {
    ///             send()
    ///             return nil
    ///         }
    ///         return event
    ///     }
    /// )
    /// ```
    ///
    /// - Parameter handler: The key-down handler.
    /// - Returns: A modified text area.
    /// - Note: macOS only.
    @MainActor
    public func keyDownHandler(_ handler: TextFieldKeyDownEventHandler) -> TextArea {
        self.config.userKeyDownHandler = handler
        return self
    }
#endif

    /// Registers a trigger source.
    ///
    /// When the user types `trigger.character` at a word boundary (start of
    /// input, or preceded by whitespace), a menu opens with items returned
    /// by the trigger's `search`. Inside the menu:
    ///
    /// - **↑** / **↓** navigates
    /// - **Return** commits the highlighted item
    /// - **Escape** dismisses
    /// - Typing extends the query and re-searches
    /// - Whitespace dismisses the menu
    ///
    /// Multiple triggers can be registered. If two triggers share the same
    /// `character`, the one registered later replaces the earlier one.
    ///
    /// - Parameter trigger: The trigger source. Use ``MenuTrigger`` for the
    ///   common closure-based case, or conform to ``TextAreaTrigger`` for
    ///   custom needs.
    /// - Returns: A modified text area.
    @MainActor
    public func trigger<T: TextAreaTrigger>(_ trigger: T) -> TextArea {
        self.config.triggers[trigger.character] = AnyTextAreaTrigger(trigger)
        return self
    }
}
