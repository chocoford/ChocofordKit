//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/20.
//

import Foundation

#if canImport(UIKit)
import UIKit

public func resignAllFirstResponder() {
    UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil);
}

#elseif canImport(AppKit)
import AppKit

public func resignAllFirstResponder() {
    
}
#endif
