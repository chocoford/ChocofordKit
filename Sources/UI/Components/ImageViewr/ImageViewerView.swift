//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI
import SDWebImageSwiftUI
import Shimmer

struct ImageViewerView: View {
    struct ImageSizeKey: PreferenceKey {
        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    let url: URL?
    let image: Image?
    
    @State private var isLoading = false

    init(url: URL?, image: Image? = nil) {
        self.url = url
        self.image = image
    }
    
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        ZoomableScrollView(size: imageSize) {
            Group {
                if let image = image {
                    image
#if os(iOS)
                        .resizable()
#endif
                        .aspectRatio(contentMode: .fit)
                } else {
                    WebImage(url: url, options: [.fromLoaderOnly])
//                        .onProgress(perform: { cur, total in
//                            if cur < total {
//                                isLoading = true
//                            } else {
//                                DispatchQueue.main.async {
//                                    isLoading = false
//                                }
//                            }
//                        })
                        .onSuccess(perform: { _, _, _ in
                            withAnimation {
                                isLoading = false
                            }
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
