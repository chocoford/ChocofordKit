//
//  TextAreaPaste.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2026/05/06.
//

import SwiftUI
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#endif

// MARK: - PasteItem

/// A single classified item read from the system pasteboard.
///
/// Extraction is best-effort: rich-text / HTML degrade to `.text(plain)`;
/// formats not covered explicitly fall into `.unknown`.
public enum TextAreaPasteItem {
    case text(String)
    case image(PlatformImage)
    case fileURL(URL)
    case url(URL)
    case unknown(Data, type: String)
}

#if canImport(AppKit)
extension TextAreaPasteItem {
    static func items(from pasteboard: NSPasteboard) -> [TextAreaPasteItem] {
        pasteboard.pasteboardItems?.compactMap { TextAreaPasteItem(from: $0) } ?? []
    }

    /// Classify a single `NSPasteboardItem` in priority order:
    /// image > fileURL > url > text > unknown.
    init?(from pbItem: NSPasteboardItem) {
        // Image
        let imageTypes: [NSPasteboard.PasteboardType] = [.tiff, .png]
        for type in imageTypes {
            if let data = pbItem.data(forType: type), let image = NSImage(data: data) {
                self = .image(image)
                return
            }
        }
        // File URL
        if let str = pbItem.string(forType: .fileURL),
           let url = URL(string: str), url.isFileURL {
            self = .fileURL(url)
            return
        }
        // Web URL
        if let str = pbItem.string(forType: .URL),
           let url = URL(string: str), !url.isFileURL {
            self = .url(url)
            return
        }
        // Plain text (rich text falls through here — NSPasteboard derives plain from rich)
        if let str = pbItem.string(forType: .string) {
            self = .text(str)
            return
        }
        // Unknown — capture first available type
        if let firstType = pbItem.types.first,
           let data = pbItem.data(forType: firstType) {
            self = .unknown(data, type: firstType.rawValue)
            return
        }
        return nil
    }
}
#endif

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
extension TextAreaPasteItem {
    static func items(from pasteboard: UIPasteboard) -> [TextAreaPasteItem] {
        if let image = pasteboard.image {
            return [.image(image)]
        }

        if let url = pasteboard.url {
            return [url.isFileURL ? .fileURL(url) : .url(url)]
        }

        if let string = pasteboard.string {
            return [.text(string)]
        }

        return pasteboard.items.compactMap { item in
            TextAreaPasteItem(from: item)
        }
    }

    init?(from pasteboardItem: [String: Any]) {
        for (typeIdentifier, value) in pasteboardItem {
            guard let type = UTType(typeIdentifier) else { continue }

            if type.conforms(to: .image) {
                if let image = value as? UIImage {
                    self = .image(image)
                    return
                }
                if let data = value as? Data, let image = UIImage(data: data) {
                    self = .image(image)
                    return
                }
            }

            if type.conforms(to: .fileURL),
               let url = Self.url(from: value),
               url.isFileURL {
                self = .fileURL(url)
                return
            }

            if type.conforms(to: .url),
               let url = Self.url(from: value) {
                self = url.isFileURL ? .fileURL(url) : .url(url)
                return
            }
        }

        for (typeIdentifier, value) in pasteboardItem {
            guard let data = value as? Data else { continue }
            self = .unknown(data, type: typeIdentifier)
            return
        }

        if let string = pasteboardItem.values.compactMap({ $0 as? String }).first {
            self = .text(string)
            return
        }

        return nil
    }

    private static func url(from value: Any) -> URL? {
        if let url = value as? URL {
            return url
        }
        if let url = value as? NSURL {
            return url as URL
        }
        if let data = value as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }
        if let string = value as? String {
            return URL(string: string)
        }
        return nil
    }
}
#endif

// MARK: - TextArea modifier

extension TextArea {
    /// Customizes how pasted content is inserted into the editor.
    ///
    /// The handler is called for each item on the pasteboard, in order.
    /// Return `nil` to fall back to default behaviour — plain text is
    /// inserted at the caret, other types are ignored. Return a
    /// ``TextAreaInsertion`` to take over.
    ///
    /// `.submenu` and `.dismiss` are no-ops in the paste context (they're
    /// only meaningful for trigger menus). Use `.text`, `.token`,
    /// `.action`, or `nil` for default.
    ///
    /// ```swift
    /// TextArea(text: $text, placeholder: Text("Drop an image…"))
    ///     .onPaste { item in
    ///         switch item {
    ///         case .image(let img):
    ///             return .token(ImageToken(image: img))
    ///         case .fileURL(let url):
    ///             return .action { upload(url) }
    ///         default:
    ///             return nil
    ///         }
    ///     }
    /// ```
    ///
    /// - Parameter handler: A closure receiving each pasteboard item.
    /// - Returns: A modified text area.
    @MainActor
    public func onPaste(
        _ handler: @escaping (TextAreaPasteItem) -> TextAreaInsertion?
    ) -> TextArea {
        self.config.pasteHandler = handler
        return self
    }
}
