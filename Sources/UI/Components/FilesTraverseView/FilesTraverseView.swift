//
//  FilesTraverseView.swift
//
//
//  Created by Dove Zachary on 2023/11/16.
//

import SwiftUI
import SFSafeSymbols


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
public struct FilesTraverseView<T>: View {
    var fileTraverse: FileTraverser<T>?
    var passthroughView: AnyView
    
    public init<C: View>(
        fileTraverse: FileTraverser<T>?,
        @ViewBuilder passthroughView: () -> C
    ) {
        self.fileTraverse = fileTraverse
        self.passthroughView = AnyView(passthroughView())
    }
    
    
//    public init<C: View>(
//        urls: [URL],
//        resourceKeys: [URLResourceKey],
//        enumerateOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants],
//        errorHandleScheme: FilesTraverseErrorHandleScheme = .skip,
//        action: @escaping (URL, URLResourceValues) async throws -> T,
//        onCompletion: @escaping (Error?) -> Void = { _ in },
//        @ViewBuilder passthroughView: () -> C
//    ) {
//        self.fileTraverse = FileTraverser(
//            urls: urls,
//            resourceKeys: resourceKeys,
//            enumerateOptions: enumerateOptions,
//            errorHandleScheme: errorHandleScheme,
//            action: action,
//            onCompletion: onCompletion
//        )
//        self.passthroughView = AnyView(passthroughView())
//    }
    
    var config = Config()
    
    @State private var showPassthroughView: Bool = false
    
    public var body: some View {
        content()
            .onChange(of: self.fileTraverse?.state) {
                showPassthroughView = false
            }
            .apply(watchURLs, isActive: config.autoTraverse)
    }
    
    @ViewBuilder
    func content() -> some View {
        if showPassthroughView || self.fileTraverse == nil {
            passthroughView
        } else if let fileTraverse = self.fileTraverse {
            Group {
                switch fileTraverse.state {
                    case .ready:
                        Text("Ready")
                        
                    case .inProgress:
                        indexingView(fileTraverse)
                        
                    case .cancelled:
                        Text("Cancelled")
                        
                    case .finished:
                        finishedView(fileTraverse)
                        
                    case .failed:
                        failedView(/*error: error*/)
                }
            }
            .controlSize(.large)
            .frame(maxWidth: 400)
            .padding(20)
        }
    }
    
    
    @ViewBuilder
    func indexingView(_ fileTraverse: FileTraverser<T>) -> some View {
        VStack {
            Text("Indexing...")
                .font(.title)
            
            ProgressView(value: Double(fileTraverse.progress.doneCount),
                         total: Double(fileTraverse.progress.totalCount))
                .padding(.horizontal, 50)
            
            if let url = fileTraverse.currentTraversingURL {
                Text(url.filePath)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Button(role: .cancel) {
                fileTraverse.abort()
            } label: {
                Text("Cancel...")
            }
            .disabled(true)
        }
    }

    @ViewBuilder
    private func failedView(/*error: Error*/) -> some View {
        VStack {
            Image(systemSymbol: .checkmarkCircle)
                .resizable()
                .scaledToFit()
                .frame(height: 64)
                .foregroundStyle(.tertiary)
            
            Text("Failed")
                .font(.title)
                .font(.largeTitle)
            
            Button {
                Task {
                    await self.fileTraverse?.start()
                }
            } label: {
                Text("Retry")
            }
            .buttonStyle(.borderedProminent)
            
            Button {
                self.showPassthroughView = true
            } label: {
                Text("Cancel")
            }
        }
    }
    
    @ViewBuilder
    private func finishedView(_ fileTraverse: FileTraverser<T>) -> some View {
        VStack {
            Image(systemSymbol: .checkmarkCircle)
                .resizable()
                .scaledToFit()
                .frame(height: 64)
                .foregroundStyle(.tertiary)
            
            Text("Indexing success")
                .font(.largeTitle)
            
            if let error = fileTraverse.error {
                VStack(alignment: .leading) {
                    Text("but some are failed...")
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(fileTraverse.failedItems, id: \.self) { url in
                                Hover(animation: .default) { isHover in
                                    HStack {
                                        let path: String = url.filePath
                                        
                                        let folderPath: String = url.deletingLastPathComponent().filePath
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
                    .frame(maxHeight: 200)
                }
            }
            
            Button {
                self.showPassthroughView = true
            } label: {
                Text("Done")
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    func watchURLs<Content: View>(content: Content) -> some View {
        content
            .onChange(of: self.fileTraverse?.urls, initial: true) { oldValue, newValue in
                if newValue?.isEmpty == false {
                    onURLsChanged()
                }
            }
    }
    
    private func onURLsChanged() {
        guard self.fileTraverse?.state != .inProgress else { return }
        Task {
            await self.fileTraverse?.start()
        }
    }
}

@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension FilesTraverseView {
    struct FinishedView: View {
        var onContinue: () -> Void
        
        var body: some View {
            VStack {
                Image(systemSymbol: .checkmarkCircle)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .foregroundStyle(.tertiary)
                
                Text("Success")
                    .font(.largeTitle)
                
                Button {
                    onContinue()
                } label: {
                    Text("Done")
                        .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
            }
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


#if DEBUG
#Preview {
    VStack {
        if #available(macOS 14.0, *) {
            
        } else {
            // Fallback on earlier versions
        }
    }
    .frame(width: 500)
    .padding()
}
#endif
