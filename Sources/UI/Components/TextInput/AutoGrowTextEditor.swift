//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/27.
//

import SwiftUI

public struct AutoGrowTextEditor: View {
    @Binding var text: String
    var prompt: Text?
    
    @State private var height: CGFloat = .zero
    
    public init(text: Binding<String>, prompt: Text? = nil) {
        self._text = text
        self.prompt = prompt
    }
    
    public var body: some View {
        ZStack {
            TextEditor(text: $text)
                .frame(height: height)
            Text(text.isEmpty ? "1" : text)
                .padding(8)
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .watchImmediately(of: geometry.size) { newValue in
                                height = newValue.height
                            }
                    }
                }
                .opacity(0)
        }
        .overlay(alignment: .topLeading) {
            if text.isEmpty, let prompt = prompt {
                prompt
                    .foregroundColor(.secondary)
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
    }
}
