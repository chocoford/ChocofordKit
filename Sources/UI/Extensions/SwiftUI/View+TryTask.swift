//
//  View+TryTask.swift
//  
//
//  Created by Dove Zachary on 2023/12/29.
//

import SwiftUI
#if canImport(SwiftyAlert)
import SwiftyAlert
#if canImport(AlertToast)
import AlertToast
#endif
#endif

public enum TryTaskErrorHandler {
#if canImport(SwiftyAlert)
    case alert
#if canImport(AlertToast)
    case alertToast
#endif
#endif
    case print
}

struct TryTaskViewModifier: ViewModifier {
#if canImport(SwiftyAlert)
    @Environment(\.alert) var alert
#if canImport(AlertToast)
    @Environment(\.alertToast) var alertToast
#endif
#endif
    var priority: TaskPriority
    var errorHandler: TryTaskErrorHandler
    var action: () async throws -> Void
    
    init(
        priority: TaskPriority = .userInitiated,
        errorHandler: TryTaskErrorHandler = .print,
        _ action: @escaping () async throws -> Void
    ) {
        self.priority = priority
        self.errorHandler = errorHandler
        self.action = action
    }
    
    func body(content: Content) -> some View {
        content
            .task(priority: priority) {
                do {
                    try await action()
                } catch {
                    if errorHandler != .print, isPreview {
                        print(error)
                    }
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
            }
    }
}

extension View {
    @ViewBuilder
    public func tryTask(
        priority: TaskPriority = .userInitiated,
        errorHandler: TryTaskErrorHandler = .print,
        _ action: @escaping () async throws -> Void
    ) -> some View {
        modifier(TryTaskViewModifier(priority: priority, errorHandler: errorHandler, action))
    }
}

