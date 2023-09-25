//
//  SingleAxisGeometryReader.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/22.
//

import SwiftUI

/// SingleAxisGeometryReader keeps the max width of its subview.
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
                Color.clear
                    .preference(key: SizeKey.self, value: axis == .horizontal ? proxy.size.width : proxy.size.height)
                    .onAppear { size = axis == .horizontal ? proxy.size.width : proxy.size.height }

            })
            .onPreferenceChange(SizeKey.self) { size = $0 }
    }
}
