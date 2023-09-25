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
    let image: Image?
    
    public enum ImageRenderer {
        case sdWebImage
        case cachedAsyncImage
    }
    var imageRenderer: ImageRenderer = .cachedAsyncImage
    
    @State private var isLoading = false

    init(url: URL?, image: Image? = nil, imageRenderer: ImageRenderer = .cachedAsyncImage) {
        self.url = url
        self.image = image
        self.imageRenderer = imageRenderer
    }
    
    @State private var imageSize: CGSize = .zero
    
    public var body: some View {
        ZoomableScrollView(size: imageSize) {
            Group {
                if let image = image {
                    image
#if os(iOS)
                        .resizable()
#endif
                        .aspectRatio(contentMode: .fit)
                } else {
                    switch imageRenderer {
                        case .cachedAsyncImage:
                            CachedAsyncImage(url: url) { phase in
                                switch phase {
                                    case .success(let image):
                                        image
#if os(iOS)
                                            .resizable()
#endif
                                            .aspectRatio(contentMode: .fit)
                                            .onAppear {
                                                isLoading = false
                                            }
                                    default:
                                        EmptyView()
                                        
                                }
                            }
                        case .sdWebImage:
                            WebImage(url: url)
                                .onSuccess(perform: { _, _, _ in
                                    isLoading = false
                                })
        #if os(iOS)
                                .resizable()
        #endif
                                .aspectRatio(contentMode: .fit)
                    }
                   
                }
            }
//#if os(macOS)
//            .offset(x: imageSize.width / 2, y: -1 * imageSize.height / 2)
//#endif
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
            Rectangle()
                .shimmering()
                .opacity(isLoading ? 1 : 0)
        }
    }
}

struct ImageViewerView_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerView(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
        
//        WebImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
//            .placeholder {
//                ProgressView()
//            }
        
    }
}
