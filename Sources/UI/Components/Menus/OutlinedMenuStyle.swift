//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/9.
//

import SwiftUI

@available(*, deprecated)
struct OutlinedMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
        
    }
}

public struct OutlinedMenu<Content: View, Label: View>: View {

    var content: () -> Content
    var label: () -> Label
    
    var size: ButtonSize = .normal
    var block: Bool = false
    var square: Bool = false
    var color: Color = .secondary
    var loading: Bool = false
    
    public init(labelSize: ButtonSize = .normal,
                block: Bool = false,
                tile: Bool = false,
                color: Color = .secondary,
                loading: Bool = false,
                @ViewBuilder content: @escaping () -> Content,
                @ViewBuilder label: @escaping () -> Label) {
        self.size = labelSize
        self.block = block
        self.square = tile
        self.color = color
        self.loading = loading
        self.content = content
        self.label = label
    }
    
    
    public var body: some View {
        Menu {
            content()
        } label: {
            label()
                .outlinedStyle(size: size, block: block, square: square, color: color, loading: loading)
        }
        .plainStyle()
    }
}

public extension Menu {
    @ViewBuilder
    static func outlined<Content: View, Label: View>(labelSize: ButtonSize = .normal,
                         block: Bool = false,
                         tile: Bool = false,
                         color: Color = .secondary,
                         loading: Bool = false,
                         @ViewBuilder content: @escaping () -> Content,
                         @ViewBuilder label: @escaping () -> Label) -> OutlinedMenu<Content, Label> {
        OutlinedMenu(labelSize: labelSize,
                     block: block,
                     tile: tile,
                     color: color,
                     loading: loading,
                     content: content,
                     label: label)
    }
}

#if DEBUG
struct OutlinedMenuStyle_Previews: PreviewProvider {
    static var previews: some View {
        Menu {
            
        } label: {
            Text("Menu")
        }
    }
}

#endif
