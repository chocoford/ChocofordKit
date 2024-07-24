//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/18.
//

import SwiftUI

struct ContainerSizeKey: EnvironmentKey {
    static var defaultValue: CGSize = .zero
}

public extension EnvironmentValues {
    var containerSize: CGSize {
        get { self[ContainerSizeKey.self] }
        set { self[ContainerSizeKey.self] = newValue }
    }
}


public extension View {
    @ViewBuilder
    func withContainerSize() -> some View {
        self
            .modifier(WidthProxyModifier())
    }
}

struct WidthProxyModifier: ViewModifier {
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geometry in
                    if #available(macOS 14.0, iOS 17.0, *) {
                        Color.clear
                            .onChange(of: geometry.size, initial: true) { oldValue, newValue in
                                size = newValue
                            }
                    } else {
                        Color.clear
                            .onChange(of: geometry.size) { newValue in
                                size = newValue
                            }
                            .onAppear {
                                size = geometry.size
                            }
                    }
                }
            }
            .environment(\.containerSize, size)
    }
}
