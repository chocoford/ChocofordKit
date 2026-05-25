//
//  TextAreaAttachment.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2026/05/06.
//

import SwiftUI

#if canImport(AppKit)
import AppKit

// MARK: - TokenAttachment

final class TokenAttachment: NSTextAttachment {
    let token: AnyTextAreaToken

    init(token: AnyTextAreaToken) {
        self.token = token
        super.init(data: nil, ofType: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewProvider(
        for parentView: NSView?,
        location: NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        // Layout always runs on the main actor; NSHostingView/SwiftUI inside
        // the provider require it.
        MainActor.assumeIsolated {
            TokenViewProvider(
                token: token,
                textAttachment: self,
                parentView: parentView,
                textLayoutManager: textContainer?.textLayoutManager,
                location: location
            )
        }
    }
}

// MARK: - TokenViewProvider

@MainActor
final class TokenViewProvider: NSTextAttachmentViewProvider {
    let token: AnyTextAreaToken
    private var cachedSize: CGSize = .zero

    init(
        token: AnyTextAreaToken,
        textAttachment: NSTextAttachment,
        parentView: NSView?,
        textLayoutManager: NSTextLayoutManager?,
        location: NSTextLocation
    ) {
        self.token = token
        super.init(
            textAttachment: textAttachment,
            parentView: parentView,
            textLayoutManager: textLayoutManager,
            location: location
        )
        self.tracksTextAttachmentViewBounds = true
        // Pre-compute natural size so attachmentBounds returns something
        // useful even if loadView hasn't run yet.
        let controller = NSHostingController(rootView: token.body)
        cachedSize = controller.sizeThatFits(in: NSSize(width: 800, height: 200))
    }

    override func loadView() {
        let host = NSHostingView(rootView: token.body)
        host.translatesAutoresizingMaskIntoConstraints = true
        let size = host.fittingSize
        if size.width > 0, size.height > 0 {
            cachedSize = size
        }
        host.frame = CGRect(origin: .zero, size: cachedSize)
        view = host
    }

    override func attachmentBounds(
        for attributes: [NSAttributedString.Key: Any],
        location: NSTextLocation,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        let descent = (attributes[.font] as? NSFont)?.descender ?? -3
        return CGRect(
            x: 0,
            y: descent,
            width: max(cachedSize.width, 1),
            height: max(cachedSize.height, 1)
        )
    }
}

// MARK: - Helpers

extension NSAttributedString {
    /// Plain-text representation: text runs verbatim, attachments expanded
    /// to their token's `plainText` (instead of the U+FFFC placeholder).
    ///
    /// Fast-paths the common no-attachment case (just returns the underlying
    /// string), and walks by attribute run instead of per-character to keep
    /// per-keystroke cost low for long content.
    var textAreaPlainText: String {
        let s = self.string
        // Fast path: no attachments at all.
        if !s.contains("\u{FFFC}") { return s }

        let nsStr = s as NSString
        var result = ""
        result.reserveCapacity(nsStr.length)
        enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: nsStr.length),
            options: []
        ) { value, range, _ in
            if let attachment = value as? TokenAttachment {
                result += attachment.token.plainText
            } else {
                result += nsStr.substring(with: range)
            }
        }
        return result
    }
}

@MainActor
func makeTokenAttributedString(
    token: AnyTextAreaToken,
    font: NSFont
) -> NSAttributedString {
    let attachment = TokenAttachment(token: token)
    let str = NSMutableAttributedString(attachment: attachment)
    str.addAttribute(.font, value: font, range: NSRange(location: 0, length: str.length))
    return str
}
#endif
