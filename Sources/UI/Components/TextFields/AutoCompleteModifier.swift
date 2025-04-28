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
    
    @FocusState var isFocused: Bool
    @Binding var text: String
    
    init(items: [String], text: Binding<String>, arrowEdge: Edge?) {
        self.items = items
        self._text = text
        self.arrowEdge = arrowEdge
    }
    
    @State private var isPresented: Bool = false
    @State private var popoverHeight: CGFloat = .zero
    
    @State private var selectionIndex: Int? = nil
    @State private var keydownListener: Any?

    var popoverItems: [String] {
        items.filter({
            text.isEmpty || $0.lowercased().contains(text.lowercased())
        })
    }
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .popover(isPresented: $isPresented, arrowEdge: arrowEdge, content: {
                // Can not use List, it will resign textField's first responder
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(popoverItems.enumerated()), id: \.element) { i, key in
                            Divider()
                                .opacity(i == 0 ? 0 : 1)
                            Hover { isHover in
                                HStack {
                                    Text(key)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    .selection.opacity(selectionIndex == i || isHover ? 1 : 0),
                                    in: RoundedRectangle(cornerRadius: 4)
                                )
                                .onTapGesture {
                                    selectItem(key)
                                }
                            }
                        }
                    }
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 2)
                    .readHeight($popoverHeight)
                }
                .frame(height: max(popoverHeight, 0))
                .frame(minWidth: 300, maxHeight: 200)
            })
            .onChange(of: text) { newValue in
                withAnimation {
                    if items.filter({$0 == newValue}).count == 1 || (
                        !items.contains(where: {$0.lowercased().contains(text.lowercased())}) &&
                        !newValue.isEmpty
                    ) || items.isEmpty {
                        isPresented = false
                    } else if items.contains(where: {$0.lowercased().contains(text.lowercased())}) {
                        isPresented = true
                    }
                }
            }
            .onChange(of: isFocused) { newValue in
                if newValue && !items.isEmpty &&
                    (
                        items.contains(where: {$0.lowercased().contains(text.lowercased())}) ||
                        text.isEmpty
                    ) {
                    withAnimation {
                        isPresented = true
                    }
                    selectionIndex = nil
                } else if !newValue {
                    withAnimation {
                        isPresented = false
                    }
                }
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    addKeyDownListener()
                } else {
                    removeKeyDownLinstener()
                }
            }
    }
    
    private func selectItem(_ item: String) {
        withAnimation {
            text = item
            isPresented = false
        }
    }
    
    private func addKeyDownListener() {
#if canImport(AppKit)
        keydownListener = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isFocused else { return event }
            print(event.keyCode)
            let maxIndex = popoverItems.count - 1
            if event.keyCode == 125 { // arrow down
                selectionIndex = min(maxIndex, (selectionIndex ?? -1) + 1)
            } else if event.keyCode == 126 { // arrow up
                if selectionIndex == 0 {
                    selectionIndex = nil
                } else if let selectionIndex {
                    self.selectionIndex = max(selectionIndex - 1, 0)
                }
            } else if event.keyCode == 36 { // Enter
                if let selectionIndex {
                    selectItem(self.popoverItems[selectionIndex])
                }
            }
            return event
        }
#endif
    }
    
    private func removeKeyDownLinstener() {
#if canImport(AppKit)
        if let keydownListener {
            NSEvent.removeMonitor(keydownListener)
        }
#endif
    }
}


extension TextField {
    @ViewBuilder
    public func autoComplete(items: [String], text: Binding<String>, arrowEdge: Edge? = nil) -> some View {
        modifier(AutoCompleteModifier(items: items,text: text, arrowEdge: arrowEdge))
    }
}
