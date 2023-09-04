//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/4.
//

import SwiftUI

struct SquareContainer<Content: View>: View {
    
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    @State private var maxSideLength: CGFloat = .zero
    
    var body: some View {
        Center {
            ViewSizeReader { size in
                content()
                    .onChange(of: size) { newValue in
                        maxSideLength = max(newValue.width, newValue.height)
                    }
            }
        }
        .frame(width: maxSideLength, height: maxSideLength)
    }
}


#if DEBUG
struct SquareContainer_Previews: PreviewProvider {
    static var previews: some View {
        Button {
            
        } label: {
//            Text("Button")
            Image(systemSymbol: .xmark)
        }
        .buttonStyle(.text(square: true, capsule: true))
        .padding()
    }
}
#endif
