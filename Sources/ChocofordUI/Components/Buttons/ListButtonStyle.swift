//
//  ListButtonStyle.swift
//  ChocofordUI
//
//  Created by Chocoford on 2023/3/27.
//

import SwiftUI

public struct ListButtonStyle: ButtonStyle {
    var showIndicator = false
    var selected: Bool = false

    public init(showIndicator: Bool = false, selected: Bool = false) {
        self.showIndicator = showIndicator
        self.selected = selected
    }
    
    private struct ListButtonStyleView<V: View>: View {
        var isPressed: Bool
        var showIndicator: Bool
        var selected: Bool

        let content: () -> V

        @State private var isHover = false

        var body: some View {
            HStack {
                content()
                Spacer()
#if os(iOS)
                if showIndicator {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
#endif
            }
            .contentShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(selected ? .accentColor.opacity(0.2) : .gray.opacity(0.2))
                    .opacity(isHover || selected ? 1 : 0)
            )
            .containerShape(RoundedRectangle(cornerRadius: 8))
            .onHover { hover in withAnimation(.easeIn(duration: 0.2)) { isHover = hover } }
        }
    }
    
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        ListButtonStyleView(isPressed: configuration.isPressed,
                            showIndicator: showIndicator,
                            selected: selected) {
            configuration.label
        }
    }
}
