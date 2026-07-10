//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/22.
//

import SwiftUI

public struct Hover<Content: View>: View {
    var animationIn: Animation?
    var animationOut: Animation?
    var content: (_ isHover: Bool) -> Content
    
    public init(animation: Animation? = nil,
                @ViewBuilder content: @escaping (_ isHover: Bool) -> Content) {
        self.animationIn = animation
        self.animationOut = animation
        self.content = content
    }
    
    public init(animationIn: Animation? = nil,
                animationOut: Animation? = nil,
                @ViewBuilder content: @escaping (_ isHover: Bool) -> Content) {
        self.animationIn = animationIn
        self.animationOut = animationOut
        self.content = content
    }
    
    @State private var isHover: Bool = false
    
    public var body: some View {
        content(isHover)
            .onHover { hover in
                if hover {
                    withAnimation(animationIn) {
                        self.isHover = hover
                    }
                } else {
                    withAnimation(animationOut) {
                        self.isHover = hover
                    }
                }
            }
    }
}
