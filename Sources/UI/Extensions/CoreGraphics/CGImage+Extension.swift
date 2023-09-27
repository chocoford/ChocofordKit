//
//  CGImage+Extension.swift
//
//
//  Created by Dove Zachary on 2023/9/27.
//

#if canImport(SwiftUI)
import SwiftUI

extension CGImage {
    public static func createFormData(_ data: Data) -> CGImage? {
        if let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
            return cgImage
        }
        return nil
    }
    
    public static func createFormURL(_ url: URL) -> CGImage? {
        if let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
            return cgImage
        }
        return nil
    }
    
    public static func createFormURLs<T>(_ urls: T) -> [CGImage] where T: Sequence, T.Element == URL {
        urls.compactMap { url in
            if let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                let cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil) {
                return cgImage
            }
            return nil
        }
    }
}

#endif
