//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/4/5.
//

import SwiftUI

public protocol IdentifiableError: Error, Identifiable {
    
}

public struct ErrorsView<E: Error>: View {
    @Binding var errors: [E]
    
    public init(errors: Binding<[E]>) {
        self._errors = errors
    }
    
    public var body: some View {
        List {
            ForEach(Array(errors.enumerated()), id: \.offset) { _, error in
                HStack {
                    Label(error.localizedDescription, systemImage: "exclamationmark.circle.fill")
                }
                .padding(8)
                .background(in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(width: 400)
    }
}

#if os(macOS)
public struct ErrorsViewToolbarButton<E: Error>: View {
    @Binding var errors: [E]
    var preferredEdge: Edge
    
    public init(errors: Binding<[E]>, preferredEdge: Edge = .top) {
        self._errors = errors
        self.preferredEdge = preferredEdge
    }
    
    @State private var show = false
    
    public var body: some View {
        if errors.count > 0 {
            Button {
                show.toggle()
            } label: {
                Image(systemName: "exclamationmark.circle")
            }
            .popover(isPresented: $show, arrowEdge: preferredEdge) {
                ErrorsView(errors: $errors)
            }
        }
    }
}
#endif

#if DEBUG
//struct ErrorsView_Previews: PreviewProvider {
//    static var previews: some View {
//        ErrorsView(errors: .constant([]))
//    }
//}
#endif
