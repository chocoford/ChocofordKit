//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/4.
//

import SwiftUI
import ShapeBuilder


public enum ButtonShape {
    case automatic
    case capsule
    case roundedRectangle(cornerRadius: CGFloat = 8.0)
    case tile
}


@ShapeBuilder
internal func buttonShape(_ shape: ButtonShape) -> some Shape {
    switch shape {
        case .automatic:
            RoundedRectangle(cornerRadius: 8.0)
        case .capsule:
            Capsule()
        case .roundedRectangle(let cornerRadius):
            RoundedRectangle(cornerRadius: cornerRadius)
        case .tile:
            Rectangle()
    }
}
