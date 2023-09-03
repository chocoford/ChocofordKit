//
//  SingleAxisGeometryReader.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/22.
//

import SwiftUI

public struct SingleAxisGeometryReader<Content: View>: View {
    private struct SizeKey: PreferenceKey {
        static var defaultValue: CGFloat { 10 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    var axis: Axis = .horizontal
    var alignment: Alignment = .center
    let content: (CGFloat) -> Content

    public init(axis: Axis = .horizontal, alignment: Alignment = .center,
                @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.axis = axis
        self.alignment = alignment
        self.content = content
    }
    
    @State private var size: CGFloat = SizeKey.defaultValue
    
    public var body: some View {
        content(size)
            .frame(maxWidth:  axis == .horizontal ? .infinity : nil,
                   maxHeight: axis == .vertical   ? .infinity : nil,
                   alignment: alignment)
            .background(GeometryReader {
                proxy in
                Color.clear.preference(key: SizeKey.self, value: axis == .horizontal ? proxy.size.width : proxy.size.height)
            }).onPreferenceChange(SizeKey.self) { size = $0 }
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
    
    @State private var size: CGSize = SizeKey.defaultValue
    
    public var body: some View {
        content(size)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .watchImmediately(of: proxy.size) { size = $0 }
                        .preference(key: SizeKey.self, value: proxy.size)
                }
            }
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
}
