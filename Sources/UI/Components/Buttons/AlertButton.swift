//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/1.
//

import SwiftUI

public struct AlertButton: View {
    
    var role: ButtonRole?
    var alertTitle: LocalizedStringKey
    var label: AnyView
    var actions: AnyView
    var messages: AnyView
    
    public init<Label: View, Actions: View, Messages: View>(
        role: ButtonRole? = nil,
        alertTitle: LocalizedStringKey = "Warning",
        @ViewBuilder label: () -> Label,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder messages: () -> Messages
    ) {
        self.role = role
        self.alertTitle = alertTitle
        self.label = AnyView(label())
        self.actions = AnyView(actions())
        self.messages = AnyView(messages())
    }
    
    public init<Label: View>(
        role: ButtonRole? = nil,
        alertTitle: LocalizedStringKey = "Warning",
        message: LocalizedStringKey,
        @ViewBuilder label: () -> Label,
        onConfirm: @Sendable @escaping () async throws -> Void
    ) {
        self.role = role
        self.alertTitle = alertTitle
        self.label = AnyView(label())
        self.actions = AnyView(
            Group {
                Button("Cancel", role: .cancel) {}
                
                AsyncButton("Confirm", role: .destructive) {
                    try await onConfirm()
                }
            }
        )
        self.messages = AnyView(
            Text(message)
        )
    }
    
    public init(
        _ titleKey: LocalizedStringKey,
        role: ButtonRole? = nil,
        alertTitle: LocalizedStringKey = "Warning",
        message: LocalizedStringKey,
        onConfirm: @Sendable @escaping () async throws -> Void
    ) {
        self.role = role
        self.alertTitle = alertTitle
        self.label = AnyView(Text(titleKey))
        self.actions = AnyView(
            Group {
                Button("Cancel", role: .cancel) {}
                
                AsyncButton("Confirm", role: .destructive) {
                    try await onConfirm()
                }
            }
        )
        self.messages = AnyView(
            Text(message)
        )
    }
    
    
    @State private var showAlert = false

    public var body: some View {
        Button(role: role, action: {
            withAnimation {
                self.showAlert.toggle()
            }
        }, label: {
            label
        })
        .alert(self.alertTitle, isPresented: $showAlert) {
            actions
        } message: {
            messages
        }
    }
}

#if DEBUG
#Preview {
    AlertButton {
        
    } actions: {
        
    } messages: {
        
    }

}
#endif
