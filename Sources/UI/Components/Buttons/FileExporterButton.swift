//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/15.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct FileExporterButton: View {
    var types: [UTType]
    var allowMultiple: Bool
    var onCompletion: ([URL]) async throws -> Void
    var onCancellation: () -> Void
    var label: AnyView
    
    public init(
        types: [UTType],
        allowMultiple: Bool,
        onCompletion: @escaping ([URL]) async throws -> Void,
        onCancellation: @escaping () -> Void = {},
        isImporterPresented: Bool = false,
        @ViewBuilder label: () -> some View
    ) {
        self.types = types
        self.allowMultiple = allowMultiple
        self.onCompletion = onCompletion
        self.onCancellation = onCancellation
        self.isImporterPresented = isImporterPresented
        self.label = AnyView(label())
    }
    
    @State private var isImporterPresented = false
    
    public var body: some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            buttonView()
                .fileImporterWithAlert(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: types,
                    allowsMultipleSelection: allowMultiple,
                    onCompletion: onCompletion,
                    onCancellation: onCancellation
                )
        } else {
            buttonView()
                .fileImporterWithAlert(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: types,
                    allowsMultipleSelection: allowMultiple,
                    onCompletion: onCompletion
                )
        }
    }
    
    @ViewBuilder
    func buttonView() -> some View {
        Button {
            isImporterPresented.toggle()
        } label: {
            self.label
        }
    }
}

#if DEBUG
#Preview {
    FileExporterButton(types: [], allowMultiple: false) { urls in
        
    } label: {
        Text("File Importer")
    }
    .padding()
}
#endif
