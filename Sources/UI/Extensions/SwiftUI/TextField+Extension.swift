//
//  TextField+Extension.swift
//  
//
//  Created by Chocoford on 2023/4/15.
//

#if canImport(SwiftUI)
import SwiftUI

public extension TextField {
    /// perform action with any blur that be triggered, including normal blur, onSubmit, onDisappear
    @ViewBuilder 
    func submitOnAnyBlur(isFocused: Bool, perform action: @escaping () -> Void) -> some View {
        onChange(of: isFocused) { focused in
            if focused == false {
                action()
            }
        }
        .onDisappear(perform: action)
        .onSubmit(action)
        .submitLabel(.done)
    }
}
#endif
