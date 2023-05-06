//
//  EmojiPicker.swift
//  SwiftyTrickle
//
//  Created by Chocoford on 2023/3/29.
//

import SwiftUI

#if os(macOS)
public struct EmojiPicker<Content: View>: View {
    var content: () -> Content
    var onSelected: (_ emoji: String) -> Void
    
    public init(onSelected: @escaping (_ emoji: String) -> Void,
         @ViewBuilder label: @escaping () -> Content) {
        self.content = label
        self.onSelected = onSelected
    }
    
    @State private var emojiInput: String = ""
    @FocusState private var textFieldFocused
    
    
    public var body: some View {
        ZStack(alignment: .leading) {

            TextField("", text: $emojiInput)
                .focused($textFieldFocused)
                .frame(width: 8, height: 8)
                .opacity(0)
                .onChange(of: emojiInput) { newValue in
                    if !newValue.isEmpty {
                        onSelected(String(emojiInput.prefix(1)))
                        emojiInput = ""
                    }
                }

            Button {
                textFieldFocused = true
                DispatchQueue.main.async {
                    NSApp.orderFrontCharacterPalette(nil)
                }
            } label: {
                content()
            }
            .buttonStyle(.borderless)

        }
    }
}
#elseif os(iOS)
public struct EmojiPicker<Content: View>: View {
    var content: () -> Content
    var onSelected: (_ emoji: String) -> Void
    
    public init(onSelected: @escaping (_ emoji: String) -> Void,
         @ViewBuilder label: @escaping () -> Content) {
        self.content = label
        self.onSelected = onSelected
    }
    
    public var body: some View {
        Button {
          
        } label: {
            content()
        }
        .buttonStyle(.borderless)
    }
}
#endif


#if DEBUG
struct EmojiPicker_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPicker(onSelected: { emoji in
            
        }) {
            Image(systemName: "face.smiling")
                .contentShape(Rectangle())
        }
    }
}
#endif

