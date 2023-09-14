//
//  Text+Extension.swift
//  
//
//  Created by Chocoford on 2023/4/16.
//

#if canImport(SwiftUI)
import SwiftUI

public extension Text {
    @ViewBuilder
    func chipStyle() -> some View {
        padding(.vertical, 2)
            .padding(.horizontal, 8)
            .foregroundColor(.accentColor)
            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
    }
}
#endif
