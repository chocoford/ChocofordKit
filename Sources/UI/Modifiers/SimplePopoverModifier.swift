//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/14.
//

import SwiftUI

struct SimplePopoverModifier<V: View>: ViewModifier {
    var arrowEdge: Edge = .top
    var popoverContent: () -> V
    
    @State private var showPopover: Bool = false
    
    func body(content: Content) -> some View {
        Button {
            showPopover.toggle()
        } label: {
            content
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showPopover, arrowEdge: arrowEdge) {
            popoverContent()
        }
    }
}

public extension View {
    @ViewBuilder
    func popover<V: View>(arrowEdge: Edge = .top,
                          @ViewBuilder content: @escaping () -> V) -> some View {
        self
            .modifier(SimplePopoverModifier(arrowEdge: arrowEdge, popoverContent: content))
    }
}
