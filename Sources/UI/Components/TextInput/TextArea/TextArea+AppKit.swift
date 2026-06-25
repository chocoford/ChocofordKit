//
//  TextArea+AppKit.swift
//  ChocofordKit
//
//  Created by Codex on 2026/06/08.
//

#if canImport(AppKit)
import SwiftUI
import AppKit

private extension NSEdgeInsets {
    func isEqual(to other: NSEdgeInsets) -> Bool {
        top == other.top &&
        left == other.left &&
        bottom == other.bottom &&
        right == other.right
    }
}

final class TextAreaScrollContainerView: NSView {
    let scrollView = NSScrollView()
    var onLayoutSizeChanged: (() -> Void)?
    private var lastLayoutSize: NSSize = .zero

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(scrollView)
    }

    override func layout() {
        super.layout()

        let sizeChanged = bounds.size != lastLayoutSize
        lastLayoutSize = bounds.size

        scrollView.frame = bounds
        let zeroInsets = NSEdgeInsets()
        if !scrollView.contentInsets.isEqual(to: zeroInsets) {
            scrollView.contentInsets = zeroInsets
        }

        if sizeChanged {
            onLayoutSizeChanged?()
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let documentView = scrollView.documentView as? TextAreaDocumentView {
            window?.makeFirstResponder(documentView.textView)
            return
        }
        if let textView = scrollView.documentView as? NSTextView {
            window?.makeFirstResponder(textView)
            return
        }
        super.mouseDown(with: event)
    }
}

final class TextAreaDocumentView: NSView {
    let textView: AutoGrowNSTextView
    var textInsets = NSEdgeInsets() {
        didSet {
            guard !textInsets.isEqual(to: oldValue) else { return }
            needsLayout = true
        }
    }
    var textContentHeight: CGFloat = 0 {
        didSet {
            guard textContentHeight != oldValue else { return }
            needsLayout = true
        }
    }

    override var isFlipped: Bool { true }

    init(textView: AutoGrowNSTextView) {
        self.textView = textView
        super.init(frame: .zero)
        addSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()

        let width = max(1, bounds.width - textInsets.left - textInsets.right)
        let availableHeight = max(1, bounds.height - textInsets.top - textInsets.bottom)
        let height = max(textContentHeight, availableHeight)
        textView.frame = NSRect(
            x: textInsets.left,
            y: textInsets.top,
            width: width,
            height: height
        )
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(textView)
    }
}

extension TextAreaFont {
    var appKitFont: NSFont {
        let pointSize = size ?? NSFont.systemFontSize
        switch design {
            case .default:
                return .systemFont(ofSize: pointSize, weight: appKitWeight)
            case .monospaced:
                return .monospacedSystemFont(ofSize: pointSize, weight: appKitWeight)
        }
    }

    private var appKitWeight: NSFont.Weight {
        switch weight {
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semibold:
                return .semibold
            case .bold:
                return .bold
        }
    }
}

extension TextArea {
    struct Representable: NSViewRepresentable {
        @Binding var text: String
        var config: Config
        var controller: TextAreaController
        @Binding var contentHeight: CGFloat
        @Binding var oneLineHeight: CGFloat
        @Binding var isComposing: Bool

        func makeNSView(context: Context) -> TextAreaScrollContainerView {
            let containerView = TextAreaScrollContainerView()
            let scrollView = containerView.scrollView
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
            let font = config.font.appKitFont
            textView.font = font
            // Bind to system-dynamic colors so appearance changes (light/dark)
            // propagate even if some path replaces attributes.
            textView.textColor = .labelColor
            textView.insertionPointColor = .labelColor
            textView.typingAttributes = [
                .foregroundColor: NSColor.labelColor,
                .font: font
            ]
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
            textView.submitOnReturnSources = config.submitOnReturnSources

            let documentView = TextAreaDocumentView(textView: textView)
            scrollView.documentView = documentView
            applyTextInsets(to: textView, in: documentView)
            context.coordinator.textView = textView
            context.coordinator.scrollView = scrollView
            context.coordinator.documentView = documentView
            controller.textView = textView
            controller.triggers = config.triggers
            controller.pasteHandler = config.pasteHandler
            containerView.onLayoutSizeChanged = { [weak coordinator = context.coordinator] in
                coordinator?.scheduleRecomputeHeight()
            }

            DispatchQueue.main.async {
                context.coordinator.recomputeHeight()
            }
            return containerView
        }

        func updateNSView(_ containerView: TextAreaScrollContainerView, context: Context) {
            let sizingChanged = context.coordinator.parent.config.sizing != config.sizing
            context.coordinator.parent = self
            let scrollView = containerView.scrollView
            guard let documentView = scrollView.documentView as? TextAreaDocumentView else { return }
            let textView = documentView.textView
            let didUpdateFont = applyFont(to: textView)
            let didUpdateInsets = applyTextInsets(to: textView, in: documentView)
            textView.userKeyDownHandler = config.userKeyDownHandler
            textView.submitOnReturn = config.submitOnReturn
            textView.submitOnReturnSources = config.submitOnReturnSources
            textView.controller = controller
            controller.textView = textView
            controller.triggers = config.triggers
            controller.pasteHandler = config.pasteHandler
            // Compare on plain-text representation so token attachments aren't
            // clobbered when the binding hasn't actually diverged.
            let currentPlain = textView.textStorage?.textAreaPlainText ?? ""
            if !textView.hasMarkedText() && currentPlain != text {
                replaceTextSafely(in: textView, with: text)
                DispatchQueue.main.async {
                    context.coordinator.recomputeHeight()
                }
            } else if didUpdateFont || didUpdateInsets || sizingChanged {
                DispatchQueue.main.async {
                    context.coordinator.recomputeHeight()
                }
            }
        }

        private func replaceTextSafely(in textView: AutoGrowNSTextView, with text: String) {
            let selectedRange = textView.selectedRange()
            let currentLength = (textView.string as NSString).length
            let replacementLength = (text as NSString).length
            let safeUpperBound = min(currentLength, replacementLength)
            let safeLocation = min(selectedRange.location, safeUpperBound)
            let safeLength = min(selectedRange.length, max(0, safeUpperBound - safeLocation))
            let safeRange = NSRange(location: safeLocation, length: safeLength)

            textView.controller?.isProgrammaticEdit = true
            defer {
                textView.controller?.isProgrammaticEdit = false
            }
            textView.setSelectedRange(safeRange)
            textView.string = text
            textView.setSelectedRange(safeRange)
        }

        @discardableResult
        private func applyFont(to textView: AutoGrowNSTextView) -> Bool {
            let font = config.font.appKitFont
            var didChange = false
            if textView.font != font {
                textView.font = font
                didChange = true
            }

            var typing = textView.typingAttributes
            if let currentFont = typing[.font] as? NSFont {
                if !currentFont.isEqual(font) {
                    typing[.font] = font
                    didChange = true
                }
            } else {
                typing[.font] = font
                didChange = true
            }
            if let currentColor = typing[.foregroundColor] as? NSColor {
                if !currentColor.isEqual(NSColor.labelColor) {
                    typing[.foregroundColor] = NSColor.labelColor
                    didChange = true
                }
            } else {
                typing[.foregroundColor] = NSColor.labelColor
                didChange = true
            }
            textView.typingAttributes = typing

            if didChange,
               let textStorage = textView.textStorage,
               textStorage.length > 0 {
                textStorage.addAttribute(
                    .font,
                    value: font,
                    range: NSRange(location: 0, length: textStorage.length)
                )
            }
            return didChange
        }

        @discardableResult
        private func applyTextInsets(to textView: AutoGrowNSTextView, in documentView: TextAreaDocumentView) -> Bool {
            let textInsets = NSEdgeInsets(
                top: config.textInsets.top,
                left: config.textInsets.leading,
                bottom: config.textInsets.bottom,
                right: config.textInsets.trailing
            )

            var didChange = false
            if !documentView.textInsets.isEqual(to: textInsets) {
                documentView.textInsets = textInsets
                didChange = true
            }
            if textView.textContainerInset != .zero {
                textView.textContainerInset = .zero
                didChange = true
            }
            if textView.textContainer?.lineFragmentPadding != 0 {
                textView.textContainer?.lineFragmentPadding = 0
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
            weak var documentView: TextAreaDocumentView?
            fileprivate var isOverflowing = false
            private var heightRecomputeScheduled = false

            init(_ parent: Representable) {
                self.parent = parent
            }

            func scheduleRecomputeHeight() {
                guard !heightRecomputeScheduled else { return }
                heightRecomputeScheduled = true
                DispatchQueue.main.async { [weak self] in
                    self?.heightRecomputeScheduled = false
                    self?.recomputeHeight()
                }
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
                let verticalInsets = parent.config.textInsets.top + parent.config.textInsets.bottom
                let height = ceil(contentHeight) + verticalInsets

                // Toggle the scroller based on the sizing policy, not on the
                // current animated SwiftUI frame. Otherwise the scroll bar can
                // flash while the frame catches up to content growth.
                let isOverflowing = isContentOverflowing(
                    measuredTextHeight: contentHeight,
                    totalHeight: height
                )
                self.isOverflowing = isOverflowing
                if let scrollView {
                    let scrollerVisibilityChanged = scrollView.hasVerticalScroller != isOverflowing
                    if scrollView.hasVerticalScroller != isOverflowing {
                        scrollView.hasVerticalScroller = isOverflowing
                    }
                    if scrollerVisibilityChanged {
                        scheduleRecomputeHeight()
                    }
                }
                syncDocumentSize(totalHeight: height)
                if !isOverflowing {
                    resetScrollPositionToTop()
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
                if let layoutHeight = measuredLayoutHeight(in: textView) {
                    return layoutHeight
                }

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

            private func measuredLayoutHeight(in textView: AutoGrowNSTextView) -> CGFloat? {
                guard let layoutManager = textView.layoutManager,
                      let textContainer = textView.textContainer else {
                    return nil
                }

                layoutManager.ensureLayout(for: textContainer)
                let usedRect = layoutManager.usedRect(for: textContainer)
                guard usedRect.height.isFinite, usedRect.height > 0 else {
                    return nil
                }
                return ceil(usedRect.maxY)
            }

            private func isContentOverflowing(measuredTextHeight: CGFloat, totalHeight: CGFloat) -> Bool {
                switch parent.config.sizing.storage {
                    case .autoGrow:
                        return false
                    case .autoGrowMaxHeight(let maxHeight):
                        return totalHeight > maxHeight + parent.config.overflowTolerance
                    case .fill:
                        guard let scrollView else { return false }
                        let visibleHeight = scrollView.contentSize.height
                        guard visibleHeight > 0 else { return false }
                        return totalHeight > visibleHeight + parent.config.overflowTolerance
                }
            }

            private func syncDocumentSize(totalHeight: CGFloat) {
                guard let documentView, let scrollView else { return }

                let visibleSize = scrollView.contentSize
                let width = max(1, visibleSize.width)
                let height = max(totalHeight, visibleSize.height)
                documentView.textContentHeight = max(
                    0,
                    totalHeight - documentView.textInsets.top - documentView.textInsets.bottom
                )
                let targetSize = NSSize(width: width, height: height)
                guard documentView.frame.size != targetSize else {
                    documentView.needsLayout = true
                    return
                }
                documentView.setFrameSize(targetSize)
            }

            private func measuredAttributedString(in textView: AutoGrowNSTextView) -> NSAttributedString {
                let attributed = textView.attributedString()
                guard attributed.length == 0 else { return attributed }

                let font = textView.font ?? parent.config.font.appKitFont
                return NSAttributedString(string: " ", attributes: [.font: font])
            }

            private func measuredTextWidth(in textView: AutoGrowNSTextView) -> CGFloat {
                let lineFragmentPadding = (textView.textContainer?.lineFragmentPadding ?? 0) * 2
                let textContainerWidth = measuredTextContainerWidth(in: textView)
                if textContainerWidth > 0 {
                    return max(1, textContainerWidth - lineFragmentPadding)
                }

                let containerWidth = [
                    textView.enclosingScrollView?.contentSize.width ?? 0,
                    textView.bounds.width
                ]
                .first { $0 > 0 } ?? 1
                let horizontalInset = textView.textContainerInset.width * 2
                let edgeInset = (documentView?.textInsets.left ?? 0) + (documentView?.textInsets.right ?? 0)
                return max(1, containerWidth - edgeInset - horizontalInset - lineFragmentPadding)
            }

            private func measuredTextContainerWidth(in textView: AutoGrowNSTextView) -> CGFloat {
                guard let width = textView.textContainer?.containerSize.width,
                      width.isFinite,
                      width < CGFloat.greatestFiniteMagnitude / 2 else {
                    return 0
                }
                return width
            }

            private func resetScrollPositionToTop() {
                guard let scrollView,
                      let documentView = scrollView.documentView
                else { return }

                let clipView = scrollView.contentView
                let targetY: CGFloat
                if documentView.isFlipped {
                    targetY = 0
                } else {
                    targetY = max(0, documentView.bounds.height - clipView.bounds.height)
                }
                let targetOrigin = NSPoint(x: 0, y: targetY)
                guard clipView.bounds.origin != targetOrigin else { return }
                clipView.scroll(to: targetOrigin)
                scrollView.reflectScrolledClipView(clipView)
            }
        }
    }
}

final class AutoGrowNSTextView: NSTextView {
    fileprivate weak var coordinator: TextArea.Representable.Coordinator?
    weak var controller: TextAreaController?
    var userKeyDownHandler: TextFieldKeyDownEventHandler?
    var submitOnReturn: (() -> Void)?
    var submitOnReturnSources: TextAreaReturnSubmitSources = .all
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
           !event.modifierFlags.contains(.shift),
           submitOnReturnSources.contains(.hardwareKeyboard) {
            submitOnReturn()
            return
        }
        if let handler = userKeyDownHandler {
            if handler(event) == nil { return }
        }
        super.keyDown(with: event)
    }

    override func scrollRangeToVisible(_ range: NSRange) {
        guard coordinator?.isOverflowing == true else { return }

        let textLength = (string as NSString).length
        guard range.location <= textLength else { return }

        let safeRange = NSRange(
            location: range.location,
            length: min(range.length, max(0, textLength - range.location))
        )
        super.scrollRangeToVisible(safeRange)
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
        textStorage.addAttribute(
            .font,
            value: coordinator?.parent.config.font.appKitFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize),
            range: range
        )
        textStorage.endEditing()
        // Also keep typingAttributes dynamic so the next character the user
        // types after a formatted paste isn't locked to the source colour.
        var typing = self.typingAttributes
        typing[.foregroundColor] = NSColor.labelColor
        typing[.font] = coordinator?.parent.config.font.appKitFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
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
