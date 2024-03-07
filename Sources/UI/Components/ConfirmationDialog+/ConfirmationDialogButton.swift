//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2024/3/7.
//

import SwiftUI

public struct ConfirmationDialogButton: View {
    var titleKey: LocalizedStringKey
    var actions: AnyView
    var label: AnyView
    
    public init<Label: View, Actions: View>(
        titleKey: LocalizedStringKey,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder label: () -> Label
    ) {
        self.titleKey = titleKey
        self.actions = AnyView(actions())
        self.label = AnyView(label())
    }
    
    @State private var isPresented: Bool = false
    
    public var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            label
        }
        .confirmationDialog(titleKey, isPresented: $isPresented) {
            actions
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
