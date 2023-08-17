//
//  FilledButtonStyle.swift
//  SwiftyTrickle
//
//  Created by Dove Zachary on 2023/8/17.
//

import SwiftUI
public struct FilledButtonStyle: ButtonStyle {
    var size: ButtonSize = .normal
    var block: Bool = false
    var loading: Bool = false
    var disabled: Bool = false
    var outlined: Bool = false
    
    private struct FilledButtonStyleView<V: View>: View {
        @Environment(\.isEnabled) private var isEnabled: Bool

        @State private var hovering = false
        var isPressed: Bool
        
        var size: ButtonSize = .normal
        var block = false
        var disabled = false

        let content: () -> V
        
        var bgColor: Color { return Color.accentColor }
        
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
            .buttonSized(size, square: false)
            .foregroundColor(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(disabled ? .gray : Color.accentColor)
                    .brightness(isPressed ? -0.1 : hovering ? -0.05 : 0.0)
            )
            .animation(.easeOut(duration: 0.2), value: hovering)
            .onHover { over in
                guard !disabled else {return}
                self.hovering = over
            }
        }
    }
    
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        FilledButtonStyleView(isPressed: configuration.isPressed, size: size, block: block, disabled: disabled) {
            LoadableButtonStyleView(loading: loading, color: .white) {
                configuration.label
            }
        }
    }
}


#if DEBUG
struct FilledButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button {
            
        } label: {
            Text("Button")
        }
        .buttonStyle(FilledButtonStyle())
    }
}
#endif


