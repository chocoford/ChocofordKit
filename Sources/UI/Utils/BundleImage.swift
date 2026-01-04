//
//  BundleImage.swift
//  ChocofordKit
//
//  Created by Chocoford on 1/4/26.
//

import SwiftUI

extension Image {
    internal init(modulePath name: String, ofType ext: String?) {
#if canImport(AppKit)
        if let nsImage = NSImage(
            contentsOfFile: Bundle.module.path(forResource: name, ofType: ext)!
        ) {
            self.init(nsImage: nsImage)
        }
#elseif canImport(UIKit)
        if let uiImage = UIImage(
            contentsOfFile: Bundle.module.path(forResource: name, ofType: ext)!
        ) {
            self.init(uiImage: uiImage)
        }
#endif
        fatalError("Not supported")
    }
}
