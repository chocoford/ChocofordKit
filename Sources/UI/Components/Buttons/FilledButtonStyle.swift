//
//  FilledButtonStyle.swift
//  SwiftyTrickle
//
//  Created by Dove Zachary on 2023/8/17.
//

import SwiftUI


public struct FilledButtonStyle: PrimitiveButtonStyle {
    var size: ButtonSize
    var color: Color
    var block: Bool
    var loading: Bool
    var square: Bool
    var shape: ButtonShape
    
    public init(
        size: ButtonSize = .normal,
        color: Color = .accentColor,
        block: Bool = false,
        loading: Bool = false,
        square: Bool = false,
        shape: ButtonShape = .automatic
    ) {
        self.size = size
        self.color = color
        self.block = block
        self.loading = loading
        self.square = square
        self.shape = shape
    }
    
    private struct FilledButtonStyleView<V: View>: View {
        @Environment(\.isEnabled) private var isEnabled: Bool

        @State private var hovering = false
        var isPressed: Bool
        
        var size: ButtonSize = .normal
        var bgColor: Color = .accentColor
        var block = false
        var square = false
        var shape: ButtonShape
        
        let content: () -> V
        
        var body: some View {
            HStack {
                if block {
                    Spacer()
                }
                content()
                if block {
                    Spacer()
                }
            }
            .buttonSized(size, square: self.square)
            .foregroundColor(Color.white)
            .background(
                buttonShape(shape)
                    .fill(isEnabled ? self.bgColor : Color.gray)
                    .brightness(isPressed ? -0.1 : hovering ? -0.05 : 0.0)
            )
            .animation(.easeOut(duration: 0.2), value: hovering)
            .onHover { over in
                guard isEnabled else {return}
                self.hovering = over
            }
        }
    }
    
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
            FilledButtonStyleView(isPressed: isPressed, size: size, bgColor: self.color, block: block, square: square, shape: shape) {
                LoadableButtonStyleView(loading: loading, color: .white) {
                    configuration.label
                }
            }
        }
    }
}

extension PrimitiveButtonStyle where Self == FilledButtonStyle {
    public static var fill: FilledButtonStyle {
        FilledButtonStyle()
    }
    
    public static func fill(
        size: ButtonSize = .normal,
        color: Color = .accentColor,
        block: Bool = false,
        loading: Bool = false,
        square: Bool = false,
        shape: ButtonShape = .automatic
    ) -> FilledButtonStyle {
        FilledButtonStyle(
            size: size,
            color: color,
            block: block,
            loading: loading,
            square: square,
            shape: shape
        )
    }
}

#if DEBUG
struct FilledButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button {
            
        } label: {
            Text("Button")
        }
        .buttonStyle(.fill)
    }
}
#endif


