//
//  LoadableButtonStyle.swift
//
//  Created by Dove Zachary on 2022/12/13.
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
