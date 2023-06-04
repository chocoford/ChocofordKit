//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI
import SDWebImageSwiftUI

//struct ImageViewerView: View {
//    var url: URL?
//
//    init(url: URL?) {
//        self.url = url
//    }
//
//    @State var dragOffset: CGSize = CGSize.zero
//    @State var dragOffsetPredicted: CGSize = CGSize.zero
//
//    @State private var scale: CGFloat = 1
//    @State private var previousScale: CGFloat = 1
//
//    var body: some View {
//        Color
//            .windowBackgroundColor
//            .overlay {
//                GeometryReader { geometry in
//                    ScrollView([.horizontal, .vertical]) {
//                        Center {
//                            WebImage(url: url)
//                                .placeholder {
//                                    Rectangle()
//                                        .frame(width: geometry.size.width, height: geometry.size.height)
//                                        .shimmering()
//                                }
//                                .resizable()
////                                .scaleEffect(scale)
//                                .aspectRatio(contentMode: .fit)
////                                .offset(x: self.dragOffset.width, y: self.dragOffset.height)
////                                .rotationEffect(.init(degrees: Double(self.dragOffset.width / 30)))
//                                .frame(width: geometry.size.width * scale,
//                                       height: geometry.size.height * scale,
//                                       alignment: .center)
//                        }
//                    }
//                    .simultaneousGesture(
//                        MagnificationGesture()
////                            .updating($scale) { currentState, gestureState, transaction in
////                                   gestureState = currentState
////                               }
//                            .onChanged({ scale in
//                                self.scale += scale - previousScale
//                                previousScale = scale
//                            })
//                            .onEnded({ _ in
//                                previousScale = 1
//
////                                if scale < 1 {
////                                    withAnimation(.default.delay(0.5)) {
////                                        scale = 1
////                                    }
////                                }
//                            })
//                    )
//                }
//            }
//    }
//}


struct ImageViewerView: View {
    struct ImageSizeKey: PreferenceKey {
        static var defaultValue: CGSize = .zero

        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    var url: URL?
    
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        ZoomableScrollView(url: url, size: imageSize) {
            WebImage(url: url)
                .placeholder {
                    Rectangle().shimmering()
                }
#if os(iOS)
                .resizable()
#endif
                .aspectRatio(contentMode: .fit)
#if os(macOS)
                .offset(x: imageSize.width / 2, y: -1 * imageSize.height / 2)
#endif
                
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ImageSizeKey.self, value: geometry.size)
                            .onChange(of: geometry.size) { newValue in
                                self.imageSize = newValue
                                print(newValue)
                            }
                    }
                }
        }
        .ignoresSafeArea()
        .onPreferenceChange(ImageSizeKey.self) {
            self.imageSize = $0
        }
        .onAppear {
            
        }
    }
    
//    @ViewBuilder
//    func imageView() -> some View {
//#if os(macOS)
//        imageView_macOS()
//#elseif os(iOS)
//        imageView_iOS()
//#endif
//    }
//
//    @ViewBuilder
//    func imageView_iOS() -> some View {
//            WebImage(url: url)
//                .placeholder {
//                    Rectangle().shimmering()
//                }
//                .aspectRatio(contentMode: .fit)
//    }
//
//    @ViewBuilder
//    func imageView_macOS() -> some View {
//        WebImage(url: url)
//            .placeholder {
//                Rectangle().shimmering()
//            }
//            .aspectRatio(contentMode: .fit)
//            .offset(x: imageSize.width / 2, y: -1 * imageSize.height / 2)
//    }
}

struct ImageViewerView_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerView(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
    }
}
