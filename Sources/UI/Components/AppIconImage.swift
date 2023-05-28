//
//  AppIconImage.swift
//  
//
//  Created by Chocoford on 2023/4/30.
//

import SwiftUI
#if os(macOS)
public let appIconImage = Image(nsImage: NSApp.applicationIconImage)

#elseif os(iOS)
public let appIconImage = Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
#endif
