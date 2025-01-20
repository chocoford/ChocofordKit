//
//  AutoCompleteModifier.swift
//
//
//  Created by Dove Zachary on 2023/10/30.
//

import SwiftUI

struct AutoCompleteModifier: ViewModifier {
    var items: [String]
    var arrowEdge: Edge?
    
    @FocusState var isFocus: Bool
    @Binding var text: String
    
    init(items: [String], text: Binding<String>, arrowEdge: Edge?) {
        self.items = items
        self._text = text
        self.arrowEdge = arrowEdge
    }
    
    @State private var showPopover: Bool = false
    @State private var popoverHeight: CGFloat = .zero
    
    func body(content: Content) -> some View {
        content
            .focused($isFocus)
            .onChange(of: text) { newValue in
                withAnimation {
                    if items.filter({$0 == newValue}).count == 1 || (
                        !items.contains(where: {$0.lowercased().contains(text.lowercased())}) &&
                        !newValue.isEmpty
                    ) || items.isEmpty {
                        showPopover = false
                    } else if items.contains(where: {$0.lowercased().contains(text.lowercased())}) {
                        showPopover = true
                    }
                }
            }
            .onChange(of: isFocus) { newValue in
                if newValue && !items.isEmpty &&
                    (
                        items.contains(where: {$0.lowercased().contains(text.lowercased())}) ||
                        text.isEmpty
                    ) {
                    withAnimation {
                        showPopover = true
                    }
                }
            }
            .popover(isPresented: $showPopover, arrowEdge: arrowEdge, content: {
                // Can not use List, it will resign textField's first responder
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(
                            Array(items.filter({
                                text.isEmpty || $0.lowercased().contains(text.lowercased())
                            }).enumerated()),
                            id: \.element
                        ) { i, key in
                            Divider()
                                .opacity(i == 0 ? 0 : 1)
                            Hover { isHover in
                                HStack {
                                    Text(key)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.selection.opacity(isHover ? 1 : 0), in: RoundedRectangle(cornerRadius: 4))
                                .onTapGesture {
                                    withAnimation {
                                        text = key
                                        showPopover = false
                                    }
                                }
                            }
                        }
                    }
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 2)
                    .readHeight($popoverHeight)
                }
                .frame(height: min(popoverHeight, 200))
                .frame(minWidth: 300, maxHeight: 200)
            })
    }
}


extension TextField {
    @ViewBuilder
    public func autoComplete(items: [String], text: Binding<String>, arrowEdge: Edge? = nil) -> some View {
        modifier(AutoCompleteModifier(items: items,text: text, arrowEdge: arrowEdge))
    }
}
