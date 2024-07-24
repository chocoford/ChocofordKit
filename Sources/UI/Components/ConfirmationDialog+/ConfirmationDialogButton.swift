//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2024/3/7.
//

import SwiftUI

public struct ConfirmationDialogButton: View {
    var titleKey: LocalizedStringKey
    var titleVisibility: Visibility
    var actions: AnyView
    var message: AnyView
    var label: AnyView
    
    public init<Label: View, Actions: View, Message: View>(
        titleKey: LocalizedStringKey,
        titleVisibility: Visibility = .automatic,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder message: () -> Message = { EmptyView() },
        @ViewBuilder label: () -> Label
    ) {
        self.titleKey = titleKey
        self.titleVisibility = titleVisibility
        self.actions = AnyView(actions())
        self.message = AnyView(message())
        self.label = AnyView(label())
    }
    
    @State private var isPresented: Bool = false
    
    public var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            label
        }
        .confirmationDialog(titleKey, isPresented: $isPresented, titleVisibility: titleVisibility) {
            actions
        } message: {
            message
        }
    }
}

#Preview {
    ConfirmationDialogButton(titleKey: "ConfirmationDialog") {
        Text("1")
        Text("2")
        Text("3")
    } label: {
        Text("ConfirmationDialog Button")
    }

}
