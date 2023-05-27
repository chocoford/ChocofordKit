//
//  Edge+Extension.swift
//  
//
//  Created by Chocoford on 2023/4/21.
//

import SwiftUI

extension Edge {
    var opppsite: Edge {
        switch self {
            case .top:
                return .bottom
            case .leading:
                return .trailing
            case .bottom:
                return .top
            case .trailing:
                return .leading
        }
    }
}
