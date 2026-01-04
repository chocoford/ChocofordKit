//
//  ThumbnailImage.swift
//
//
//  Created by Dove Zachary on 2023/9/26.
//

import SwiftUI

var thumbnailImagesCache: [ThumbnailImage.PlatformImage : ThumbnailImage.PlatformImage] = [:]

public struct ThumbnailImageWrapper<P: View>: ViewModifier {
#if canImport(AppKit)
    public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
    public typealias PlatformImage = UIImage
#endif
    
    var sourceImage: PlatformImage
    var thumbnailSize: CGSize
    var placeholder: () -> P
    
    public init(_ sourceImage: PlatformImage,
                thumbnailSize: CGSize,
                @ViewBuilder placeholder: @escaping () -> P = {
        Center { ProgressView().controlSize(.small) }
    }) {
        self.sourceImage = sourceImage
        self.thumbnailSize = thumbnailSize
        self.placeholder = placeholder
    }
    
    @State private var thumbnail: PlatformImage? = nil
    
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
                    loadThumbnail()
                }
        }
    }
    
    @MainActor
    func loadThumbnail() {
        if thumbnailImagesCache.count > 20 {
            _ = thumbnailImagesCache.dropFirst(10)
        }
        if let thumbnail = thumbnailImagesCache[self.sourceImage] {
            self.thumbnail = thumbnail
            return
        }
        self.thumbnail = self.sourceImage.preparingThumbnail(of: thumbnailSize)
        thumbnailImagesCache[self.sourceImage] = self.thumbnail
    }
}
#if os(macOS)
public typealias ThumbnailImageCache = NSCache<NSString, NSImage>
#elseif os(iOS)
public typealias ThumbnailImageCache = NSCache<NSString, UIImage>
#endif
public let deafultThumbnailImageCache: ThumbnailImageCache = {
    let cache = ThumbnailImageCache()
    cache.name = "ThumbnailImageCache"
    return cache
}()

public struct ThumbnailImage<I: View>: View {
#if canImport(AppKit)
    public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
    public typealias PlatformImage = UIImage
#endif
    
    private var id = UUID()
    private var url: URL?
    private var sourceImage: PlatformImage?
    private var cacheID: String?
    private var thumbnailSize: CGSize
    private var cache: ThumbnailImageCache?
    private var image: (Image) -> I
    private var placeholder: AnyView
    
    public init(
        _ sourceImage: PlatformImage?,
        width: CGFloat,
        cacheID: String? = nil,
        cache: ThumbnailImageCache = deafultThumbnailImageCache,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: () -> some View = {
            Center { ProgressView().controlSize(.small) }
        }
    ) {
        let size: CGSize
        if let sourceImage = sourceImage {
            size = CGSize(width: width, height: width * sourceImage.size.height / sourceImage.size.width)
        } else {
            size = CGSize(width: width, height: width)
        }
        self.init(sourceImage, size: size, cacheID: cacheID, cache: cache, image: image, placeholder: placeholder)
    }
    
    public init(
        _ sourceImage: PlatformImage?,
        height: CGFloat,
        cacheID: String? = nil,
        cache: ThumbnailImageCache = deafultThumbnailImageCache,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: () -> some View = {
            Center { ProgressView().controlSize(.small) }
        }
    ) {
        let size: CGSize
        
        if let sourceImage = sourceImage {
            size = CGSize(width:  height * sourceImage.size.width / sourceImage.size.height, height: height)
        } else {
            size = CGSize(width: height, height: height)
        }
        self.init(sourceImage, size: size, cacheID: cacheID, cache: cache, image: image, placeholder: placeholder)
    }
    
    
    public init(
        _ sourceImage: PlatformImage?,
        size thumbnailSize: CGSize,
        cacheID: String? = nil,
        cache: ThumbnailImageCache = deafultThumbnailImageCache,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: () -> some View = {
            Center { ProgressView().controlSize(.small) }
        }
    ) {
        self.sourceImage = sourceImage
        self.thumbnailSize = thumbnailSize
        if let cacheID = cacheID {
            self.cacheID = cacheID
            self.cache = cache
        }
        self.image = image
        self.placeholder = AnyView(placeholder())
    }
    
    public init(
        _ url: URL?,
        height: CGFloat,
        cacheID: String? = nil,
        cache: ThumbnailImageCache = deafultThumbnailImageCache,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: () -> some View = {
            Center { ProgressView().controlSize(.small) }
        }
    ) {
        self.url = url
        self.thumbnailSize = .init(width: height, height: height)
        if let cacheID = cacheID {
            self.cacheID = cacheID
            self.cache = cache
        }
        self.image = image
        self.placeholder = AnyView(placeholder())
    }
    
    @State private var thumbnail: PlatformImage? = nil
    
    public var body: some View {
        if let thumbnail = thumbnail {
#if canImport(AppKit)
            image(Image(nsImage: thumbnail))
#elseif canImport(UIKit)
            image(Image(uiImage: thumbnail))
#endif
        } else {
            placeholder
                .task(id: id) {
                    loadThumbnail()
                    loadThumbnailV2()
                }
        }
    }
    
    func loadThumbnail() {
        guard let sourceImage = self.sourceImage else { return }
        if let cacheID = cacheID {
            let key = NSString(string: "\(cacheID)-\(Int(thumbnailSize.width))x\(Int(thumbnailSize.height))")
            if let thumbnail = self.cache?.object(forKey: key) {
                self.thumbnail = thumbnail
            } else if let thumbnail = sourceImage.preparingThumbnail(of: thumbnailSize) {
//            } else {
//                let thumbnail = sourceImage.byPreparingThumbnail(of: thumbnailSize)
                self.thumbnail = thumbnail
                self.cache?.setObject(thumbnail, forKey: key)
            } else {
                self.thumbnail = sourceImage
            }
        } else {
            self.thumbnail = sourceImage.preparingThumbnail(of: thumbnailSize)
        }
    }
    
    func loadThumbnailV2() {
        guard let url = self.url else { return }
        #if os(macOS)
        DispatchQueue.global(qos: .userInitiated).async {
            if let cacheID = cacheID {
                let key = NSString(string: "\(cacheID)-\(Int(thumbnailSize.width))x\(Int(thumbnailSize.height))")
                if let thumbnail = self.cache?.object(forKey: key) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.thumbnail = thumbnail
                        }
                    }
                } else if let thumbnail = NSImage.byPreparingThumbnail(
                    from: url, 
                    height: max(thumbnailSize.width, thumbnailSize.height)
                ) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.thumbnail = thumbnail
                        }
                    }
                    self.cache?.setObject(thumbnail, forKey: key)
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.thumbnail = NSImage.byPreparingThumbnail(from: url, height: max(thumbnailSize.width, thumbnailSize.height))
                    }
                }
            }
        }
#elseif os(iOS)
        DispatchQueue.global(qos: .userInitiated).async {
            if let cacheID = cacheID {
                let key = NSString(string: "\(cacheID)-\(Int(thumbnailSize.width))x\(Int(thumbnailSize.height))")
                if let thumbnail = self.cache?.object(forKey: key) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.thumbnail = thumbnail
                        }
                    }
                } else if let thumbnail = UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: thumbnailSize) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.thumbnail = thumbnail
                        }
                    }
                    self.cache?.setObject(thumbnail, forKey: key)
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation {
                        self.thumbnail = UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: thumbnailSize)
                    }
                }
            }
        }
#endif
    }
}

extension Image {
    @ViewBuilder
    public func thumbnail<P: View>(
        _ srouceImage: ThumbnailImageWrapper.PlatformImage,
        thumbnailSize: CGSize,
        @ViewBuilder placeholder: @escaping () -> P = {
            Center { ProgressView().controlSize(.small) }
        }
    ) -> some View {
        self.modifier(ThumbnailImageWrapper(srouceImage, thumbnailSize: thumbnailSize, placeholder: placeholder))
    }
}
