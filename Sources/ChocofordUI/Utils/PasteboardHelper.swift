//
//  PasteboardHelper.swift
//  
//
//  Created by Chocoford on 2023/4/14.
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public final class PasteboardHelper {
    public static var general = PasteboardHelper()
}

#if os(macOS)
public extension PasteboardHelper {
    func setString(_ string: String) {
        NSPasteboard.general.setString(string, forType: .string)
    }
}
#elseif os(iOS)
public extension PasteboardHelper {
    func setString(_ string: String){
        UIPasteboard.general.string = string
    }
}
#endif
