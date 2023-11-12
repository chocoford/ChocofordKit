//
//  NSImage+Extension.swift
//  
//
//  Created by Dove Zachary on 2023/9/26.
//

#if canImport(AppKit)
import AppKit

extension NSImage {
    @MainActor
    public func byPreparingThumbnail(ofSize size: CGSize) async -> NSImage {
        let originalSize = self.size
        let fromRect = NSMakeRect(0, 0, originalSize.width, originalSize.height)
        let smallerImage = NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect, from: fromRect, operation: .copy, fraction: 1)
            return true
        }
        return smallerImage
    }
    
    @MainActor
    public func byPreparingThumbnail(width newWidth: CGFloat) async -> NSImage {
        let originalSize = self.size
        let aspectRatio = self.size.height / self.size.width
        let newHeight = newWidth * aspectRatio
        let fromRect = NSMakeRect(0, 0, originalSize.width, originalSize.height)
        let smallerImage = NSImage(
            size: CGSize(width: newWidth, height: newHeight),
            flipped: false
        ) { rect in
            self.draw(in: rect, from: fromRect, operation: .copy, fraction: 1)
            return true
        }
        return smallerImage
    }
    
    @MainActor
    public func byPreparingThumbnail(height newHeight: CGFloat) async -> NSImage {
        let originalSize = self.size
        let aspectRatio = self.size.height / self.size.width
        let newWidth = newHeight / aspectRatio
        let fromRect = NSMakeRect(0, 0, originalSize.width, originalSize.height)
        let smallerImage = NSImage(
            size: CGSize(width: newWidth, height: newHeight),
            flipped: false)
        { rect in
            self.draw(in: rect, from: fromRect, operation: .copy, fraction: 1)
            return true
        }
        return smallerImage
    }
    
    public var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    public func writePNGData(to url: URL, options: Data.WritingOptions = .atomic) throws {
        try pngData?.write(to: url, options: options)
    }
}
#endif
