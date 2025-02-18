//
//  NSImage+Extension.swift
//  
//
//  Created by Dove Zachary on 2023/9/26.
//

#if canImport(AppKit)
import AppKit

extension NSImage {
    public func preparingThumbnail(of size: CGSize, keepRatio: Bool = true) -> NSImage? {
        let start = Date()
        
        let originalSize: CGSize
        
        if keepRatio {
            originalSize = self.size 
        } else {
            originalSize = self.size
        }
        let fromRect = NSMakeRect(0, 0, originalSize.width, originalSize.height)
        let smallerImage = NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect, from: fromRect, operation: .copy, fraction: 1)
            return true
        }
        return smallerImage
    }
    
    public func preparingThumbnail(width newWidth: CGFloat) -> NSImage? {
        let originalSize = self.size
        let aspectRatio = self.size.height / self.size.width
        let newHeight = newWidth * aspectRatio
        return preparingThumbnail(of: CGSize(width: newWidth, height: newHeight))
    }
    
    public func preparingThumbnail(height newHeight: CGFloat) -> NSImage? {
        let originalSize = self.size
        let aspectRatio = self.size.height / self.size.width
        let newWidth = newHeight / aspectRatio
        return preparingThumbnail(of: CGSize(width: newWidth, height: newHeight))
    }
    
    static public func byPreparingThumbnail(from url: URL, height: CGFloat) -> NSImage? {
        guard let cgImage = CGImage.createThumbnail(from: url, size: height) else { return nil }
        return NSImage(cgImage: cgImage, size: .zero)
    }
    
    static public func byPreparingThumbnail(with data: Data, height: CGFloat) -> NSImage? {
        guard let cgImage = CGImage.createThumbnail(from: data, size: height) else { return nil }
        return NSImage(cgImage: cgImage, size: .zero)
    }
    
    
    public var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    public func writePNGData(to url: URL, options: Data.WritingOptions = .atomic) throws {
        try pngData?.write(to: url, options: options)
    }
}
#endif
