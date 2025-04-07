//
//  EmojiPicker.swift
//  SwiftyTrickle
//
//  Created by Chocoford on 2023/3/29.
//

import SwiftUI
import ChocofordEssentials
//import SwiftUIOverlayContainer

public struct EmojiPicker<Content: View>: View {
//    @Environment(\.overlayContainerManager) var telepoter

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
            emojiField()
                .frame(width: 8, height: 8)
                .opacity(0)
                .onChange(of: emojiInput) { newValue in
                    if let c = newValue.first, c.isEmoji {
                        onSelected(String(c))
                        #if os(iOS)
                        textFieldFocused = false
                        #endif
                    }
                    emojiInput = ""
                    textFieldFocused = false
                }
            Button {
                textFieldFocused = true
#if os(macOS)
                DispatchQueue.main.async {
                    NSApp.orderFrontCharacterPalette(nil)
                }
#elseif os(iOS)
                telepoter.show(view: EmojiKeyboardMaskView {
                    textFieldFocused = false
                }, in: "teleport", using: TeleportConfiguration())
#endif
            } label: {
                content()
            }
            .buttonStyle(.borderless)
        }
    }
    
    @ViewBuilder
    func emojiField() -> some View {
#if os(macOS)
        TextField("", text: $emojiInput)
            .focused($textFieldFocused)
#elseif os(iOS)
        EmojiTextField(text: $emojiInput)
            .focused($textFieldFocused)
#endif
    }
    
    
    #if os(iOS)
    @ViewBuilder
    func keyboardMask() -> some View {
        
    }
    #endif
}
//#elseif os(iOS)
//public struct EmojiPicker<Content: View>: View {
//    var content: () -> Content
//    var onSelected: (_ emoji: String) -> Void
//
//    public init(onSelected: @escaping (_ emoji: String) -> Void,
//         @ViewBuilder label: @escaping () -> Content) {
//        self.content = label
//        self.onSelected = onSelected
//    }
//
//    public var body: some View {
//        Button {
//
//        } label: {
//            content()
//        }
//        .buttonStyle(.borderless)
//    }
//}
//#endif

struct EmojiKeyboardMaskView: View {
//    @Environment(\.overlayContainer) var container

    var onTap: () -> Void
    
    var body: some View {
        Color.clear //green.opacity(0.5)
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture {
                onTap()
//                container.dismiss()
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 0.1)
                    .onChanged({ _ in
                        onTap()
//                        container.dismiss()
                    })
            )
    }
}


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

