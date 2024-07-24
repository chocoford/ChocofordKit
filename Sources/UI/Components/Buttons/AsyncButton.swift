//
//  AsyncButton.swift
//  
//
//  Created by Dove Zachary on 2023/6/16.
//

import SwiftUI
#if canImport(SwiftyAlert)
import SwiftyAlert
#if canImport(AlertToast)
import AlertToast
#endif
#endif

public struct AsyncButtonError: LocalizedError {
//    var error: Error?
//    
//    public var errorDescription: String {
//        return "Unexpected error: \(error?.localizedDescription ?? "")"
//    }
}
public enum AsyncButtonErrorHandler {
#if canImport(SwiftyAlert)
    case alert
#if canImport(AlertToast)
    case alertToast
#endif
#endif
    case print
}

/// A button that allow perform async throw action, with alert.
public struct AsyncButton<Label: View, Loading: View>: View {
#if canImport(SwiftyAlert)
    @Environment(\.alert) var alert
#if canImport(AlertToast)
    @Environment(\.alertToast) var alertToast
#endif
#endif
    internal var role: ButtonRole?
    internal var errorHandler: AsyncButtonErrorHandler
    internal var action: () async throws -> Void
    internal var label: () -> Label
    internal var loadingLabel: () -> Loading
    
    
    public init(role: ButtonRole? = nil,
                errorHandler: AsyncButtonErrorHandler = .alert,
                action: @escaping @Sendable () async throws -> Void,
                @ViewBuilder label: @escaping () -> Label,
                @ViewBuilder loadingLabel: @escaping () -> Loading = {  ProgressView().controlSize(.small) }) {
        self.role = role
        self.errorHandler = errorHandler
        self.action = action
        self.label = label
        self.loadingLabel = loadingLabel
    }
    
    public init<S>(
        _ title: S,
        role: ButtonRole? = nil,
        errorHandler: AsyncButtonErrorHandler = .alert,
        action: @escaping @Sendable () async throws -> Void,
        @ViewBuilder loadingLabel: @escaping () -> Loading = {
            ProgressView()
#if canImport(AppKit)
                .controlSize(.small)
#endif
        }
    ) where S : StringProtocol, Label == Text {
        self.role = role
        self.errorHandler = errorHandler
        self.action = action
        self.label = { Text(title) }
        self.loadingLabel = loadingLabel
    }
    
    private var showAlert: Binding<Bool> {
        Binding {
            self.error != nil
        } set: { val in
            if !val {
                self.error = nil
            }
        }

    }
    @State private var error: (any Error)? = nil
    
    @State private var labelWidth: CGFloat = .zero
    
    @State private var isRunning: Bool = false
    
    public var body: some View {
        Button(role: role) {
            guard !isRunning else { return }
            Task {
                isRunning = true
                do {
                    try await action()
                } catch {
                    switch errorHandler {
#if canImport(SwiftyAlert)
                        case .alert:
                            alert(error: error)
#if canImport(AlertToast)
                        case .alertToast:
                            alertToast(.init(error: error))
#endif
#endif
                        case .print:
                            print(error)
                    }

                }
                isRunning = false
            }
        } label: {
            ZStack {
#if canImport(AppKit)
                if isRunning {
                    loadingLabel()
                        .fixedSize()
                } else {
                    label()
                }
#elseif canImport(UIKit)
                label()
                    .opacity(isRunning ? 0 : 1)
                    .overlay {
                        loadingLabel()
                            .fixedSize()
                            .opacity(isRunning ? 1 : 0)
                    }
#endif
            }
            
//            ViewSizeReader { size in
//                if isRunning {
//                    loadingLabel()
//                        .frame(width: labelWidth)
//                } else {
//                    label()
//                        .onChange(of: size.width) { width in
//                            labelWidth = width
//                        }
//                }
//            }
        }
        .disabled(isRunning)
        .alert("Error occured!", isPresented: showAlert) {
            Button {
                showAlert.wrappedValue.toggle()
            } label: {
                Text("OK")
            }
        } message: {
            if let error = self.error as? LocalizedError {
                Text(
"""
Error: \(error.errorDescription ?? "Unknown")
Reason: \(error.failureReason ?? "Unknown")
Suggestion: \(error.recoverySuggestion ?? "Unknown")
"""
                )
            } else if let error = self.error {
                let _ = dump(error)
                Text(error.localizedDescription)
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
