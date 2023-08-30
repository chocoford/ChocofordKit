//
//  AsyncButton.swift
//  
//
//  Created by Dove Zachary on 2023/6/16.
//

import SwiftUI

public struct UnexpectedError: LocalizedError {
//    var error: Error?
//    
//    public var errorDescription: String {
//        return "Unexpected error: \(error?.localizedDescription ?? "")"
//    }
}

/// A button that allow perform async throw action, with alert.
public struct AsyncButton<Label: View, E: LocalizedError>: View {
    
    internal var role: ButtonRole?
    internal var action: () async throws -> Void
    internal var label: () -> Label
    
//    internal var config: Config = .init()
    
    @State private var showAlert = false
    @State private var error: E? = nil
    
    public init(role: ButtonRole? = nil,
                action: @escaping () async throws -> Void,
                @ViewBuilder label: @escaping () -> Label) {
        self.role = role
        self.action = action
        self.label = label
    }
    
    public init(role: ButtonRole? = nil,
                action: @escaping () async -> Void,
                @ViewBuilder label: @escaping () -> Label) where E == UnexpectedError {
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
                do {
                    try await action()
                } catch let error as E {
                    self.error = error
                }
                isRunning = false
            }
        }, label: label)
        .disabled(isRunning)
        .alert(isPresented: $showAlert, error: error) {
            Button {
                showAlert.toggle()
            } label: {
                Text("OK")
            }
        }
    }
}

//extension AsyncButton {
//    class Config<A: View>: ObservableObject {
//        var alertAction: () -> A
//        
//        init(@ViewBuilder alertAction: @escaping () -> A = { EmptyView() }) {
//            self.alertAction = alertAction
//        }
//        
//        func alertAction() ->
//    }
//}
