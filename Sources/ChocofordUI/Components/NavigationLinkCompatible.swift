//
//  NavigationLinkCompatible.swift
//  
//
//  Created by Dove Zachary on 2023/3/1.
//

import SwiftUI

public struct NavigationLinkCompatible<P: Hashable, Title: View, Icon: View>: View {
    var value: P?
    var label: () -> Label<Title, Icon>
    var onClick: () -> Void
    
    public init(value: P?, label: @escaping () -> Label<Title, Icon>, onClick: @escaping () -> Void) where P : Hashable {
        self.value = value
        self.label = label
        self.onClick = onClick
    }
    
    public var body: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            NavigationLink(value: value, label: label)
        } else {
           label()
                .onTapGesture(perform: onClick)
        }
    }
}

//struct NavigationLinkCompatible_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationLinkCompatible()
//    }
//}
