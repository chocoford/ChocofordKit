//
//  Alignment+Extension.swift
//  
//
//  Created by Chocoford on 2023/4/21.
//

import SwiftUI

extension Alignment {
    var opposite: Alignment {
        switch self {
            case .bottom:
                return .top
            case .bottomLeading:
                return .topTrailing
            case .bottomTrailing:
                return .topLeading
            case .center:
                return .center
            case .centerFirstTextBaseline:
                return .centerLastTextBaseline
            case .centerLastTextBaseline:
                return .centerFirstTextBaseline
            case .leading:
                return .trailing
            case .leadingFirstTextBaseline:
                return .leadingLastTextBaseline
            case .leadingLastTextBaseline:
                return .leadingFirstTextBaseline
            case .top:
                return .bottom
            case .topLeading:
                return .bottomTrailing
            case .topTrailing:
                return .bottomLeading
            case .trailing:
                return .leading
            case .trailingFirstTextBaseline:
                return .trailingLastTextBaseline
            case .trailingLastTextBaseline:
                return .trailingFirstTextBaseline
            default:
                return .center
        }
    }
}
