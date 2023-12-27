//
//  PublisherToast.swift
//  
//
//  Created by Dove Zachary on 2023/10/25.
//

import SwiftUI
import Combine
import AlertToast
import ChocofordEssentials

internal struct ErrorPublisherToastModifier<P: Publisher, E: Error>: ViewModifier where P.Output == Optional<E>, P.Failure == Never {
    var publisher: P
    var duration: TimeInterval
    var tapToDismiss: Bool
    var offsetY: CGFloat
    var alert: (P.Output) -> AlertToast
    var onTap: (P.Output) -> Void
    var onComplete: (P.Output) -> Void
    
    internal init(
        publisher: P,
        duration: TimeInterval = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping (P.Output) -> AlertToast,
        onTap: @escaping (P.Output) -> Void = { _ in },
        onComplete: @escaping (P.Output) -> Void = { _ in }
    ) {
        self.publisher = publisher
        self.duration = duration
        self.tapToDismiss = tapToDismiss
        self.offsetY = offsetY
        self.alert = alert
        self.onTap = onTap
        self.onComplete = onComplete
    }

    
    @State private var error: P.Output = nil
    
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
                offsetY: offsetY
            ) {
                return self.alert(error)
            } onTap: {
                return self.onTap(error)
            } completion: {
                return self.onComplete(error)
            }
    }
}

extension AlertToast {
    
}

extension View {
    @ViewBuilder
    public func toast<P: Publisher, E: Error>(
        publisher: P,
        duration: TimeInterval = 2,
        tapToDismiss: Bool = true,
        offsetY: CGFloat = 0,
        alert: @escaping (P.Output) -> AlertToast,
        onTap: @escaping (P.Output) -> Void = { _ in },
        onComplete: @escaping (P.Output) -> Void = { _ in }
    ) -> some View where P.Output == Optional<E>, P.Failure == Never {
        modifier(
            ErrorPublisherToastModifier(
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
    
    @ViewBuilder
    public func toastBus() -> some View {
        
    }
}



#if DEBUG

enum ErrorPublisherToastError: LocalizedError {
    
}

class ErrorPublisherToastTestModel: ObservableObject {
    @Published var error: ErrorPublisherToastError?
}

struct ErrorPublisherToast_PreviewView: View {
    @StateObject var viewModel = ErrorPublisherToastTestModel()
    
    var body: some View {
        Text("Hello world")
            .toast(publisher: viewModel.$error) { error in
                AlertToast(displayMode: .hud, type: .error(.red))
            }
    }
}

#endif
