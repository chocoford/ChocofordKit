//
//  Image+Extension.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/20.
//

import SwiftUI

extension Image {
    public init?(base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        
#if os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        self = Image(nsImage: nsImage)
#elseif os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
#endif
    }
    
    public init?(data: Data) {
#if os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        self = Image(nsImage: nsImage)
#elseif os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
#endif
    }
}
