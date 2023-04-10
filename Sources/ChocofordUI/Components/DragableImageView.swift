//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/4/3.
//

import SwiftUI

#if os(macOS)
public class DragableNSImageView: NSImageView, NSFilePromiseProviderDelegate {
    var fileUrl: URL?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        shadow = NSShadow()
        if let shadow = shadow {
            shadow.shadowOffset = .zero
            shadow.shadowColor = NSColor.gray
            shadow.shadowBlurRadius = 5
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func mouseDown(with event: NSEvent) {
        print("on mouse down")
        guard
            let fileUrl = fileUrl,
            let image = image
        else {
            return
        }
        // Create the dragging item for the drag operation
        let draggingItem = NSDraggingItem(pasteboardWriter: fileUrl as NSURL)
//        let draggingFrame: NSRect = .init(origin: .init(x: self.bounds.origin.x + (self.bounds.size.width - image.size.width) / 2,
//                                                        y: self.bounds.origin.y + (self.bounds.size.height - image.size.height) / 2),
//                                          size: image.size)
        let draggingFrame: NSRect = self.bounds
        draggingItem.setDraggingFrame(draggingFrame, contents: image)
        
        // Start the dragging session
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    
    // MARK: - NSFilePromiseProviderDelegate - useless now
    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return "drag file"
    }
    
    public func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        print("writePromiseTo \(url.path)")
    }
}

extension DragableNSImageView: NSDraggingSource {
    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }
}


public struct DragableImageView: NSViewRepresentable {
    var image: NSImage
    
    var sourceURL: URL
    
    public init(image: CGImage, size: CGSize, sourceURL: URL) {
        self.image = .init(cgImage: image, size: .init(width: size.width, height: size.height))
        self.sourceURL = sourceURL
    }
    
    public init(image: NSImage, sourceURL: URL) {
        self.image = image
        self.sourceURL = sourceURL
    }
    
    public func makeNSView(context: Self.Context) -> DragableNSImageView {
        let dragableView = DragableNSImageView(image: image)
        
        dragableView.fileUrl = sourceURL
        return dragableView
    }

    public func updateNSView(_ dragableView: DragableNSImageView, context: Self.Context) {
        dragableView.image = image
        dragableView.fileUrl = sourceURL
    }
}
#endif
