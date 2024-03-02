//
//  SpaceAround.swift
//
//
//  Created by Dove Zachary on 2023/12/27.
//

import SwiftUI

@available(macOS 13.0, iOS 16.0, *)
public struct SpaceAround: View {
    var content: AnyView
    
    public init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    public var body: some View {
        Grid(verticalSpacing: 0) {
            GridRow {
                self.content
            }
            Divider()
                .frame(height: 0)
                .opacity(0)
        }
    }
}
