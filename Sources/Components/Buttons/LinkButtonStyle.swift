//
//  LinkButtonStyleView.swift
//  
//
//  Created by Chocoford on 2023/4/27.
//

import SwiftUI

public struct LinkButtonStyleView<V: View>: View {
    var isPressed: Bool
    
    let content: () -> V
    
    @State private var isHover: Bool = false
    
    public init(isPressed: Bool, @ViewBuilder content: @escaping () -> V) {
        self.isPressed = isPressed
        self.content = content
    }
    
    public var body: some View {
        compatibleView()
            .contentShape(Rectangle())
            .onHover { hover in
                isHover = hover
            }
            .brightness(isPressed ? 0.3 : 0)
    }
    
    @ViewBuilder
    private func compatibleView() -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            content()
                .underline(isHover)
#if os(iOS)
                .foregroundColor(.accentColor)
#elseif os(macOS)
                .foregroundColor(.blue)
#endif
        } else {
            content()
                .overlay(
                    isHover ?
                    VStack {
                        Spacer(minLength: 0)
                        Rectangle().frame(height: 1)
                        #if os(iOS)
                            .foregroundColor(.accentColor)
                        #elseif os(macOS)
                            .foregroundColor(.blue)
                        #endif
                    }
                        .allowsTightening(false)
                    :
                        nil
                )
                .foregroundColor(.blue)
        }
    }
}

public struct CustomLinkButtonStyle: PrimitiveButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        LinkButtonStyleView(isPressed: false) {
            configuration.label
        }
    }
}

public struct LinkStyle: PrimitiveButtonStyle {
    
    public init() {}
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
            LinkButtonStyleView(isPressed: isPressed) {
                configuration.label
            }
        }
        
    }
}
