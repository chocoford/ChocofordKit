//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/16.
//

import SwiftUI

@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
@Observable
public class FileTraverser {
    public var urls: [URL]
    public var resourceKeys: [URLResourceKey]
    public var enumerateOptions: FileManager.DirectoryEnumerationOptions
    public var errorHandleScheme: FilesTraverseErrorHandleScheme
    public var action: (URL, URLResourceValues) async throws -> Void
    public var onCompletion: (Error?) -> Void
    

    public init(
        urls: [URL],
        resourceKeys: [URLResourceKey] = [],
        enumerateOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants],
        errorHandleScheme: FilesTraverseErrorHandleScheme = .skip,
        action: @escaping (URL, URLResourceValues) async throws -> Void,
        onCompletion: @escaping (Error?) -> Void = { _ in }
    ) {
        self.urls = urls
        self.resourceKeys = resourceKeys
        self.enumerateOptions = enumerateOptions
        self.errorHandleScheme = errorHandleScheme
        self.action = action
        self.onCompletion = onCompletion
    }
    
    public var state: State = .ready
    
    public var currentTraversingURL: URL?
    
    public var allItems: [URL] = []
    public var progress: Progress = .init(doneCount: 0, totalCount: 0)
     
    public var failedItems: [URL] = []
    public var error: Error? = nil
    

    public func start() async {
        guard state != .inProgress else { return }
        state = .inProgress
        await performTraverse()
    }
    
    public func abort() {
        state = .cancelled
    }
    
    private func performTraverse() async {
        prepareURLs()
        
        for url in self.allItems {
                do {
                    self.currentTraversingURL = url
                    let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
                    try await action(url, resourceValues)
                } catch {
                    dump(error)
                    self.error = error
                    if case .abort = self.errorHandleScheme {
                        state = .error
                        break
                    } else {
                        failedItems.append(url)
                    }
                }
                self.progress.doneCount += 1
            }
        
        onCompletion(self.error)
        if self.state != .error {
            state = .finished
        }
    }
    
    private func prepareURLs() {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.nameKey]
        for url in self.urls {
            var isDirectory = ObjCBool(false)
            let path: String = {
//                if #available(macOS 13.0, iOS 16.0, *) {
                    url.absoluteURL.path(percentEncoded: false)
//                } else {
//                    url.absoluteURL.path
//                }
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
                    self.error = error
                    return true
                }
            ) else {
                continue
            }

            for case let subURL as URL in enumerator {
                allItems.append(subURL)
            }
        }
        self.progress.totalCount = self.allItems.count
    }
}

@available(macOS 14.0, iOS 17.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension FileTraverser {
    public struct Progress {
        public var doneCount: Int
        public var totalCount: Int
    }
    
    public enum State {
        case ready
        case inProgress
        case finished
        case cancelled
        case error
    }
}
