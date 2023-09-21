//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/16.
//

import SwiftUI


/// A container makes content centered.
/// All elements are vertically aligned.
public struct Center<Content: View>: View {
    var axes: Axis.Set
    var content: () -> Content

    public init(
        _ axes: Axis.Set = [.vertical, .horizontal],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axes = axes
        self.content = content
    }
    
    public var body: some View {
        switch self.axes {
            case .horizontal:
                HStack {
                    Spacer(minLength: 0)
                    VStack {
                        content()
                    }
                    Spacer(minLength: 0)
                }
            case .vertical:
                VStack {
                    Spacer(minLength: 0)
                    content()
                    Spacer(minLength: 0)
                }
            default:
                HStack {
                    Spacer(minLength: 0)
                    VStack {
                        Spacer(minLength: 0)
                        content()
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }
        }
        
    }
}

#if DEBUG
struct Center_Previews: PreviewProvider {
    static var previews: some View {
        Center{ }
    }
}
#endif
