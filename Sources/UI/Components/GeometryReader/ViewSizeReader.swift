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
