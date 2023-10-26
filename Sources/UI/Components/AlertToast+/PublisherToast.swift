//
//  PublisherToast.swift
//  
//
//  Created by Dove Zachary on 2023/10/25.
//

import SwiftUI
import Combine
import AlertToast

internal struct PublisherToastModifier: ViewModifier {
    var publisher: AnyPublisher<Error, Never>
    var duration: TimeInterval
    var tapToDismiss: Bool
    var offsetY: CGFloat
    var alert: () -> AlertToast
    var onTap: () -> Void
    var onComplete: () -> Void
    
    internal init<P: Publisher>(
        publisher: P,
        duration: TimeInterval = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping () -> AlertToast,
        onTap: @escaping () -> Void = {},
        onComplete: @escaping () -> Void = {}
    ) where P.Output == Error, P.Failure == Never {
        self.publisher = AnyPublisher(publisher)
        self.duration = duration
        self.tapToDismiss = tapToDismiss
        self.offsetY = offsetY
        self.alert = alert
        self.onTap = onTap
        self.onComplete = onComplete
    }

    
    @State private var error: Error? = nil
    
    var isPresent: Binding<Bool> {
        Binding {
            self.error != nil
        } set: { val in
            if !val && self.error != nil {
                self.error = nil
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(self.publisher) { error in
                self.error = error
            }
            .toast(
                isPresenting: isPresent,
                duration: duration,
                tapToDismiss: tapToDismiss,
                offsetY: offsetY,
                alert: alert,
                onTap: onTap,
                completion: onComplete
            )
    }
}

extension View {
    @ViewBuilder
    public func toast<P: Publisher>(
        publisher: P,
        duration: TimeInterval = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping () -> AlertToast,
        onTap: @escaping () -> Void = {},
        onComplete: @escaping () -> Void = {}
    ) -> some View where P.Output == Error, P.Failure == Never  {
        modifier(
            PublisherToastModifier(
                publisher: publisher,
                duration: duration,
                tapToDismiss: tapToDismiss,
                offsetY: offsetY,
                alert: alert,
                onTap: onTap, 
                onComplete: onComplete
            )
        )
    }
}
