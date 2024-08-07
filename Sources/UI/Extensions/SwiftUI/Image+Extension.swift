//
//  Image+Extension.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/20.
//

#if canImport(SwiftUI)
import SwiftUI

extension Image {
    public init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        
#if canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        self = Image(nsImage: nsImage)
#elseif canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
#endif
    }
    
    public init?(data: Data) {
#if canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        self = Image(nsImage: nsImage)
#elseif canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
#endif
    }
    
    public init(contentsOf url: URL) throws {
        struct InvalidURLError: Error {}
        
        guard let image = Image(data: try Data(contentsOf: url)) else {
            throw InvalidURLError()
        }
        self = image
    }
    
#if canImport(AppKit)
    public init(platformImage: NSImage) {
        self.init(nsImage: platformImage)
    }
#elseif canImport(UIKit)
    public init(platformImage: UIImage) {
        self.init(uiImage: platformImage)
    }
#endif
    
    public init(cgImage: CGImage, size: CGSize = .zero) {
#if canImport(AppKit)
        let image = NSImage(cgImage: cgImage, size: size)
        self.init(nsImage: image)
#elseif canImport(UIKit)
        let image = UIImage(cgImage: cgImage)
        self.init(uiImage: image)
#endif
    }
}
#endif


