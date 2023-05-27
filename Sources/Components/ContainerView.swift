//
//  ContainerView.swift
//  
//
//  Created by Chocoford on 2023/3/26.
//

import SwiftUI

public protocol ContainerView: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}

extension ContainerView {
    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(content: content)
    }
}
