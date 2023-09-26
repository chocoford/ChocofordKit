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
    public func byPreparingThumbnail(ofSize size: CGSize) async -> NSImage? {
        let originalSize = self.size
        let fromRect = NSMakeRect(0, 0, originalSize.width, originalSize.height)
        let smallerImage = NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect, from: fromRect, operation: .copy, fraction: 1)
            return true
        }
        return smallerImage
    }
}
#endif
