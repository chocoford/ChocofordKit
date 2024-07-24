//
//  CGImage+Extension.swift
//
//
//  Created by Dove Zachary on 2023/9/27.
//

import Foundation
#if canImport(CoreImage) && canImport(UniformTypeIdentifiers)
import CoreImage
import UniformTypeIdentifiers

extension CGImage {
    public static func createFromData(_ data: Data) -> CGImage? {
        if let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
            return cgImage
        }
        return nil
    }
    
    public static func createFromURL(_ url: URL) -> CGImage? {
        if let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
            return cgImage
        }
        return nil
    }
    
    public static func createFromURLs<T>(_ urls: T) -> [CGImage] where T: Sequence, T.Element == URL {
        urls.compactMap { url in
            if let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
                return cgImage
            }
            return nil
        }
    }
    
    
    public static func createThumbnail(from data: Data, size: CGFloat) -> CGImage? {
        if let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(
            cgImageSource,
            0,
            [
                kCGImageSourceCreateThumbnailFromImageIfAbsent : true,
                kCGImageSourceThumbnailMaxPixelSize: size
            ] as CFDictionary
           ) {
            return cgImage
        }
        return nil
    }
    
    public static func createThumbnail(from url: URL, size: CGFloat) -> CGImage? {
        if let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(cgImageSource, 0, [
            kCGImageSourceCreateThumbnailFromImageIfAbsent : true,
            kCGImageSourceThumbnailMaxPixelSize: size
         ] as CFDictionary) {
            return cgImage
        }
        return nil
    }
    
    
    @discardableResult
    public func saveTo(_ url: URL, properties: [String : Any]? = nil) throws -> Self {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            (UTType(filenameExtension: url.pathExtension) ?? .jpeg).identifier as CFString,
            1,
            nil
        ) else {
            struct CGImageDestinationCreateFailed: Error {}
            throw CGImageDestinationCreateFailed()
        }
        CGImageDestinationAddImage(
            destination,
            self,
            properties as CFDictionary?
        )
        
        guard CGImageDestinationFinalize(destination) else {
            struct CGImageDestinationFinalizeFailed: Error {}
            throw CGImageDestinationFinalizeFailed()
        }
        
        return self
    }

}

#endif
