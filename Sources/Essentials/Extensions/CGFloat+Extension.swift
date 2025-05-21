//
//  File.swift
//  
//
//  Created by Chocoford on 2023/5/1.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public extension CGFloat {
    #if os(iOS)
    static var safeArearTop: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        return (keyWindow?.safeAreaInsets.top) ?? 0
        
    }
    #endif
}
