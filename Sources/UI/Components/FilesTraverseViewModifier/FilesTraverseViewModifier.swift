//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/14.
//

import SwiftUI

public enum FilesTraverseErrorHandleScheme {
    case skip
    case abort
}

struct FilesTraverseViewModifier: ViewModifier {
    @Binding var urls: [URL]
    var resourceKeys: [URLResourceKey]
    var action: (URL, URLResourceValues) async throws -> Void
    
    var errorHandleScheme: FilesTraverseErrorHandleScheme
    
    init(
        urls: Binding<[URL]>,
        resourceKeys: [URLResourceKey] = [],
        errorHandleScheme: FilesTraverseErrorHandleScheme = .skip,
        action: @escaping (URL, URLResourceValues) async throws -> Void
    ) {
        self._urls = urls
        self.resourceKeys = resourceKeys
        self.errorHandleScheme = errorHandleScheme
        self.action = action
    }
    
    private var totalCount: Double { Double(allItems.count) }
    @State private var isTraversing = false
    @State private var showSheet = false
    @State private var doneCount: Double = 0
    @State private var currentURL: URL? = nil
    @State private var allItems: [URL] = []
    
    @State private var failedURLs: [URL] = []
    @State private var error: Error? = nil
    
    let enumerateOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
    
    func body(content: Content) -> some View {
        content
            .apply(watchURLs)
            .sheet(isPresented: $showSheet, onDismiss: {
                onDismiss()
            }) {
                Center {
                    Group {
                        if isTraversing {
                            VStack {
                                Text("Indexing...")
                                    .font(.title)
                                
                                ProgressView(value: doneCount, total: totalCount)
                                    .frame(maxWidth: 300)
                                
                                if let url = self.currentURL {
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
                                    showSheet = false
                                } label: {
                                    Text("Cancel...")
                                }
                                .disabled(true)
                            }
                        } else if let error = error {
                            if failedURLs.isEmpty {
                                VStack {
                                    Text("Error")
                                        .font(.title)
                                    
                                    Text(error.localizedDescription)
                                    
                                    Button(role: .cancel) {
                                        showSheet = false
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
                                            ForEach(self.failedURLs, id: \.self) { url in
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
                                                        Spacer(minLength: 0)
                                                    }
                                                    .lineLimit(1)
                                                }
                                            }
                                        }
                                    }
                                    
                                    Button(role: .cancel) {
                                        showSheet = false
                                    } label: {
                                        Text("OK")
                                    }
                                }
                            }
                        }
                    }
                    .controlSize(.large)
                    .frame(maxWidth: 400)
                }
            }
    }
    
    @ViewBuilder
    func watchURLs<Content: View>(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onChange(of: self.urls, initial: true) { oldValue, newValue in
                    if !newValue.isEmpty {
                        onURLsChanged()
                    }
                }
        } else {
            content
                .watchImmediately(of: self.urls) { newValue in
                    if !newValue.isEmpty {
                        onURLsChanged()
                    }
                }
        }
    }
    
    private func onURLsChanged() {
        guard !isTraversing else { return }
        withAnimation {
            self.showSheet = true
        }
        Task {
            await self.performTraverse()
        }
    }
    
    private func performTraverse() async {
        isTraversing = true
        prepareURLs()
        for url in allItems {
            do {
                let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
                try await action(url, resourceValues)
            } catch {
                dump(error)
                self.error = error
                if case .abort = self.errorHandleScheme {
                    break
                } else {
                    failedURLs.append(url)
                }
            }
            self.doneCount += 1
        }
        isTraversing = false
        
        if self.failedURLs.isEmpty && self.error == nil {
            self.showSheet = false
        }
    }
    
    private func prepareURLs() {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.nameKey]
        for url in self.urls {
//            _ = url.startAccessingSecurityScopedResource()
//            defer { url.stopAccessingSecurityScopedResource() }
            var isDirectory = ObjCBool(false)
            let path: String = {
                if #available(macOS 13.0, iOS 16.0, *) {
                    url.absoluteURL.path(percentEncoded: false)
                } else {
                    url.absoluteURL.path
                }
            }()
            guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else { continue }
            
            if !isDirectory.boolValue {
                allItems.append(url)
                continue
            }
            
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: resourceKeys,
                options: enumerateOptions,
                errorHandler: { url, error in
                    print(url, error)
                    return true
                }
            ) else {
                continue
            }

            for case let subURL as URL in enumerator {
                allItems.append(subURL)
            }
        }
    }
    
    private func onDismiss() {
        isTraversing = false
        doneCount = 0
        currentURL = nil
        allItems = []
        failedURLs = []
        error = nil
        self.urls = []
    }
}

extension View {
    @ViewBuilder
    public func filesTraverseSheet(
        urls: Binding<[URL]>,
        resourceKeys: [URLResourceKey] = [],
        errorHandleScheme: FilesTraverseErrorHandleScheme = .skip,
        action: @escaping (URL, URLResourceValues) async throws -> Void
    ) -> some View {
        modifier(
            FilesTraverseViewModifier(
                urls: urls,
                resourceKeys: resourceKeys,
                errorHandleScheme: errorHandleScheme,
                action: action
            )
        )
    }
}


#if DEBUG
//#Preview {
//    FilesTravellingView()
//}
#endif
