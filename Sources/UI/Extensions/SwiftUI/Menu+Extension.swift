//
//  Menu+Extension.swift
//  
//
//  Created by Chocoford on 2023/4/15.
//

#if canImport(SwiftUI)
import SwiftUI

public extension Menu {
    @ViewBuilder
    func plainStyle() -> some View {
        menuIndicator(.hidden)
            .buttonStyle(.plain)
            .fixedSize()
    }
}

#endif
