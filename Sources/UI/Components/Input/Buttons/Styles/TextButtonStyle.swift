//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/4.
//

import SwiftUI
import ShapeBuilder

public struct TextButtonStyle: PrimitiveButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    var size: ButtonSize
//    var color: Color
    var block: Bool
    var loading: Bool
    var square: Bool
    var shape: ButtonShape
    
    public init(
        size: ButtonSize = .normal,
//        color: Color = .primary,
        block: Bool = false,
        loading: Bool = false,
        square: Bool = false,
        shape: ButtonShape = .automatic
    ) {
        self.size = size
//        self.color = color
        self.block = block
        self.loading = loading
        self.square = square
        self.shape = shape
    }
    
    private struct TextButtonStyleView<V: View>: View {
        @Environment(\.isEnabled) private var isEnabled: Bool

        @State private var hovering = false
        var isPressed: Bool
        
        var size: ButtonSize = .normal
//        var color: Color = Color.primary
        var block = false
        var square: Bool
        var shape: ButtonShape

        let content: () -> V
        
        var body: some View {
            container {
                if block {
                    Spacer(minLength: 0)
                }
                content()
                    .foregroundColor(isEnabled ? nil : .secondary)
                
                if block {
                    Spacer(minLength: 0)
                }
            }
            .buttonSized(size, square: self.square)
            .background {
                buttonShape(shape)
                    .fill(.foreground)
                    .opacity(!self.isEnabled ? 0 : self.isPressed ? 0.1 : self.hovering ? 0.15 : 0)
            }
            .animation(.easeOut(duration: 0.2), value: hovering)
            .onHover { over in
                guard isEnabled else { return }
                self.hovering = over
            }
        }
        
        @ViewBuilder
        func container<C: View>(@ViewBuilder content: @escaping () -> C) -> some View {
            if self.square {
                SquareContainer {
                    content()
                }
            } else {
                HStack {
                    content()
                }
            }
        }
      
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
            TextButtonStyleView(isPressed: isPressed, 
                                size: size,
//                                color: self.color,
                                block: block,
                                square: square, 
                                shape: shape) {
                LoadableButtonStyleView(loading: loading, color: .white) {
                    configuration.label
                }
            }
        }
    }
}

extension PrimitiveButtonStyle where Self == TextButtonStyle {
    public static var text: TextButtonStyle {
        TextButtonStyle()
    }
    
    public static func text(
        size: ButtonSize = .normal,
//        color: Color = .primary,
        block: Bool = false,
        loading: Bool = false,
        square: Bool = false,
        shape: ButtonShape = .automatic
    ) -> TextButtonStyle {
        TextButtonStyle(
            size: size,
//            color: color,
            block: block,
            loading: loading,
            square: square,
            shape: shape
        )
    }
}

#if DEBUG
struct TextButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button {
            
        } label: {
//            Text("Button")
            Image(systemSymbol: .xmark)
        }
        .buttonStyle(.text(square: true))
        .padding()
    }
}
#endif
