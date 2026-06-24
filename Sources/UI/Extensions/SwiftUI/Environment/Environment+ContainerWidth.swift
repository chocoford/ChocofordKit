//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/18.
//

import SwiftUI

struct ContainerSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
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
            .overlay {
                GeometryReader { geometry in
                    let currentSize = geometry.size

                    Color.clear
                        .task(id: currentSize) {
                            await MainActor.run {
                                guard size != currentSize else { return }
                                size = currentSize
                            }
                        }
                }
                .allowsHitTesting(false)
                .opacity(0)
            }
            .environment(\.containerSize, size)
    }
}

public struct WithContainerSize<Content: View>: View {
    @Environment(\.containerSize) private var containerSize
    
    var content: (_ containerSize: CGSize) -> Content
    
    public init(
        @ViewBuilder content: @escaping (_ containerSize: CGSize) -> Content
    ) {
        self.content = content
    }
    
    public var body: some View {
        content(containerSize)
    }
}
