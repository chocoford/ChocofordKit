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
        image: Image? = nil,
        imageRenderer: ImageRenderer = .animatableCached
    ) {
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.image = image
        self.imageRenderer = imageRenderer
    }
    
    @State private var imageSize: CGSize = .zero
    
    public var body: some View {
        ZoomableScrollView(size: imageSize) {
            imageRenderer(url: url)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ImageSizeKey.self, value: geometry.size)
                            .onChange(of: geometry.size) { newValue in
                                self.imageSize = newValue
                            }
                    }
                }
        }
        .ignoresSafeArea()
        .onPreferenceChange(ImageSizeKey.self) {
            self.imageSize = $0
        }
        .onAppear {
            isLoading = true
        }
        .overlay {
            Center {
                ProgressView()
            }
            .opacity(isLoading ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private func imageRenderer() -> some View {
        Group {
            switch imageRenderer {
                case .noCached:
                    AsyncImage(url: url) { phase in
                        switch phase {
                            case .success(let image):
                                image
#if os(iOS)
                                    .resizable()
#endif
                                    .aspectRatio(contentMode: .fit)
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
                                image
#if os(iOS)
                                    .resizable()
#endif
                                    .aspectRatio(contentMode: .fit)
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
#if os(iOS)
                        .resizable()
#endif
                        .aspectRatio(contentMode: .fit)
            }
        }
#if os(macOS)
        .offset(x: imageSize.width / 2, y: -1 * imageSize.height / 2)
#endif
    }
    
    @ViewBuilder
    private func thumbnailImageView() -> some View {
        switch imageRenderer {
            case .noCached:
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                        case .success(let image):
                            image
#if os(iOS)
                                .resizable()
#endif
                                .aspectRatio(contentMode: .fit)
                                .onAppear {
                                    DispatchQueue.main.async {
                                        isLoading = false
                                    }
                                }
                        case .failure(let error):
                            if let image = image {
                                placeholderImageView()
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
                            if let image = image {
                                placeholderImageView()
                            } else {
                                EmptyView()
                            }
                            
                    }
                }
            case .cached:
                CachedAsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                        case .success(let image):
                            image
#if os(iOS)
                                .resizable()
#endif
                                .aspectRatio(contentMode: .fit)
                                .onAppear {
                                    DispatchQueue.main.async {
                                        isLoading = false
                                    }
                                }
                        case .failure(let error):
                            if let image = image {
                                placeholderImageView()
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
                            if let image = image {
                                placeholderImageView()
                            } else {
                                EmptyView()
                            }
                            
                    }
                }
            case .animatableCached:
                WebImage(url: thumbnailURL)
                    .placeholder {
                        placeholderImageView()
                    }
                    .onSuccess(perform: { _, _, _ in
                        isLoading = false
                    })
#if os(iOS)
                    .resizable()
#endif
                    .aspectRatio(contentMode: .fit)
        }
    }
    
    @ViewBuilder
    private func placeholderImageView() -> some View {
        if let image = image {
            image
#if os(iOS)
                .resizable()
#endif
                .aspectRatio(contentMode: .fit)
        } else {
            Center {
                ProgressView().controlSize(.small)
            }
        }
    }
}

struct ImageViewerView_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerView(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"), imageRenderer: .noCached)
        
//        WebImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
//            .placeholder {
//                ProgressView()
//            }
        
    }
}
