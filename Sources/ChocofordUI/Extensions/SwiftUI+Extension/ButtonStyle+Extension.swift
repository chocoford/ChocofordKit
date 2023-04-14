//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/4/13.
//

import SwiftUI

#if os(iOS)
public struct LinkButtonStyleView<V: View>: View {
    var isPressed: Bool
    
    let content: () -> V
    
    public init(isPressed: Bool, @ViewBuilder content: @escaping () -> V) {
        self.isPressed = isPressed
        self.content = content
    }
    
    public var body: some View {
        if #available(iOS 16.0, *) {
            content()
                .underline()
                .foregroundColor(.blue)
        } else {
            content()
                .overlay(
                    VStack {
                        Spacer(minLength: 0)
                        Rectangle().frame(height: 1)
                            .foregroundColor(.blue)
                    }
                        .allowsTightening(false)
                )
                .foregroundColor(.blue)
        }
    }
}

public struct LinkButtonStyle: PrimitiveButtonStyle {
    public func makeBody(configuration: Self.Configuration) -> some View {
        LinkButtonStyleView(isPressed: false) {
            configuration.label
        }
    }
}

extension PrimitiveButtonStyle where Self == LinkButtonStyle {
    public static var linkStyle: LinkButtonStyle {
        LinkButtonStyle()
    }
}
#elseif os(macOS)
extension PrimitiveButtonStyle where Self == LinkButtonStyle {
    public static var linkStyle: LinkButtonStyle {
        .link
    }
}
#endif
