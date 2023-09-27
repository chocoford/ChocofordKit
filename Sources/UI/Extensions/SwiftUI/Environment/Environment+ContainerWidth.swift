//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/18.
//

import SwiftUI

struct ContainerWidthKey: EnvironmentKey {
    static var defaultValue: CGFloat = .zero
}

public extension EnvironmentValues {
    var containerWidth: CGFloat {
        get { self[ContainerWidthKey.self] }
        set { self[ContainerWidthKey.self] = newValue }
    }
}


public extension View {
    @ViewBuilder
    func injectContainerWidth() -> some View {
        self
            .modifier(WidthProxyModifier())
    }
}

struct WidthProxyModifier: ViewModifier {
    func body(content: Content) -> some View {
        SingleAxisGeometryReader(axis: .horizontal) { width in
            content
                .environment(\.containerWidth, width)
        }
    }
}
