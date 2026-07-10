//
//  AccessibilityRepresentation.swift
//
//
//  Created by Dove Zachary on 2023/9/11.
//

import SwiftUI

public protocol AccessibilityRepresentation {
    var identifier: String { get }
}


extension View {
    @ViewBuilder
    public func accessibility<A: AccessibilityRepresentation>(_ accessibility: A) -> some View {
        self
            .accessibilityIdentifier(accessibility.identifier)
    }
}
