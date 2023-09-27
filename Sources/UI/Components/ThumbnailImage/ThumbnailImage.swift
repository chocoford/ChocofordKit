//
//  ThumbnailImage.swift
//
//
//  Created by Dove Zachary on 2023/9/26.
//

import SwiftUI

var thumbnailImagesCache: [ThumbnailImage.ThumbnailImage : ThumbnailImage.ThumbnailImage] = [:]

public struct ThumbnailImageWrapper<P: View>: ViewModifier {
#if canImport(AppKit)
    public typealias ThumbnailImage = NSImage
#elseif canImport(UIKit)
    public typealias ThumbnailImage = UIImage
#endif
    
    var sourceImage: ThumbnailImage
    var thumbnailSize: CGSize
    var placeholder: () -> P
    
    public init(_ sourceImage: ThumbnailImage,
                thumbnailSize: CGSize,
                @ViewBuilder placeholder: @escaping () -> P = {
        Center { ProgressView().controlSize(.small) }
    }) {
        self.sourceImage = sourceImage
        self.thumbnailSize = thumbnailSize
        self.placeholder = placeholder
    }
    
    @State private var thumbnail: ThumbnailImage? = nil
    
    public func body(content: Content) -> some View {
        if let thumbnail = thumbnail {
#if canImport(AppKit)
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
#elseif canImport(UIKit)
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
#endif
        } else {
            placeholder()
                .task {
                    await loadThumbnail()
                }
        }
    }
    
    @MainActor
    func loadThumbnail() async {
        if thumbnailImagesCache.count > 20 {
            _ = thumbnailImagesCache.dropFirst(10)
        }
        if let thumbnail = thumbnailImagesCache[self.sourceImage] {
            self.thumbnail = thumbnail
            return
        }
        self.thumbnail = await self.sourceImage.byPreparingThumbnail(ofSize: thumbnailSize)
        thumbnailImagesCache[self.sourceImage] = self.thumbnail
    }
}

public struct ThumbnailImage<P: View>: View {
#if canImport(AppKit)
    public typealias ThumbnailImage = NSImage
#elseif canImport(UIKit)
    public typealias ThumbnailImage = UIImage
#endif
    
    var srouceImage: ThumbnailImage
    var thumbnailSize: CGSize
    var placeholder: () -> P
    
    public init(_ srouceImage: ThumbnailImage,
                thumbnailSize: CGSize,
                @ViewBuilder placeholder: @escaping () -> P = {
        Center { ProgressView().controlSize(.small) }
    }) {
        self.srouceImage = srouceImage
        self.thumbnailSize = thumbnailSize
        self.placeholder = placeholder
    }
    
    @State private var thumbnail: ThumbnailImage? = nil
    
    public var body: some View {
        if let thumbnail = thumbnail {
#if canImport(AppKit)
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
#elseif canImport(UIKit)
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
#endif
        } else {
            placeholder()
                .onAppear {
                    loadThumbnail()
                }
        }
    }
    
    func loadThumbnail() {
        Task { @MainActor in
            self.thumbnail = await self.srouceImage.byPreparingThumbnail(ofSize: thumbnailSize)
        }
    }
}

extension Image {
    @ViewBuilder
    public func thumbnail<P: View>(
        _ srouceImage: ThumbnailImageWrapper.ThumbnailImage,
        thumbnailSize: CGSize,
        @ViewBuilder placeholder: @escaping () -> P = {
            Center { ProgressView().controlSize(.small) }
        }
    ) -> some View {
        self.modifier(ThumbnailImageWrapper(srouceImage, thumbnailSize: thumbnailSize, placeholder: placeholder))
    }
}
