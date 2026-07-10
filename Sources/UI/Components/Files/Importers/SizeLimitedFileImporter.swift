//
//  SizeLimitedFileImporter.swift
//
//
//  Created by Dove Zachary on 2023/10/22.
//
#if canImport(SwiftUI)

import SwiftUI
import UniformTypeIdentifiers
import ChocofordEssentials

// MARK: - SizeLimitedFileImporter
struct SizeLimitedFileImporter: ViewModifier {
    var isPresented: Binding<Bool>
    var allowedContentTypes: [UTType]
    var allowsMultipleSelection: Bool
    var maxSize: Int
    var onCompletion: (Result<[URL], Error>) -> Void
    
    @State private var showAlert = false
    
    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: isPresented,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: allowsMultipleSelection
            ) { result in
                do {
                    let urls: [URL] = try result.get()
                    
                    if urls.contains(where: {
                        if let size = $0.getFileSize(), size < maxSize {
                            return false
                        }
                        return true
                    }) {
                        showAlert = true
                    } else {
                        onCompletion(.success(urls))
                    }
                } catch {
                    onCompletion(.failure(error))
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button {
                    showAlert.toggle()
                } label: {
                    Text("OK")
                }
            } message: {
                Text("Some of them have exceeded the maximum size limit: \(maxSize.fileSizeFormatted())")
            }
    }
}

extension View {
    @ViewBuilder
    public func fileImporter(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool,
        maxSize: Int,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        modifier(SizeLimitedFileImporter(isPresented: isPresented, allowedContentTypes: allowedContentTypes, allowsMultipleSelection: allowsMultipleSelection, maxSize: maxSize, onCompletion: onCompletion))
    }
}
#endif
