//
//  LoadableButtonStyle.swift
//
//  Created by Chocoford on 2022/12/13.
//

import SwiftUI

public struct LoadableButtonStyleView<V: View>: View {
    var loading: Bool = false
    var color: Color = .white
    @State private var hovering = false
    
    let content: () -> V
    
    public init(loading: Bool = false, color: Color = .white, @ViewBuilder content: @escaping () -> V) {
        self.loading = loading
        self.color = color
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            content()
                .opacity(loading ? 0 : 1)
            if loading {
                CircularProgressView()
                    .size(14)
                    .stroke(color)
            }
        }
        .onHover { over in
            self.hovering = over
        }
    }
}


public struct LoadableButtonStyle: ButtonStyle {
    var loading: Bool = false
    var color: Color = .white
    
    public init(loading: Bool = false, color: Color = .white) {
        self.loading = loading
        self.color = color
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        LoadableButtonStyleView(loading: loading, color: color) {
            configuration.label
        }
    }
}
