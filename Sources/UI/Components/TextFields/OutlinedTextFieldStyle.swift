//
//  OutlinedTextFieldStyle.swift
//
//
//  Created by Dove Zachary on 2023/9/14.
//
import SwiftUI

public struct OutlinedTextFieldStyle<Prepend: View>: TextFieldStyle {
    var loading: Bool
    var prepend: () -> Prepend
    
    @FocusState private var isFocused: Bool
    
    init(
        loading: Bool = false,
        @ViewBuilder prepend: @escaping () -> Prepend = { EmptyView() }
    ) {
        self.loading = loading
        self.prepend = prepend
    }
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        HStack {
            prepend()
            configuration
                .focused($isFocused)
                .textFieldStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isFocused ? Color.accentColor : Color.separatorColor)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.textBackgroundColor))
                .padding(1)
                .overlay(
                    loading ?
                    CircularProgressView()
                        .size(14)
                        .lineWidth(2)
                        .padding(.trailing, 12) : nil,
                    alignment: .trailing
                )
        )
    }
}

extension TextFieldStyle where Self == OutlinedTextFieldStyle<EmptyView> {
    public static var outlined: OutlinedTextFieldStyle<EmptyView> {
        OutlinedTextFieldStyle(loading: false)
    }
    
    public static func outlined<P: View>(loading: Bool = false, @ViewBuilder prepend: @escaping () -> P) -> OutlinedTextFieldStyle<P> {
        OutlinedTextFieldStyle(loading: loading, prepend: prepend)
    }
}

//extension TextFieldStyle where Self == OutlinedTextFieldStyle<P> {
//    public static func outlined<P: View>(loading: Bool = false, @ViewBuilder prepend: @escaping () -> P) -> OutlinedTextFieldStyle<P> {
//        OutlinedTextFieldStyle(loading: loading, prepend: prepend)
//    }
//}

#if DEBUG
#Preview {
    TextField("", text: .constant(""), prompt: Text("Enter your email"))
        .textFieldStyle(.outlined(loading: false, prepend: {
            Image(systemSymbol: .envelope)
        }))
        .padding()
        .previewLayout(.fixed(width: 400, height: 400))
}
#endif
