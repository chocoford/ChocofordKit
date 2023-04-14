//
//  SecondaryButtonStyle.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import SwiftUI

public struct OutlinedButtonStyle: ButtonStyle {
    var colors: ButtonColor
    var size: ButtonSize = .normal
    var block: Bool = false
    var square: Bool = false

    public func makeBody(configuration: Self.Configuration) -> some View {
        OutlinedButtonStyleView(isPressed: configuration.isPressed, colors: colors, size: size, block: block) {
            configuration.label
        }
    }
}

public struct OutlinedButtonStyleView<V: View>: View {
    @State private var hovering = false
    var isPressed: Bool
    
    var colors: ButtonColor
    var size: ButtonSize = .normal
    var block = false
    var square = false
    
    let content: () -> V
    
    public init(hovering: Bool = false, isPressed: Bool, colors: ButtonColor, size: ButtonSize, block: Bool = false, square: Bool = false,
                @ViewBuilder content: @escaping () -> V) {
        self.hovering = hovering
        self.isPressed = isPressed
        self.colors = colors
        self.size = size
        self.block = block
        self.square = square
        self.content = content
    }
    
    public var body: some View {
        HStack {
            if block {
                Spacer(minLength: 0)
            }
            content()
            if block {
                Spacer(minLength: 0)
            }
        }
        .buttonSized(size, square: square)
        .background(isPressed ? colors.pressed : hovering ? colors.hovered : .clear)
        .foregroundColor(colors.default)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colors.default)
        )
        .containerShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.2), value: hovering)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .onHover { over in
            self.hovering = over
        }
    }
}

extension ButtonStyle {
//    public var outlined
}

#if DEBUG
struct OutlinedButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ForEach(ButtonSize.allCases, id: \.self) { size in
                Button {} label: {
                    Text("Hello, world!")
                }
                .buttonStyle(OutlinedButtonStyle(colors: .init(default: .red,
                                                               hovered: .green,
                                                               pressed: .blue),
                                                 size: size))
            }
        }
       
        .padding()
    }
}
#endif
