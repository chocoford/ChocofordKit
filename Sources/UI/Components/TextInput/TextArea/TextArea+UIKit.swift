//
//  TextArea+UIKit.swift
//  ChocofordKit
//
//  Created by Codex on 2026/06/08.
//

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import SwiftUI
import UIKit

extension TextArea {
    struct Representable: UIViewRepresentable {
        @Binding var text: String
        var config: Config
        var controller: TextAreaController
        @Binding var contentHeight: CGFloat
        @Binding var oneLineHeight: CGFloat
        @Binding var isComposing: Bool

        func makeUIView(context: Context) -> UITextView {
            // Default UITextView uses TextKit 1. We deliberately stay on it on
            // iOS: UITextView's TextKit 2 implementation has well-known layout
            // measurement issues (stale `usageBoundsForTextContainer`, fragment
            // enumeration quirks, trailing-empty-line miscounts). TextKit 1's
            // `usedRect + extraLineFragmentRect` is the canonical iOS auto-grow
            // pattern and is rock-stable.
            let textView = AutoGrowUITextView()
            textView.coordinator = context.coordinator
            textView.delegate = context.coordinator
            textView.font = .preferredFont(forTextStyle: .body)
            textView.backgroundColor = .clear
            textView.textColor = .label
            textView.tintColor = .label
            textView.textContainer.lineFragmentPadding = 0
            applyTextInsets(to: textView)
            // Start non-scrolling: lets the frame grow naturally with content.
            // We flip to scrolling once measured height exceeds maxHeight, see
            // recomputeHeight below.
            textView.isScrollEnabled = false
            textView.text = text

            context.coordinator.textView = textView
            controller.textView = textView
            controller.pasteHandler = config.pasteHandler

            DispatchQueue.main.async {
                context.coordinator.recomputeHeight()
            }
            return textView
        }

        func updateUIView(_ textView: UITextView, context: Context) {
            let maxHeightChanged = context.coordinator.parent.config.maxHeight != config.maxHeight
            context.coordinator.parent = self
            controller.pasteHandler = config.pasteHandler
            let didUpdateInsets = applyTextInsets(to: textView)
            // Skip while IME is composing — assigning `text` clears marked text.
            if textView.markedTextRange == nil && textView.text != text {
                textView.text = text
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
        private func applyTextInsets(to textView: UITextView) -> Bool {
            let insets = UIEdgeInsets(
                top: config.textInsets.top,
                left: config.textInsets.leading,
                bottom: config.textInsets.bottom,
                right: config.textInsets.trailing
            )

            var didChange = false
            if !UIEdgeInsetsEqualToEdgeInsets(textView.textContainerInset, insets) {
                textView.textContainerInset = insets
                didChange = true
            }
            if !UIEdgeInsetsEqualToEdgeInsets(textView.scrollIndicatorInsets, .zero) {
                textView.scrollIndicatorInsets = .zero
                didChange = true
            }
            return didChange
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        @MainActor
        final class Coordinator: NSObject, UITextViewDelegate {
            fileprivate var parent: Representable
            weak var textView: AutoGrowUITextView?
            private var lastIsSingleLine: Bool?

            fileprivate init(_ parent: Representable) {
                self.parent = parent
            }

            func textViewDidChange(_ textView: UITextView) {
                if textView.markedTextRange == nil && parent.text != textView.text {
                    parent.text = textView.text
                }
                recomputeComposing()
                textView.setNeedsLayout()
                textView.layoutIfNeeded()
                recomputeHeight()
                // Keep an async correction pass for UIKit cases where
                // `sizeThatFits` still resolves against stale text layout.
                scheduleRecomputeHeight()
            }

            func textViewDidChangeSelection(_ textView: UITextView) {
                recomputeComposing()
            }

            func recomputeHeight() {
                guard let textView else { return }

                // `sizeThatFits` is UIKit's own measurement API — it correctly
                // accounts for wrapping, trailing newlines and empty text. We
                // pin `isScrollEnabled` to false during measurement so the
                // value is a function of content alone and doesn't depend on
                // the (possibly-flipped) scrolling mode below.
                let wasScrollEnabled = textView.isScrollEnabled
                if wasScrollEnabled {
                    textView.isScrollEnabled = false
                }
                let width = textView.bounds.width > 0
                    ? textView.bounds.width
                    : UIScreen.main.bounds.width
                let size = textView.sizeThatFits(CGSize(
                    width: width,
                    height: .greatestFiniteMagnitude
                ))
                let height = ceil(size.height)
                let isSingleLine = isSingleVisualLine(in: textView)

                // Toggle internal scrolling: only enable once content exceeds
                // maxHeight so the frame can grow naturally below that.
                let isOverflowing = height > parent.config.maxHeight + parent.config.overflowTolerance
                if textView.isScrollEnabled != isOverflowing {
                    textView.isScrollEnabled = isOverflowing
                }
                if let binding = parent.config.linesOverflowBinding,
                   binding.wrappedValue != isOverflowing {
                    binding.wrappedValue = isOverflowing
                }

                if isSingleLine {
                    parent.oneLineHeight = height
                } else if parent.oneLineHeight <= 0 {
                    parent.oneLineHeight = estimatedSingleLineHeight(in: textView)
                }

                let oldHeight = parent.contentHeight
                if oldHeight != height {
                    parent.contentHeight = height
                }

                if lastIsSingleLine != isSingleLine {
                    lastIsSingleLine = isSingleLine
                    parent.config.onSingleLineChanged?(isSingleLine)
                }
            }

            func scheduleRecomputeHeight() {
                DispatchQueue.main.async { [weak self] in
                    self?.recomputeHeight()
                }
            }

            func recomputeComposing() {
                let composing = textView?.markedTextRange != nil
                if parent.isComposing != composing {
                    parent.isComposing = composing
                }
            }

            private func isSingleVisualLine(in textView: UITextView) -> Bool {
                if textView.text.hasSuffix("\n") {
                    return false
                }

                let layoutManager = textView.layoutManager
                let textContainer = textView.textContainer
                layoutManager.ensureLayout(for: textContainer)

                let glyphRange = layoutManager.glyphRange(for: textContainer)
                var lineCount = 0
                layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, _, stop in
                    lineCount += 1
                    if lineCount > 1 {
                        stop.pointee = true
                    }
                }

                return lineCount <= 1
            }

            private func estimatedSingleLineHeight(in textView: UITextView) -> CGFloat {
                let font = textView.font ?? .preferredFont(forTextStyle: .body)
                let verticalInsets = textView.textContainerInset.top + textView.textContainerInset.bottom
                return ceil(font.lineHeight + verticalInsets)
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

    override func paste(_ sender: Any?) {
        guard let controller = coordinator?.parent.controller,
              controller.pasteHandler != nil
        else {
            super.paste(sender)
            return
        }

        let items = TextAreaPasteItem.items(from: .general)
        guard !items.isEmpty else {
            super.paste(sender)
            return
        }

        if !controller.handlePaste(items) {
            super.paste(sender)
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)),
           coordinator?.parent.controller.pasteHandler != nil {
            let pasteboard = UIPasteboard.general
            return pasteboard.hasImages
                || pasteboard.hasURLs
                || pasteboard.hasStrings
                || !pasteboard.items.isEmpty
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
#endif
