//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/20.
//
import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

/// Publisher to read keyboard changes.
public protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

public extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
#if canImport(UIKit)
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
#else
        CurrentValueSubject(false).eraseToAnyPublisher()
#endif
    }

}

struct IsKeyboardPresentKey: EnvironmentKey {
    static var defaultValue: Bool = false
}
public extension EnvironmentValues {
    var isKeyboardPresent: Bool {
        get { self[IsKeyboardPresentKey.self] }
        set { self[IsKeyboardPresentKey.self] = newValue }
    }
}

//extension View {
//    @ViewBuilder
//    public func watchKeyboardVisibility() -> some View where self: KeyboardReadable {
//        onReceive(keyboardPublisher) { isPresent in
//            
//        }
//    }
//}
