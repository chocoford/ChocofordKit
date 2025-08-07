//
//  File.swift
//  
//
//  Created by Chocoford on 2023/3/30.
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
    case xsmall, small, normal, large
}


public extension View {
    @ViewBuilder
    func buttonSized(_ size: ButtonSize, square: Bool) -> some View {
        switch size {
            case .large:
                padding(.vertical, 10)
                    .padding(.horizontal,  square ? 10 : 16)
                    
            case .normal:
                padding(.vertical, 8)
                    .padding(.horizontal, square ? 8 : 12)
                
            case .small:
                padding(.vertical, 4)
                    .padding(.horizontal, square ? 4 : 10)
                
            case .xsmall:
                padding(.vertical, 0)
                    .padding(.horizontal, square ? 0 : 4)
              
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
