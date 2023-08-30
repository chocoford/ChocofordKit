//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/8/30.
//

import SwiftUI

/// A button that has a toggle style, with toggle state and toggle action.
public struct ToggleButton<L: View>: View {
    public typealias Action = () -> Void
    
    var label: () -> L
    var isOn: Bool
    var action: Action
    
    public init(isOn: Bool, action: @escaping Action, @ViewBuilder label: @escaping () -> L) {
        self.label = label
        self.isOn = isOn
        self.action = action
    }
    
    @State private var localIsOn: Bool = false
    
    public var body: some View {
        Toggle(isOn: $localIsOn, label: self.label)
            .onChange(of: localIsOn) { newVal in
                if newVal != self.isOn {
                    self.action()
                    DispatchQueue.main.async {
                        self.localIsOn = self.isOn
                    }
                }
            }
            .onChange(of: self.isOn) { newVal in
                self.localIsOn = newVal
            }
    }
}
