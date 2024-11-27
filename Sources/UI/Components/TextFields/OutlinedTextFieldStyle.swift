//
//  OutlinedTextFieldStyle.swift
//
//
//  Created by Dove Zachary on 2023/9/14.
//
import SwiftUI

public enum PaddingOption: Hashable {
    case all(CGFloat)
    case horizontal(CGFloat)
    case vertical(CGFloat)
    case top(CGFloat)
    case bottom(CGFloat)
    case leading(CGFloat)
    case trailing(CGFloat)
}

struct PaddingValue {
    var leading: CGFloat?
    var trailing: CGFloat?
    var top: CGFloat?
    var bottom: CGFloat?
}

extension Array<PaddingOption> {
    func getPaddingValue() -> PaddingValue {
        self.reduce(PaddingValue()) { partialResult, option in
            switch option {
                case .all(let all):
                    return PaddingValue(
                        leading: partialResult.leading ?? all,
                        trailing: partialResult.trailing ?? all,
                        top: partialResult.top ?? all,
                        bottom: partialResult.bottom ?? all
                    )
                case .horizontal(let horizontal):
                    return PaddingValue(
                        leading: partialResult.leading ?? horizontal,
                        trailing: partialResult.trailing ?? horizontal,
                        top: partialResult.top,
                        bottom: partialResult.bottom
                    )
                case .vertical(let vertical):
                    return PaddingValue(
                        leading: partialResult.leading,
                        trailing: partialResult.trailing,
                        top: partialResult.top ?? vertical,
                        bottom: partialResult.bottom ?? vertical
                    )
                case .top(let top):
                    return PaddingValue(
                        leading: partialResult.leading,
                        trailing: partialResult.trailing,
                        top: partialResult.top ?? top,
                        bottom: partialResult.bottom
                    )
                case .bottom(let bottom):
                    return PaddingValue(
                        leading: partialResult.leading,
                        trailing: partialResult.trailing,
                        top: partialResult.top,
                        bottom: partialResult.bottom ?? bottom
                    )
                case .leading(let leading):
                    return PaddingValue(
                        leading: partialResult.leading ?? leading,
                        trailing: partialResult.trailing,
                        top: partialResult.top,
                        bottom: partialResult.bottom
                    )
                case .trailing(let trailing):
                    return PaddingValue(
                        leading: partialResult.leading,
                        trailing: partialResult.trailing ?? trailing,
                        top: partialResult.top,
                        bottom: partialResult.bottom
                    )
            }
        }
    }
}

public struct OutlinedTextFieldStyle<Prepend: View, Append: View>: TextFieldStyle {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.controlSize) var controlSize
    
    var loading: Bool
    var padding: [PaddingOption]
    var prepend: () -> Prepend
    var append: () -> Append
    var paddingValue: PaddingValue
    
    @FocusState private var isFocused: Bool
    
    init(
        loading: Bool = false,
        padding: [PaddingOption] = [.all(10)],
        @ViewBuilder prepend: @escaping () -> Prepend = { EmptyView() },
        @ViewBuilder append: @escaping () -> Append = { EmptyView() }
    ) {
        self.loading = loading
        self.padding = padding
        self.prepend = prepend
        self.append = append
        
        self.paddingValue = padding.getPaddingValue()
    }
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: 2) {
            prepend()
            configuration
                .focused($isFocused)
                .textFieldStyle(.plain)
            append()
        }
        .foregroundStyle(isEnabled ? .primary : .secondary)
        .padding(.top, paddingValue.top)
        .padding(.bottom, paddingValue.bottom)
        .padding(.leading, paddingValue.leading)
        .padding(.trailing, paddingValue.trailing)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isEnabled ? Color.textBackgroundColor : Color.gray.opacity(0.4))
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isEnabled ? (isFocused ? Color.accentColor : Color.separatorColor) : Color.gray,
                        lineWidth: 0.5
                    )
            }
            .compositingGroup()
            .shadow(radius: 0.5, y: 0.5)
            .padding(1)
            .overlay(
                loading ?
                CircularProgressView()
                    .size(14)
                    .lineWidth(2)
                    .padding(.trailing, 12) : nil,
                alignment: .trailing
            )
        }
        .opacity(isEnabled ? 1 : 0.6)
        .animation(.default, value: isFocused)
    }
}

extension TextFieldStyle where Self == OutlinedTextFieldStyle<EmptyView, EmptyView> {
    public static var outlined: OutlinedTextFieldStyle<EmptyView, EmptyView> {
        OutlinedTextFieldStyle(loading: false)
    }
    
//    public static func outlined<P: View>(
//        loading: Bool = false,
//        padding: PaddingOption...,
//        @ViewBuilder prepend: @escaping () -> P
//    ) -> OutlinedTextFieldStyle<P, EmptyView> {
//        OutlinedTextFieldStyle(
//            loading: loading,
//            prepend: prepend,
//            append: { EmptyView() }
//        )
//    }
//    public static func outlined<A: View>(
//        loading: Bool = false,
//        padding: PaddingOption...,
//        @ViewBuilder append: @escaping () -> A
//    ) -> OutlinedTextFieldStyle<EmptyView, A> {
//        OutlinedTextFieldStyle(
//            loading: loading,
//            prepend: { EmptyView() },
//            append: append
//        )
//    }
    public static func outlined<P: View, A: View>(
        loading: Bool = false,
        padding: [PaddingOption] = [.all(10)],
        @ViewBuilder prepend: @escaping () -> P = { EmptyView() },
        @ViewBuilder append: @escaping () -> A = { EmptyView() }
    ) -> OutlinedTextFieldStyle<P, A> {
        OutlinedTextFieldStyle(
            loading: loading,
            padding: padding,
            prepend: prepend,
            append: append
        )
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
        .textFieldStyle(
            .outlined(
                loading: false,
                prepend: {
                    Image(systemSymbol: .envelope)
                }
            )
        )
        .padding()
        .previewLayout(.fixed(width: 400, height: 400))
}
#endif
