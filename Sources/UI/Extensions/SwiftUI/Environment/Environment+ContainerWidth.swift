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

struct ContainerSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct WidthProxyModifier: ViewModifier {
    @State private var size: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .environment(\.containerSize, size)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ContainerSizePreferenceKey.self, value: size)
                        .onAppear {
                            print("geometry.size", geometry.size)
                            size = geometry.size
                        }
                }
            }
            .onPreferenceChange(ContainerSizePreferenceKey.self) { newSize in
                print("onPreferenceChange", newSize)
                size = newSize
            }
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

#Preview {
    VStack {
        Color.red
    }
    .withContainerSize()
}
