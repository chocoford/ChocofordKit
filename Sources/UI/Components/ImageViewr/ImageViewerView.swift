//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI
import SDWebImageSwiftUI
import CachedAsyncImage
import Shimmer

public struct ImageViewerView: View {
    struct ImageSizeKey: PreferenceKey {
        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    
    let url: URL?
    var thumbnailURL: URL?
    let image: Image?
        
    public enum ImageRenderer {
        case animatableCached
        case cached
        case noCached
    }
    var imageRenderer: ImageRenderer = .cached
    
    @State private var isLoading = false

    init(
        url: URL?,
        thumbnailURL: URL? = nil,
        imageRenderer: ImageRenderer = .animatableCached
    ) {
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.image = nil
        self.imageRenderer = imageRenderer
    }
    
    init(image: Image) {
        self.image = image
        self.imageRenderer = .cached
        self.url = nil
        self.thumbnailURL = nil
    }
    
    @State private var imageSize: CGSize = .zero
#if os(macOS)
    @State private var window: NSWindow? = nil
#endif
    
    public var body: some View {
        ZStack {
            GeometryReader { geometry in
                Color.clear.preference(key: ImageSizeKey.self, value: geometry.size)
                    .watchImmediately(of: geometry.size) { newValue in
                        self.imageSize = newValue
                    }
            }
            
            ZoomableScrollView(size: imageSize) {
                Group {
                    if let image = image {
                        imageView(image: image)
                    } else {
                        asyncImageView()
                    }
                }
#if os(macOS)
                .offset(x: imageSize.width / 2, y: -1 * imageSize.height / 2)
#endif
            }
        }
        .ignoresSafeArea()
        .onPreferenceChange(ImageSizeKey.self) {
            self.imageSize = $0
        }
        .onAppear {
            /// will be called every time view appears.
            if self.image == nil {
                isLoading = true
            }
        }
        .overlay {
            Center {
                ProgressView()
            }
            .opacity(isLoading ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private func asyncImageView() -> some View {
        Group {
            switch imageRenderer {
                case .noCached:
                    AsyncImage(url: url) { phase in
                        switch phase {
                            case .success(let image):
                                imageView(image: image)
                                    .onAppear {
                                        DispatchQueue.main.async {
                                            isLoading = false
                                        }
                                    }
                            case .failure(let error):
                                if thumbnailURL != nil {
                                    thumbnailImageView()
                                } else {
                                    Center {
                                        Text(error.localizedDescription)
                                    }
                                    .onAppear {
                                        DispatchQueue.main.async {
                                            isLoading = false
                                        }
                                    }
                                }
                                
                            default:
                                if thumbnailURL != nil {
                                    thumbnailImageView()
                                } else {
                                    EmptyView()
                                }
                        }
                    }
                case .cached:
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                            case .success(let image):
                                imageView(image: image)
                                    .onAppear {
                                        DispatchQueue.main.async {
                                            isLoading = false
                                        }
                                    }
                            case .failure(let error):
                                if thumbnailURL != nil {
                                    thumbnailImageView()
                                } else {
                                    Center {
                                        Text(error.localizedDescription)
                                    }
                                    .onAppear {
                                        DispatchQueue.main.async {
                                            isLoading = false
                                        }
                                    }
                                }
                                
                            default:
                                if thumbnailURL != nil {
                                    thumbnailImageView()
                                } else {
                                    EmptyView()
                                }
                                
                        }
                    }
                case .animatableCached:
                    WebImage(url: url)
                        .placeholder {
                            thumbnailImageView()
                        }
                        .onSuccess(perform: { _, _, _ in
                            isLoading = false
                        })
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize == .zero ? nil : imageSize.width,
                               height: imageSize == .zero ? nil : imageSize.height)
            }
        }
    }
    
    @ViewBuilder
    private func thumbnailImageView() -> some View {
        switch imageRenderer {
            case .noCached:
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                        case .success(let image):
                            imageView(image: image)
                                .onAppear {
                                    DispatchQueue.main.async {
                                        isLoading = false
                                    }
                                }
                        case .failure(let error):
                            Center {
                                Text(error.localizedDescription)
                            }
                            .onAppear {
                                DispatchQueue.main.async {
                                    isLoading = false
                                }
                            }
                            
                        default:
                            EmptyView()
                            
                    }
                }
            case .cached:
                CachedAsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                        case .success(let image):
                            imageView(image: image)
                                .onAppear {
                                    DispatchQueue.main.async {
                                        isLoading = false
                                    }
                                }
                        case .failure(let error):
                            Center {
                                Text(error.localizedDescription)
                            }
                            .onAppear {
                                DispatchQueue.main.async {
                                    isLoading = false
                                }
                            }
                            
                        default:
                            EmptyView()
                    }
                }
            case .animatableCached:
                WebImage(url: thumbnailURL)
                    .onSuccess(perform: { _, _, _ in
                        isLoading = false
                    })
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize == .zero ? nil : imageSize.width,
                           height: imageSize == .zero ? nil : imageSize.height)

        }
    }
    
    @ViewBuilder
    private func imageView(image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: imageSize == .zero ? nil : imageSize.width,
                   height: imageSize == .zero ? nil : imageSize.height)
    }
}

struct ImageViewerView_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerView(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"), imageRenderer: .cached)
    }
}
