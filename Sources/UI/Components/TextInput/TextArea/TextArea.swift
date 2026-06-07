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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
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
        return Self.estimatedSingleLineHeight
    }

    private static var estimatedSingleLineHeight: CGFloat {
        // Vertical inset is 12 top + 12 bottom (see makeNSView / makeUIView).
        let inset: CGFloat = 24
#if canImport(AppKit)
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return ceil(font.boundingRectForFont.height) + inset
#elseif canImport(UIKit)
        let font = UIFont.preferredFont(forTextStyle: .body)
        return ceil(font.lineHeight) + inset
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
        var background: AnyView = AnyView(EmptyView())
        var clipShapeApplier: ((AnyView) -> AnyView)?
        var onSingleLineChanged: ((_ isSingleLine: Bool) -> Void)?
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

// MARK: - macOS

#if canImport(AppKit)
extension TextArea {
    fileprivate struct Representable: NSViewRepresentable {
        @Binding var text: String
        var config: Config
        var controller: TextAreaController
        @Binding var contentHeight: CGFloat
        @Binding var oneLineHeight: CGFloat
        @Binding var isComposing: Bool

        func makeNSView(context: Context) -> NSScrollView {
            let scrollView = NSScrollView()
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.borderType = .noBorder
            scrollView.drawsBackground = false
            scrollView.autohidesScrollers = true

            let textView = AutoGrowNSTextView(usingTextLayoutManager: true)
            textView.coordinator = context.coordinator
            textView.controller = controller
            textView.delegate = context.coordinator
            textView.isEditable = true
            // Rich text mode is required for inline attachments (token rendering)
            // and broad paste validation. Formatting toolbars / font panel are
            // disabled below to keep typing behaviour plain.
            textView.isRichText = true
            textView.usesFontPanel = false
            textView.usesRuler = false
            textView.usesInspectorBar = false
            textView.importsGraphics = false  // paste paths handled by us
            textView.allowsImageEditing = false
            textView.allowsUndo = true
            textView.drawsBackground = false
            textView.font = .systemFont(ofSize: NSFont.systemFontSize)
            // Bind to system-dynamic colors so appearance changes (light/dark)
            // propagate even if some path replaces attributes.
            textView.textColor = .labelColor
            textView.insertionPointColor = .labelColor
            textView.typingAttributes = [
                .foregroundColor: NSColor.labelColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            textView.textContainerInset = NSSize(width: 0, height: 12)
            textView.textContainer?.lineFragmentPadding = 12
            textView.textContainer?.widthTracksTextView = true
            textView.minSize = .zero
            textView.maxSize = NSSize(
                width: CGFloat.infinity,
                height: CGFloat.infinity
            )
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.autoresizingMask = .width
            textView.string = text
            textView.userKeyDownHandler = config.userKeyDownHandler

            scrollView.documentView = textView
            context.coordinator.textView = textView
            context.coordinator.scrollView = scrollView
            controller.textView = textView
            controller.triggers = config.triggers
            controller.pasteHandler = config.pasteHandler

            DispatchQueue.main.async {
                context.coordinator.recomputeHeight()
            }
            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            context.coordinator.parent = self
            guard let textView = scrollView.documentView as? AutoGrowNSTextView else { return }
            textView.userKeyDownHandler = config.userKeyDownHandler
            textView.controller = controller
            controller.textView = textView
            controller.triggers = config.triggers
            controller.pasteHandler = config.pasteHandler
            // Compare on plain-text representation so token attachments aren't
            // clobbered when the binding hasn't actually diverged.
            let currentPlain = textView.textStorage?.textAreaPlainText ?? ""
            if !textView.hasMarkedText() && currentPlain != text {
                textView.string = text
                DispatchQueue.main.async {
                    context.coordinator.recomputeHeight()
                }
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        @MainActor
        final class Coordinator: NSObject, NSTextViewDelegate {
            var parent: Representable
            weak var textView: AutoGrowNSTextView?
            weak var scrollView: NSScrollView?

            init(_ parent: Representable) {
                self.parent = parent
            }

            func textDidChange(_ notification: Notification) {
                guard let textView = notification.object as? NSTextView else { return }
                if !textView.hasMarkedText() {
                    let plain = textView.textStorage?.textAreaPlainText ?? ""
                    if parent.text != plain {
                        parent.text = plain
                    }
                }
                recomputeHeight()
                recomputeComposing()
                // Trigger detection is run from textViewDidChangeSelection,
                // which fires after every keystroke too (the caret moves).
                // Skipping it here avoids doing the work twice per keystroke.
            }

            func textViewDidChangeSelection(_ notification: Notification) {
                guard let textView = notification.object as? NSTextView else { return }
                if !textView.hasMarkedText() {
                    parent.controller.detectAfterTextChange()
                }
            }

            func recomputeHeight() {
                guard let textView else { return }

                let contentHeight: CGFloat
                if let textLayoutManager = textView.textLayoutManager {
                    // TextKit 2
                    textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
                    contentHeight = textLayoutManager.usageBoundsForTextContainer.height
                } else if let layoutManager = textView.layoutManager,
                          let textContainer = textView.textContainer {
                    // TextKit 1 fallback
                    layoutManager.ensureLayout(for: textContainer)
                    contentHeight = layoutManager.usedRect(for: textContainer).height
                } else {
                    return
                }

                let height = ceil(contentHeight) + textView.textContainerInset.height * 2

                // Toggle the scroller based on whether content actually exceeds
                // maxHeight, not on the current (animated) frame size. Otherwise
                // the scroll bar flashes during the grow animation while the
                // SwiftUI frame is still catching up to the new content height.
                if let scrollView {
                    let shouldShow = height > parent.config.maxHeight
                    if scrollView.hasVerticalScroller != shouldShow {
                        scrollView.hasVerticalScroller = shouldShow
                    }
                }

                if parent.oneLineHeight <= 0 {
                    parent.oneLineHeight = height
                }

                let oldHeight = parent.contentHeight
                guard oldHeight != height else { return }

                if oldHeight > 0 {
                    let anim: Animation
                    if #available(macOS 14.0, iOS 17.0, *) {
                        anim = .smooth
                    } else {
                        anim = .easeOut(duration: 0.25)
                    }
                    withAnimation(anim) {
                        parent.contentHeight = height
                    }
                } else {
                    parent.contentHeight = height
                }

                let wasMulti = oldHeight > parent.oneLineHeight
                let isMulti = height > parent.oneLineHeight
                if wasMulti != isMulti {
                    parent.config.onSingleLineChanged?(!isMulti)
                }
            }

            func recomputeComposing() {
                let composing = textView?.hasMarkedText() ?? false
                if parent.isComposing != composing {
                    parent.isComposing = composing
                }
            }
        }
    }
}

final class AutoGrowNSTextView: NSTextView {
    fileprivate weak var coordinator: TextArea.Representable.Coordinator?
    weak var controller: TextAreaController?
    var userKeyDownHandler: TextFieldKeyDownEventHandler?
    private var isNormalizingAttributes = false
    private var lastFrameWidth: CGFloat = 0
    private var heightRecomputeScheduled = false
    private var imeRecomputeScheduled = false

    override func keyDown(with event: NSEvent) {
        if hasMarkedText() {
            super.keyDown(with: event)
            return
        }
        if let controller, controller.menuState != nil {
            switch event.keyCode {
            case 36, 76:
                controller.commitSelection()
                return
            case 53:
                controller.dismiss()
                return
            case 125:
                controller.selectNext()
                return
            case 126:
                controller.selectPrevious()
                return
            default:
                break
            }
        }
        if let handler = userKeyDownHandler {
            if handler(event) == nil { return }
        }
        super.keyDown(with: event)
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        // Coalesce rapid IME compose events into a single update per runloop.
        guard !imeRecomputeScheduled else { return }
        imeRecomputeScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.imeRecomputeScheduled = false
            self?.coordinator?.recomputeComposing()
            self?.coordinator?.recomputeHeight()
        }
    }

    override func unmarkText() {
        super.unmarkText()
        DispatchQueue.main.async { [weak self] in
            self?.coordinator?.recomputeComposing()
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        // Height-only changes (e.g. SwiftUI animating our `.frame(height:)`,
        // or text growing in place) do not require a full re-layout —
        // textDidChange already covers content changes. Only react to width
        // changes (window resize / parent reflow) which actually affect line
        // wrapping and therefore content height.
        guard newSize.width != lastFrameWidth else { return }
        lastFrameWidth = newSize.width
        guard !heightRecomputeScheduled else { return }
        heightRecomputeScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.heightRecomputeScheduled = false
            self?.coordinator?.recomputeHeight()
        }
    }

    private func normalizeAppearanceAttributes() {
        guard !isNormalizingAttributes,
              let textStorage,
              textStorage.length > 0 else { return }
        let range = NSRange(location: 0, length: textStorage.length)
        isNormalizingAttributes = true
        textStorage.beginEditing()
        // Overwrite — not remove — so every glyph resolves through
        // NSColor.labelColor (a dynamic system color) at draw time.
        // Removing the attribute alone is unreliable: some rendering paths
        // fall back to a hardcoded color instead of the textView's textColor.
        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
        textStorage.endEditing()
        // Also keep typingAttributes dynamic so the next character the user
        // types after a formatted paste isn't locked to the source colour.
        var typing = self.typingAttributes
        typing[.foregroundColor] = NSColor.labelColor
        self.typingAttributes = typing
        isNormalizingAttributes = false
    }

    override func paste(_ sender: Any?) {
        // No custom handler — paste as plain text only (avoid pulling source
        // formatting into the editor).
        defer { normalizeAppearanceAttributes() }
        guard let controller, controller.pasteHandler != nil else {
            pasteAsPlainText(sender)
            return
        }
        guard let pbItems = NSPasteboard.general.pasteboardItems, !pbItems.isEmpty else {
            pasteAsPlainText(sender)
            return
        }
        let items = pbItems.compactMap { TextAreaPasteItem(from: $0) }
        guard !items.isEmpty else {
            pasteAsPlainText(sender)
            return
        }
        controller.handlePaste(items)
    }

    override func readSelection(
        from pboard: NSPasteboard,
        type: NSPasteboard.PasteboardType
    ) -> Bool {
        let didRead = super.readSelection(from: pboard, type: type)
        if didRead { normalizeAppearanceAttributes() }
        return didRead
    }

    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        // Always allow paste while the pasteboard has any item — our override
        // decides what to do with it. Without this, a pasteboard containing
        // only image / file content would make the action invalid and the
        // system would beep before paste(_:) is even called.
        if item.action == #selector(NSText.paste(_:)) {
            return NSPasteboard.general.pasteboardItems?.isEmpty == false
        }
        return super.validateUserInterfaceItem(item)
    }
}
#endif

// MARK: - iOS

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
extension TextArea {
    fileprivate struct Representable: UIViewRepresentable {
        @Binding var text: String
        var config: Config
        var controller: TextAreaController
        @Binding var contentHeight: CGFloat
        @Binding var oneLineHeight: CGFloat
        @Binding var isComposing: Bool

        func makeUIView(context: Context) -> UITextView {
            let textView = AutoGrowUITextView(usingTextLayoutManager: true)
            textView.coordinator = context.coordinator
            textView.delegate = context.coordinator
            textView.font = .preferredFont(forTextStyle: .body)
            textView.backgroundColor = .clear
            textView.textColor = .label
            textView.tintColor = .label
            textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            textView.textContainer.lineFragmentPadding = 0
            // Start non-scrolling: lets the frame grow naturally with content.
            // We flip to scrolling once measured height exceeds maxHeight, see
            // recomputeHeight below.
            textView.isScrollEnabled = false
            textView.text = text

            context.coordinator.textView = textView

            DispatchQueue.main.async {
                context.coordinator.recomputeHeight()
            }
            return textView
        }

        func updateUIView(_ textView: UITextView, context: Context) {
            context.coordinator.parent = self
            // Skip while IME is composing — assigning `text` clears marked text.
            if textView.markedTextRange == nil && textView.text != text {
                textView.text = text
                DispatchQueue.main.async {
                    context.coordinator.recomputeHeight()
                }
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        @MainActor
        final class Coordinator: NSObject, UITextViewDelegate {
            fileprivate var parent: Representable
            weak var textView: AutoGrowUITextView?

            fileprivate init(_ parent: Representable) {
                self.parent = parent
            }

            func textViewDidChange(_ textView: UITextView) {
                if textView.markedTextRange == nil && parent.text != textView.text {
                    parent.text = textView.text
                }
                recomputeHeight()
                recomputeComposing()
            }

            func textViewDidChangeSelection(_ textView: UITextView) {
                recomputeComposing()
            }

            func recomputeHeight() {
                guard let textView else { return }

                let contentHeight: CGFloat
                if let textLayoutManager = textView.textLayoutManager {
                    // TextKit 2
                    textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
                    contentHeight = textLayoutManager.usageBoundsForTextContainer.height
                } else {
                    // TextKit 1 fallback (e.g. if init(usingTextLayoutManager:) wasn't honored)
                    let lm = textView.layoutManager
                    lm.ensureLayout(for: textView.textContainer)
                    contentHeight = lm.usedRect(for: textView.textContainer).height
                }

                let insetVertical = textView.textContainerInset.top + textView.textContainerInset.bottom
                let height = ceil(contentHeight) + insetVertical

                // Toggle internal scrolling: only enable once content exceeds
                // maxHeight so the frame can grow naturally below that.
                let shouldScroll = height > parent.config.maxHeight
                if textView.isScrollEnabled != shouldScroll {
                    textView.isScrollEnabled = shouldScroll
                }

                if parent.oneLineHeight <= 0 {
                    parent.oneLineHeight = height
                }

                let oldHeight = parent.contentHeight
                guard oldHeight != height else { return }

                if oldHeight > 0 {
                    let anim: Animation
                    if #available(macOS 14.0, iOS 17.0, *) {
                        anim = .smooth
                    } else {
                        anim = .easeOut(duration: 0.25)
                    }
                    withAnimation(anim) {
                        parent.contentHeight = height
                    }
                } else {
                    parent.contentHeight = height
                }

                let wasMulti = oldHeight > parent.oneLineHeight
                let isMulti = height > parent.oneLineHeight
                if wasMulti != isMulti {
                    parent.config.onSingleLineChanged?(!isMulti)
                }
            }

            func recomputeComposing() {
                let composing = textView?.markedTextRange != nil
                if parent.isComposing != composing {
                    parent.isComposing = composing
                }
            }
        }
    }
}

final class AutoGrowUITextView: UITextView {
    fileprivate weak var coordinator: TextArea.Representable.Coordinator?
    private var lastFrameWidth: CGFloat = 0
    private var heightRecomputeScheduled = false

    override func layoutSubviews() {
        super.layoutSubviews()
        // Only react to width changes (rotation / parent reflow); height
        // changes are driven by us and don't require another recompute.
        guard bounds.width != lastFrameWidth else { return }
        lastFrameWidth = bounds.width
        guard !heightRecomputeScheduled else { return }
        heightRecomputeScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.heightRecomputeScheduled = false
            self?.coordinator?.recomputeHeight()
        }
    }
}
#endif
