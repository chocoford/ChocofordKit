//
//  FilledButtonStyle.swift
//  SwiftyTrickle
//
//  Created by Dove Zachary on 2023/8/17.
//

#if canImport(SwiftUI)

import SwiftUI

public struct FilledButtonStyle: PrimitiveButtonStyle {
    var size: ButtonSize
    var style: AnyShapeStyle
    var block: Bool
    var loading: Bool
    var square: Bool
    var shape: ButtonShape
    
    public init<S: ShapeStyle>(
        size: ButtonSize = .normal,
        style: S = Color.accentColor,
        block: Bool = false,
        loading: Bool = false,
        square: Bool = false,
        shape: ButtonShape = .automatic
    ) {
        self.size = size
        self.style = AnyShapeStyle(style)
        self.block = block
        self.loading = loading
        self.square = square
        self.shape = shape
    }
    
    private struct FilledButtonStyleView<V: View, S: ShapeStyle>: View {
        @Environment(\.isEnabled) private var isEnabled: Bool

        @State private var isHovered = false
        var isPressed: Bool
        
        var size: ButtonSize = .normal
        var backgroundStyle: S
        var block = false
        var square = false
        var shape: ButtonShape
        
        let content: () -> V
        
        init(
            isPressed: Bool,
            size: ButtonSize,
            backgroundStyle: S,
            block: Bool = false,
            square: Bool = false,
            shape: ButtonShape,
            @ViewBuilder content: @escaping () -> V
        ) {
            self.isPressed = isPressed
            self.size = size
            self.backgroundStyle = backgroundStyle
            self.block = block
            self.square = square
            self.shape = shape
            self.content = content
        }
        
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
                    .fill(isEnabled ? AnyShapeStyle(self.backgroundStyle) : AnyShapeStyle(Color.gray))
                    .brightness(isPressed ? -0.1 : isHovered ? -0.05 : 0.0)
            )
            .animation(.easeOut(duration: 0.2), value: isHovered)
            .onHover { hover in
                guard isEnabled else { return }
                self.isHovered = hover
            }
        }
    }
    
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
            FilledButtonStyleView(
                isPressed: isPressed,
                size: size,
                backgroundStyle: self.style,
                block: block,
                square: square,
                shape: shape
            ) {
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
    
    public static func fill<S: ShapeStyle>(
        size: ButtonSize = .normal,
        style: S = Color.accentColor,
        block: Bool = false,
        loading: Bool = false,
        square: Bool = false,
        shape: ButtonShape = .automatic
    ) -> FilledButtonStyle {
        FilledButtonStyle(
            size: size,
            style: style,
            block: block,
            loading: loading,
            square: square,
            shape: shape
        )
    }
}

#if DEBUG
struct FillButtonView: View {
    @State private var isLoading = false
    var body: some View {
        Button {
            isLoading = true
        } label: {
            Text("Button")
        }
        .buttonStyle(.fill(loading: isLoading, shape: .roundedRectangle(cornerRadius: 4)))
    }
}

struct FilledButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        FillButtonView()
            .padding()
    }
}
#endif


#endif
