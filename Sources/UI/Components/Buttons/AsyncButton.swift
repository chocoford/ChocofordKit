//
//  AsyncButton.swift
//  
//
//  Created by Dove Zachary on 2023/6/16.
//

import SwiftUI

public struct AsyncButton<Label: View>: View {
    
    var role: ButtonRole?
    var action: () async -> Void
    var label: () -> Label
    
    public init(role: ButtonRole? = nil,
                action: @escaping () async -> Void,
                @ViewBuilder label: @escaping () -> Label) {
        self.role = role
        self.action = action
        self.label = label
    }
    
    @State private var isRunning: Bool = false
    
    public var body: some View {
        Button(role: role, action: {
            guard !isRunning else { return }
            Task {
                isRunning = true
                await action()
                isRunning = false
            }
        }, label: label)
        .disabled(isRunning)
    }
}
