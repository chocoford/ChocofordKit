//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/5/12.
//

import SwiftUI
#if os(iOS)
import UIKit
class UIEmojiTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var onFocus: (() -> Void)? = nil
    
    func setEmoji() {
        _ = self.textInputMode
    }
    
    override var textInputContextIdentifier: String? {
           return ""
    }
    
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
//            print(mode.primaryLanguage)
            if mode.primaryLanguage == "emoji" {
                self.keyboardType = .default // do not remove this
                return mode
            }
        }
        return nil
    }
    
    override func becomeFirstResponder() -> Bool {
        if let onFocus = onFocus {
            onFocus()
        }
        return super.becomeFirstResponder()
    }
}

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding? = nil
    var placeholder: String = ""
    
    func makeUIView(context: Context) -> UIEmojiTextField {
        let emojiTextField = UIEmojiTextField()
        emojiTextField.placeholder = placeholder
        emojiTextField.text = text
        emojiTextField.delegate = context.coordinator
        
        emojiTextField.onFocus = {
            isFocused?.wrappedValue = true
        }
        
        return emojiTextField
    }
    
    func updateUIView(_ uiView: UIEmojiTextField, context: Context) {
        uiView.text = text
        
        DispatchQueue.main.async {
            if let isFocused = self.isFocused?.wrappedValue, !isFocused {
                uiView.resignFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField
        
        init(parent: EmojiTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.text = textField.text ?? ""
            }
        }
    }
}

#if DEBUG
struct EmojiContentView: View {
    
    @State private var text: String = ""
    
    var body: some View {
        EmojiTextField(text: $text, placeholder: "Enter emoji")
            .frame(height: 100)
            .background(.green)
            
    }
}

struct EmojiTextField_Previews: PreviewProvider {
    static var previews: some View {
        EmojiContentView()
    }
}
#endif

#endif
