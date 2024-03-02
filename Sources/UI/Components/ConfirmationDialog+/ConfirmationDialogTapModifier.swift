//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/12/29.
//

import SwiftUI

struct ConfirmationDialogTapModifier: ViewModifier {
    var titleKey: LocalizedStringKey
    var actions: AnyView
    
    init<Actions: View>(titleKey: LocalizedStringKey, actions: () -> Actions) {
        self.titleKey = titleKey
        self.actions = AnyView(actions())
    }
    
    @State private var isPresented: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                isPresented.toggle()
            }
            .confirmationDialog(titleKey, isPresented: $isPresented) {
                actions
            }
    }
}

extension View {
    @ViewBuilder
    public func confirmationDialogOnTap<Actions: View>(
        titleKey: LocalizedStringKey,
        actions: @escaping () -> Actions
    ) -> some View {
        modifier(
            ConfirmationDialogTapModifier(titleKey: titleKey, actions: actions)
        )
    }
}
