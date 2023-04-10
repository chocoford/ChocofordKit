//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/3/30.
//

import SwiftUI

public struct ButtonColor {
    var `default`: Color
    var hovered: Color
    var pressed: Color
    
    public init(`default`: Color, hovered: Color, pressed: Color) {
        self.`default` = `default`
        self.hovered = hovered
        self.pressed = pressed
    }
}

public enum ButtonSize: CaseIterable {
    case small, normal, large
}


internal extension View {
    @ViewBuilder
    func buttonSized(_ size: ButtonSize) -> some View {
        switch size {
            case .large:
                padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    
            case .normal:
                padding(.vertical, 8)
                    .padding(.horizontal, 12)
                
            case .small:
                padding(.vertical, 4)
                    .padding(.horizontal, 10)
              
        }
    }
    
//    @ViewBuilder
//    func buttonBorderRadius() -> some View {
//        switch size {
//            case .large:
//                padding(.vertical, 10)
//                    .padding(.horizontal, 16)
//                    
//            case .normal:
//                padding(.vertical, 8)
//                    .padding(.horizontal, 12)
//                
//            case .small:
//                padding(.vertical, 4)
//                    .padding(.horizontal, 10)
//              
//        }
//    }
}
