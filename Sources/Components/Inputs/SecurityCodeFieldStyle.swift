//
//  SecurityCodeFieldStyle.swift
//  
//
//  Created by Chocoford on 2023/4/23.
//

import SwiftUI
import ChocofordUIEssentials

public struct SecurityCodeFieldStyle: TextFieldStyle {
    @Binding var text: String
    var length: Int
    
    @FocusState private var isFocused: Bool
    
    
    public init(_ text: Binding<String>, length: Int) {
        self._text = text
        self.length = length
    }
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            configuration
                .focused($isFocused)
                .textFieldStyle(.plain)
                .opacity(0)
            
            HStack {
                ForEach(0..<length, id: \.self) { i in
                    Text(text.count > i ? String(text[i]) : " ")
                        .font(.monospaced(.body)())
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.gray)
                        }
                    
                }
            }
        }
    }
}

#if DEBUG
struct SecurityCodeFieldStyle_Previews: PreviewProvider {
    static var previews: some View {
        TextField("", text: .constant(""))
            .textFieldStyle(SecurityCodeFieldStyle(.constant(""), length: 4))
    }
}
#endif
