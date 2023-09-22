//
//  AsyncButton.swift
//  
//
//  Created by Dove Zachary on 2023/6/16.
//

import SwiftUI

public struct AsyncButtonError: LocalizedError {
//    var error: Error?
//    
//    public var errorDescription: String {
//        return "Unexpected error: \(error?.localizedDescription ?? "")"
//    }
}

/// A button that allow perform async throw action, with alert.
public struct AsyncButton<Label: View, Loading: View>: View {
    
    internal var role: ButtonRole?
    internal var action: () async throws -> Void
    internal var label: () -> Label
    internal var loadingLabel: () -> Loading
    
    
    @State private var showAlert = false
    @State private var error: Error? = nil
    
    @State private var labelWidth: CGFloat = .zero
    
    public init(role: ButtonRole? = nil,
                action: @escaping () async throws -> Void,
                @ViewBuilder label: @escaping () -> Label,
                @ViewBuilder loadingLabel: @escaping () -> Loading = {  ProgressView().controlSize(.small) }) {
        self.role = role
        self.action = action
        self.label = label
        self.loadingLabel = loadingLabel
    }
    
    @State private var isRunning: Bool = false
    
    public var body: some View {
        Button(role: role) {
            guard !isRunning else { return }
            Task {
                isRunning = true
                do {
                    try await action()
                } catch {
                    self.error = error
                }
                isRunning = false
            }
        } label: {
            ViewSizeReader { size in
                if isRunning {
                    loadingLabel()
                        .frame(width: labelWidth)
                } else {
                    label()
                        .onChange(of: size.width) { width in
                            labelWidth = width
                        }
                }
            }
        }
        .disabled(isRunning)
        .alert("Error occured!", isPresented: $showAlert) {
            Button {
                showAlert.toggle()
            } label: {
                Text("OK")
            }
        } message: {
            if let error = self.error {
                Text(String(describing: error))
            } else {
                Text("Unexpected error.")
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        AsyncButton {
            await Timer.wait(2)
        } label: {
            Center(.horizontal) {
                Text("Button")
            }
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .controlSize(.large)
    }
    .frame(width: 200)
}
#endif
