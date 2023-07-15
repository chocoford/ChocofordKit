//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/22.
//

import SwiftUI

public struct Hover<Content: View>: View {
    var animation: Animation?
    var content: (_ isHover: Bool) -> Content
    
    public init(animation: Animation? = nil,
                @ViewBuilder content: @escaping (_ isHover: Bool) -> Content) {
        self.animation = animation
        self.content = content
    }
    
    @State private var isHover: Bool = false
    
    public var body: some View {
        content(isHover)
            .onHover { hover in
                withAnimation(animation) {
                    self.isHover = hover
                }
            }
    }
}
