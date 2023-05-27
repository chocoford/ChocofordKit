//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/16.
//

import SwiftUI

public struct Center<Content: View>: View {
    var content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
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

#if DEBUG
struct Center_Previews: PreviewProvider {
    static var previews: some View {
        Center{ }
    }
}
#endif
