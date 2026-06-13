//
//  TextArea+AppKit.swift
//  ChocofordKit
//
//  Created by Codex on 2026/06/08.
//

#if canImport(AppKit)
import SwiftUI
import AppKit

extension TextArea {
    struct Representable: NSViewRepresentable {
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
            applyTextInsets(to: textView)
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
            textView.submitOnReturn = config.submitOnReturn

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
            let maxHeightChanged = context.coordinator.parent.config.maxHeight != config.maxHeight
            context.coordinator.parent = self
            guard let textView = scrollView.documentView as? AutoGrowNSTextView else { return }
            let didUpdateInsets = applyTextInsets(to: textView)
            textView.userKeyDownHandler = config.userKeyDownHandler
            textView.submitOnReturn = config.submitOnReturn
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
            } else if didUpdateInsets || maxHeightChanged {
                DispatchQueue.main.async {
                    context.coordinator.recomputeHeight()
                }
            }
        }

        @discardableResult
        private func applyTextInsets(to textView: AutoGrowNSTextView) -> Bool {
            // NSTextView only exposes symmetric horizontal inset knobs. Preserve
            // the existing default behavior and approximate asymmetric callers
            // with the larger horizontal/vertical values.
            let verticalInset = max(config.textInsets.top, config.textInsets.bottom)
            let horizontalInset = max(config.textInsets.leading, config.textInsets.trailing)
            let textContainerInset = NSSize(width: 0, height: verticalInset)

            var didChange = false
            if textView.textContainerInset != textContainerInset {
                textView.textContainerInset = textContainerInset
                didChange = true
            }
            if textView.textContainer?.lineFragmentPadding != horizontalInset {
                textView.textContainer?.lineFragmentPadding = horizontalInset
                didChange = true
            }
            return didChange
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

                let contentHeight = measuredContentHeight(in: textView)
                let height = ceil(contentHeight) + textView.textContainerInset.height * 2

                // Toggle the scroller based on whether content actually exceeds
                // maxHeight, not on the current (animated) frame size. Otherwise
                // the scroll bar flashes during the grow animation while the
                // SwiftUI frame is still catching up to the new content height.
                let isOverflowing = height > parent.config.maxHeight + parent.config.overflowTolerance
                if let scrollView {
                    if scrollView.hasVerticalScroller != isOverflowing {
                        scrollView.hasVerticalScroller = isOverflowing
                    }
                }
                if let binding = parent.config.linesOverflowBinding,
                   binding.wrappedValue != isOverflowing {
                    binding.wrappedValue = isOverflowing
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

            private func measuredContentHeight(in textView: AutoGrowNSTextView) -> CGFloat {
                let width = measuredTextWidth(in: textView)
                let attributed = measuredAttributedString(in: textView)
                let rect = attributed.boundingRect(
                    with: NSSize(
                        width: width,
                        height: CGFloat.greatestFiniteMagnitude
                    ),
                    options: [.usesLineFragmentOrigin, .usesFontLeading]
                )
                return ceil(rect.height)
            }

            private func measuredAttributedString(in textView: AutoGrowNSTextView) -> NSAttributedString {
                let attributed = textView.attributedString()
                guard attributed.length == 0 else { return attributed }

                let font = textView.font ?? .systemFont(ofSize: NSFont.systemFontSize)
                return NSAttributedString(string: " ", attributes: [.font: font])
            }

            private func measuredTextWidth(in textView: AutoGrowNSTextView) -> CGFloat {
                let containerWidth = [
                    textView.bounds.width,
                    textView.enclosingScrollView?.contentSize.width ?? 0,
                    measuredTextContainerWidth(in: textView)
                ]
                .first { $0 > 0 } ?? 1
                let horizontalInset = textView.textContainerInset.width * 2
                let lineFragmentPadding = (textView.textContainer?.lineFragmentPadding ?? 0) * 2
                return max(1, containerWidth - horizontalInset - lineFragmentPadding)
            }

            private func measuredTextContainerWidth(in textView: AutoGrowNSTextView) -> CGFloat {
                guard let width = textView.textContainer?.containerSize.width,
                      width.isFinite,
                      width < CGFloat.greatestFiniteMagnitude / 2 else {
                    return 0
                }
                return width
            }
        }
    }
}

final class AutoGrowNSTextView: NSTextView {
    fileprivate weak var coordinator: TextArea.Representable.Coordinator?
    weak var controller: TextAreaController?
    var userKeyDownHandler: TextFieldKeyDownEventHandler?
    var submitOnReturn: (() -> Void)?
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
        if let submitOnReturn,
           event.keyCode == 36,
           !event.modifierFlags.contains(.shift) {
            submitOnReturn()
            return
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

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard canHandleDrop(sender) else {
            return super.draggingEntered(sender)
        }
        return .copy
    }

    override func prepareForDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard canHandleDrop(sender) else {
            return super.prepareForDragOperation(sender)
        }
        return true
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard canHandleDrop(sender) else {
            return super.performDragOperation(sender)
        }
        let items = TextAreaPasteItem.items(from: sender.draggingPasteboard)
        guard !items.isEmpty else { return false }
        return controller?.handlePaste(items) ?? false
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

    private func canHandleDrop(_ sender: any NSDraggingInfo) -> Bool {
        guard controller?.pasteHandler != nil else { return false }
        let items = TextAreaPasteItem.items(from: sender.draggingPasteboard)
        return items.contains { item in
            switch item {
                case .image, .fileURL, .url:
                    return true
                case .text, .unknown:
                    return false
            }
        }
    }
}
#endif
