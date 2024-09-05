//
//  WithAsyncValue.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/8/23.
//

import SwiftUI

public struct WithAsyncValue<Content: View, Value>: View {
    @Environment(\.alertToast) var alertToast
    
    var asyncValue: () async throws -> Value
    var content: (Value?, Error?) -> Content
    var errorHandler: ((Error) -> Void)?
    
    @State private var value: Value?
    @State private var error: Error?
    
    public init(
        _ asyncValue: @escaping () async throws -> Value,
        @ViewBuilder content: @escaping (Value?, Error?) -> Content,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        self.asyncValue = asyncValue
        self.content = content
        self.errorHandler = errorHandler
    }
    
    public init(
        _ asyncValue: @escaping () async throws -> Value,
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
            .task {
                do {
                    self.value = try await asyncValue()
                } catch {
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
