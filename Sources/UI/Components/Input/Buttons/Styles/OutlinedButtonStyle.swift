//
//  SecondaryButtonStyle.swift
//  CSWang
//
//  Created by Chocoford on 2022/12/10.
//

#if canImport(SwiftUI)
import SwiftUI

public struct OutlinedButtonStyle: PrimitiveButtonStyle {
    var colors: ButtonColor
    var size: ButtonSize = .normal
    var block: Bool = false
    var square: Bool = false

    public init(
        colors: ButtonColor = .init(
            default: .accentColor,
            hovered: .accentColor.opacity(0.5),
            pressed: .accentColor.opacity(0.1)
        ),
        size: ButtonSize = .normal,
        block: Bool = false,
        square: Bool = false
    ) {
        self.colors = colors
        self.size = size
        self.block = block
        self.square = square
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
            OutlinedButtonStyleView(isPressed: isPressed, colors: colors, size: size, block: block) {
                configuration.label
            }
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
                .padding(.horizontal, 1)
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

extension PrimitiveButtonStyle where Self == OutlinedButtonStyle {
    public static var outlined: OutlinedButtonStyle {
        OutlinedButtonStyle()
    }
    
    public static func outlined(
        colors: ButtonColor = .init(
            default: .accentColor,
            hovered: .accentColor.opacity(0.5),
            pressed: .accentColor.opacity(0.1)
        ),
        size: ButtonSize = .normal,
        block: Bool = false,
        square: Bool = false
    ) -> OutlinedButtonStyle {
        OutlinedButtonStyle(
            colors: colors,
            size: size,
            block: block,
            square: square
        )
    }
}

public struct OutlinedMenuButtonStyle: MenuStyle {
    var colors: ButtonColor
    var size: ButtonSize = .normal
    var block: Bool = false
    var square: Bool = false
    
    public func makeBody(configuration: Configuration) -> some View {
        OutlinedButtonStyleView(isPressed: false, colors: colors, size: size, block: block) {
            
        }
    }
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

#endif
