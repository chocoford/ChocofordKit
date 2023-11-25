//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

var draggableCache: [String : URL] = [:]

extension View {
    @ViewBuilder
    public func fileDraggable(data: Data?, utType: UTType, cacheID: String? = nil) -> some View {
        onDrag {
            guard let data = data else { return .init() }
            if let cacheID = cacheID,
               let url = draggableCache[cacheID] {
                return .init(object: url as NSURL)
            }
            
            do {
                let filename: String
                if let fileExtension = utType.preferredFilenameExtension {
                    filename = "\(UUID()).\(fileExtension)"
                } else {
                    filename = "\(UUID())"
                }
                let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename, conformingTo: utType)
                try data.write(to: url)
                
                if let cacheID = cacheID {
                    draggableCache[cacheID] = url
                }
                
                return .init(object: url as NSURL)
            } catch {
                return .init()
            }
        }
    }
}
