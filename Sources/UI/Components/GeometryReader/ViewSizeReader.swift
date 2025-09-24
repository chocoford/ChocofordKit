//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/4.
//

import SwiftUI

struct ViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize { .zero }
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
    

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
    
    @State private var size: CGSize = .zero
    
    public var body: some View {
        content(size)
            .readSize($size)
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
        content
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .watchImmediately(of: geometry.size) { size in
                            if let width = width {
                                width.wrappedValue = size.width
                            }
                            if let height = height {
                                height.wrappedValue = size.height
                            }
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
