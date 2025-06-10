//
//  WithAsyncValue.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/8/23.
//

import SwiftUI
import Logging

public struct WithAsyncValue<Content: View, Value: Sendable>: View {
    @Environment(\.alertToast) var alertToast
    
    private let logger = Logger(label: "WithAsyncValue")
    
    var asyncValue: @Sendable () async throws -> Value?
    var content: (Value?, Error?) -> Content
    var errorHandler: ((Error) -> Void)?
    
    @State private var value: Value?
    @State private var error: Error?
    
    @State private var getValueTask: Task<Void, Never>? = nil
    
    public init(
        _ asyncValue: @Sendable @escaping () async throws -> Value?,
        @ViewBuilder content: @escaping (Value?, Error?) -> Content,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        self.asyncValue = asyncValue
        self.content = content
        self.errorHandler = errorHandler
    }
    
    public init(
        _ asyncValue: @Sendable @escaping () async throws -> Value?,
        @ViewBuilder content: @escaping (Value?) -> Content,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        self.asyncValue = asyncValue
        self.content = { value, _ in
            content(value)
        }
        self.errorHandler = errorHandler
    }
    
    public var body: some View {
        content(value, error)
            .onAppear {
                self.getValueTask = Task.detached {
                    logger.info("\(Thread.current)")
                    do {
                        let value = try await asyncValue()
                        await MainActor.run {
                            self.value = value
                        }
                    } catch {
                        await MainActor.run {
                            self.error = error
                            if let errorHandler {
                                errorHandler(error)
                            } else {
                                alertToast(error)
                            }
                        }
                    }
                }
            }
            .onDisappear {
                logger.info("on Disappear, cancel task...")
                self.getValueTask?.cancel()
            }
    }
}


#if DEBUG
struct WithAsyncValuePreview: View {
    
    var asyncValue: Int {
        get async {
            1
        }
    }
    
    var body: some View {
        WithAsyncValue({
            await asyncValue
        }) { value in
            
        }
    }
}


#Preview {
    WithAsyncValuePreview()
}
#endif
