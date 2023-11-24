//
//  FilesTraverseView.swift
//
//
//  Created by Dove Zachary on 2023/11/16.
//

import SwiftUI

public enum FilesTraverseErrorHandleScheme {
    case skip
    case abort
}

@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension FilesTraverseView {
    public enum UserEvent {
        case cancel
        case finish
    }
}

@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public struct FilesTraverseView: View {

    var fileTraverse: FileTraverser
    
    public init(fileTraverse: FileTraverser, onUserEvent: (UserEvent) -> Void = { _ in }) {
        self.fileTraverse = fileTraverse
    }
    
    public init(
        urls: [URL],
        resourceKeys: [URLResourceKey],
        enumerateOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants],
        errorHandleScheme: FilesTraverseErrorHandleScheme = .skip,
        action: @escaping (URL, URLResourceValues) async throws -> Void,
        onCompletion: @escaping (Error?) -> Void = { _ in },
        onUserEvent: (UserEvent) -> Void = { _ in }
    ) {
        self.fileTraverse = FileTraverser(
            urls: urls,
            resourceKeys: resourceKeys,
            enumerateOptions: enumerateOptions,
            errorHandleScheme: errorHandleScheme,
            action: action,
            onCompletion: onCompletion
        )
//        self.onUserDone = onUserDone
    }
    
    var config = Config()
    
    public var body: some View {
        content()
            .controlSize(.large)
            .frame(maxWidth: 400)
            .padding(20)
            .apply(watchURLs, isActive: config.autoTraverse)
    }
    
    @ViewBuilder
    func content() -> some View {
        switch self.fileTraverse.state {
            case .ready:
                Text("Ready")
            case .inProgress:
                indexingView()
                
            case .cancelled:
                Text("Cancelled")
                
            case .finished:
                if let error = self.fileTraverse.error {
                    errorView(error)
                } else {
                    Text("Done")
                }
            case .error:
                if let error = self.fileTraverse.error {
                    errorView(error)
                } else {
                    Text("Error")
                }
        }
    }
    
    @ViewBuilder
    func indexingView() -> some View {
        VStack {
            Text("Indexing...")
                .font(.title)
            
            ProgressView(value: Double(self.fileTraverse.progress.doneCount),
                         total: Double(self.fileTraverse.progress.totalCount))
                .padding(.horizontal, 50)
            
            if let url = self.fileTraverse.currentTraversingURL {
                let path: String = {
                    if #available(macOS 13.0, iOS 16.0, *) {
                        url.path(percentEncoded: false)
                    } else {
                        url.path
                    }
                }()
                
                Text(path)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Button(role: .cancel) {
                self.fileTraverse.abort()
            } label: {
                Text("Cancel...")
            }
            .disabled(true)
        }
    }
    
    @ViewBuilder
    func errorView(_ error: Error) -> some View {
        if self.fileTraverse.failedItems.isEmpty {
            VStack {
                Text("Error")
                    .font(.title)
                
                Text(error.localizedDescription)
                
                Button {
//                    showSheet = false
//                    onUserDone()
                } label: {
                    Text("OK")
                }
            }
        } else {
            VStack {
                Text("Indexing done, but some are failed...")
                    .font(.title)
                
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(self.fileTraverse.failedItems, id: \.self) { url in
                            Hover(animation: .default) { isHover in
                                HStack {
                                    let path: String = {
                                        if #available(macOS 13.0, iOS 16.0, *) {
                                            url.absoluteURL.path(percentEncoded: false)
                                        } else {
                                            url.absoluteURL.path
                                        }
                                    }()
                                    let folderPath: String = {
                                        if #available(macOS 13.0, iOS 16.0, *) {
                                            url.deletingLastPathComponent().absoluteURL.path(percentEncoded: false)
                                        } else {
                                            url.deletingLastPathComponent().absoluteURL.path
                                        }
                                    }()
                                    Text(path)
#if os(macOS)
                                    if isHover {
                                        Button {
                                            NSWorkspace.shared.selectFile(
                                                path,
                                                inFileViewerRootedAtPath: folderPath
                                            )
                                        } label: {
                                            Image(systemName: "arrowshape.right.circle.fill")
                                        }
                                        .buttonStyle(.borderless)
                                        .controlSize(.small)
                                    }
#endif
                                    Spacer(minLength: 0)
                                }
                                .lineLimit(1)
                            }
                        }
                    }
                }
                
                Button {
//                    showSheet = false
//                    onUserDone()
                } label: {
                    Text("OK")
                }
            }
        }
    }
    
    @ViewBuilder
    func watchURLs<Content: View>(content: Content) -> some View {
//        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onChange(of: self.fileTraverse.urls, initial: true) { oldValue, newValue in
                    if !newValue.isEmpty {
                        onURLsChanged()
                    }
                }
//        } else {
//            content
//                .watchImmediately(of: self.fileTraverse.urls) { newValue in
//                    if !newValue.isEmpty {
//                        onURLsChanged()
//                    }
//                }
//        }
    }
    
    private func onURLsChanged() {
        guard self.fileTraverse.state != .inProgress else { return }
        Task {
            await self.fileTraverse.start()
        }
    }
}

@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension FilesTraverseView {
    class Config {
        var autoTraverse: Bool = false
    }
    
    public func autoTraverse(_ enabled: Bool = true) -> FilesTraverseView {
        self.config.autoTraverse = enabled
        return self
    }
}
