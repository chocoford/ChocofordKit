//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/27.
//

import SwiftUI

public struct LagacyAutoGrowTextEditor: View {
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

@available(macOS 15.0, iOS 15.0, *)
public struct AutoGrowTextEditor: View {
    @Binding var inputText: String
    var placeholder: Text
    
    
    public init(text: Binding<String>, placeholder: Text) {
        self._inputText = text
        self.placeholder = placeholder
    }
    
    var config: Config = Config()
    
    @State private var textHeight: CGFloat?
    @State private var textEditorHeight: CGFloat = .zero
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var oneLineTextHeight = CGFloat.zero
    @FocusState private var isFocused: Bool
    
    public var body: some View {
        ScrollView {
            ZStack(alignment: .center) {
                Text(inputText.isEmpty ? " " : inputText)
                    .font(.body)
                    .foregroundStyle(.blue)
                    .padding(.vertical, 12)
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .readHeight($textHeight)
                    .opacity(0)
                
                TextEditor(text: $inputText)
                    .focused($isFocused)
                    .overlay(alignment: .topLeading) {
                        if inputText.isEmpty {
                            placeholder
                                .pointerStyle(.horizontalText)
                                .onTapGesture {
                                    isFocused = true
                                }
                                .padding(.leading, 6)
                        }
                    }
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .scrollClipDisabled()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .scrollIndicators(.hidden)
                    .keyDownHandler(.enter {
                        if textEditorHeight >= config.maxHeight {
                            scrollPosition.scrollTo(edge: .bottom)
                        }
                    })
            }
        }
        .scrollIndicators(textEditorHeight > config.maxHeight ? .visible : .hidden)
        .scrollPosition($scrollPosition, anchor: .bottom)
        .frame(height: min(textEditorHeight, config.maxHeight))
        .if(config.clipShape != nil, transform: { content in
            content
                .clipShape(config.clipShape!)
        })
        .background {
            config.background
        }
        .onChange(of: textHeight, initial: true) { oldValue, newValue in
            if oldValue == nil, let newValue {
                oneLineTextHeight = newValue
            }
            guard let newValue else { return }
            if let oldValue, oldValue > 0 {
                withAnimation(.smooth) {
                    textEditorHeight = newValue
                }
            } else {
                textEditorHeight = newValue
            }
            
            if oldValue == oneLineTextHeight, newValue > oneLineTextHeight {
                // print("changed to multi line", oldValue, newValue, oneLineTextHeight)
                self.config.onSingleLineChanged?(false)
            } else if let oldValue, newValue == oneLineTextHeight, oldValue > oneLineTextHeight {
                self.config.onSingleLineChanged?(true)
            }
        }
    }
    
    
    class Config {
        var maxHeight: CGFloat = 200
        var background: AnyView = AnyView(EmptyView())
        var clipShape: AnyShape?
        var onSingleLineChanged: ((_ isSingleLine: Bool) -> Void)?
    }
    
    @MainActor
    public func maxHeight(_ height: CGFloat) -> AutoGrowTextEditor {
        self.config.maxHeight = height
        return self
    }
    
    @MainActor
    public func clipShape<S: Shape>(_ shape: S) -> AutoGrowTextEditor {
        config.clipShape = AnyShape(shape)
        return self
    }
    
    @MainActor
    public func background<Content: View>(@ViewBuilder _ content: () -> Content) -> AutoGrowTextEditor {
        self.config.background = AnyView(content())
        return self
    }
    
    @MainActor
    public func onSingleLineChanged(_ action: @escaping (_ isSingleLine: Bool) -> Void) -> AutoGrowTextEditor {
        self.config.onSingleLineChanged = action
        return self
    }
}
