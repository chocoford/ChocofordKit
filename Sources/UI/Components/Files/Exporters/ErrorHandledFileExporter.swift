//
//  ErrorHandledFileExporter.swift
//
//
//  Created by Dove Zachary on 2023/10/22.
//

//#if canImport(SwiftUI)
//
//import SwiftUI
//import UniformTypeIdentifiers
//
//internal struct ErrorHandledFileExporter: ViewModifier {
//    @Binding var isPresented: Bool
//    var allowedContentTypes: [UTType]
//    var allowsMultipleSelection: Bool
//    var onCompletion: ([URL]) async throws -> Void
//    var onCancellation: (() -> Void)? = nil
//    
//    @State private var error: Error? = nil
//    
//    var showAlert: Binding<Bool> {
//        Binding {
//            self.error != nil
//        } set: { val in
//            if !val {
//                self.error = nil
//            }
//        }
//
//    }
//    
//    func body(content: Content) -> some View {
//        Group {
//            if #available(macOS 14.0, iOS 17.0, macCatalyst 17.0, visionOS 1.0, *),
//               let onCancellation = onCancellation {
//                content
//                    .fileExporter { result in
//                        Task {
//                            do {
//                                let urls: [URL] = try result.get()
//                                try await onCompletion(urls)
//                            } catch {
//#if DEBUG
//                                dump(error)
//#endif
//                                self.error = error
//                            }
//                        }
//                    } onCancellation: {
//                        onCancellation()
//                    }
//            } else {
//                content
//                    .fileImporter(
//                        isPresented: $isPresented,
//                        allowedContentTypes: allowedContentTypes,
//                        allowsMultipleSelection: allowsMultipleSelection
//                    ) { result in
//                        Task {
//                            do {
//                                let urls: [URL] = try result.get()
//                                try await onCompletion(urls)
//                            } catch {
//#if DEBUG
//                                dump(error)
//#endif
//                                self.error = error
//                            }
//                        }
//                    }
//            }
//        }
//        .alert("Error", isPresented: showAlert) {
//            Button {
//                showAlert.wrappedValue.toggle()
//            } label: {
//                Text("OK")
//            }
//        } message: {
//            if let error = self.error {
//                Text("Import failed: \(error.localizedDescription)")
//            } else {
//                Text("Import failed")
//            }
//        }
//    }
//}
//
//extension View {
//    @ViewBuilder
//    public func fileExporterWithAlert(
//        isPresented: Binding<Bool>,
//        allowedContentTypes: [UTType],
//        allowsMultipleSelection: Bool,
//        onCompletion: @escaping ([URL]) async throws -> Void
//    ) -> some View {
//        modifier(ErrorHandledFileExporter(
//            isPresented: isPresented,
//            allowedContentTypes: allowedContentTypes,
//            allowsMultipleSelection: allowsMultipleSelection,
//            onCompletion: onCompletion
//        ))
//    }
//    
//    @available(macOS 14.0, *, iOS 17.0, macCatalyst 17.0, visionOS 1.0, *)
//    @ViewBuilder
//    public func fileExporterWithAlert(
//        isPresented: Binding<Bool>,
//        allowedContentTypes: [UTType],
//        allowsMultipleSelection: Bool,
//        onCompletion: @escaping ([URL]) async throws -> Void,
//        onCancellation: @escaping () -> Void
//    ) -> some View {
//        modifier(ErrorHandledFileExporter(
//            isPresented: isPresented,
//            allowedContentTypes: allowedContentTypes,
//            allowsMultipleSelection: allowsMultipleSelection,
//            onCompletion: onCompletion,
//            onCancellation: onCancellation
//        ))
//    }
//}
//
//
//
//#endif
