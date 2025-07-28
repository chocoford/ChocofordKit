//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/4.
//

import SwiftUI

public struct ViewSizeReader<Content: View>: View {
    private struct SizeKey: PreferenceKey {
        static var defaultValue: CGSize { .zero }
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }

    let content: (CGSize) -> Content

    public init(@ViewBuilder content: @escaping (CGSize) -> Content) {
        self.content = content
    }
    
    var config = Config()
    
    @State private var size: CGSize = SizeKey.defaultValue
    
    public var body: some View {
        content(size)
            .background {
                GeometryReader { proxy in
                    ZStack {
                        if config.ignoreSafeArea {
                            Color.clear
                                .ignoresSafeArea()
                        } else {
                            Color.clear
                        }
                    }
                    .watchImmediately(of: proxy.size) { size = $0 }
                    .onChange(of: proxy.size) { newValue in
                        size = newValue
                    }
                }
            }
    }
    
    class Config {
        var ignoreSafeArea: Bool = false
    }
    
    public func ignoreSafeArea() -> Self {
        self.config.ignoreSafeArea = true
        return self
    }
}


public struct BindSizeModifier: ViewModifier {
    var width: Binding<CGFloat?>?
    var height: Binding<CGFloat?>?
    
    public init(
        width: Binding<CGFloat?>? = nil,
        height: Binding<CGFloat?>? = nil
    ) {
        self.width = width
        self.height = height
    }
    
    public init(
        width: Binding<CGFloat>? = nil,
        height: Binding<CGFloat>? = nil
    ) {
        self.width = width.map { Binding<CGFloat?>($0) }
        self.height = height.map { Binding<CGFloat?>($0) }
    }
    
    public func body(content: Content) -> some View {
        ViewSizeReader { size in
            if #available(iOS 17.0, macOS 14.0, *) {
                content
                    .onChange(of: size, initial: true) { _, size in
                        self.width?.wrappedValue = size.width
                        self.height?.wrappedValue = size.height
                    }
            } else {
                content
                    .onChange(of: size) { size in
                        self.width?.wrappedValue = size.width
                        self.height?.wrappedValue = size.height
                    }
            }
        }
    }
}

extension View {
    @MainActor @ViewBuilder
    public func readSize(_ size: Binding<CGSize>) -> some View {
        modifier(
            BindSizeModifier(
                width: Binding(
                    get: {
                        size.wrappedValue.width
                    },
                    set: { val in
                        size.wrappedValue.width = val
                    }
                ),
                height: Binding(
                    get: {
                        size.wrappedValue.height

                    },
                    set: { val in
                        size.wrappedValue.height = val
                    }
                )
            )
        )
    }
    
    @MainActor @ViewBuilder
    public func readWidth(_ width: Binding<CGFloat>) -> some View {
        modifier(
            BindSizeModifier(
                width: Binding(
                    get: {
                        width.wrappedValue
                    },
                    set: { val in
                        width.wrappedValue = val
                    }
                )
            )
        )
    }
    
    @MainActor @ViewBuilder
    public func readHeight(_ height: Binding<CGFloat>) -> some View {
        modifier(
            BindSizeModifier(
                height: Binding(
                    get: {
                        height.wrappedValue

                    },
                    set: { val in
                        height.wrappedValue = val
                    }
                )
            )
        )
    }
    
    
    @MainActor @ViewBuilder
    public func readSize(width: Binding<CGFloat?>, height: Binding<CGFloat?>) -> some View {
        modifier(
            BindSizeModifier(
                width: Binding(
                    get: {
                        width.wrappedValue
                    },
                    set: { val in
                        width.wrappedValue = val
                    }
                ),
                height: Binding(
                    get: {
                        height.wrappedValue

                    },
                    set: { val in
                        height.wrappedValue = val
                    }
                )
            )
        )
    }
    
    @MainActor @ViewBuilder
    public func readWidth(_ width: Binding<CGFloat?>) -> some View {
        modifier(
            BindSizeModifier(
                width: Binding(
                    get: {
                        width.wrappedValue
                    },
                    set: { val in
                        width.wrappedValue = val
                    }
                )
            )
        )
    }
    
    @MainActor @ViewBuilder
    public func readHeight(_ height: Binding<CGFloat?>) -> some View {
        modifier(
            BindSizeModifier(
                height: Binding(
                    get: {
                        height.wrappedValue

                    },
                    set: { val in
                        height.wrappedValue = val
                    }
                )
            )
        )
    }
}
