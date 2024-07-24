//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/10.
//

import SwiftUI
import Shimmer

public protocol CarouselItem: Hashable, Identifiable {
    #if os(macOS)
    typealias Image = NSImage
    #else
    typealias Image = UIImage
    #endif
    var id: ID { get }
    var idString: String { get }
    /// image for detail (open viewer)
    var image: Image? { get }
}

extension CarouselItem where ID == UUID {
    var idString: String {
        self.id.uuidString
    }
}

extension CarouselItem where ID == String {
    var idString: String {
        self.id
    }
}
 
public struct Carousel<I>: View where I: CarouselItem {
    @Binding var images: [I]
    
    public init(images: Binding<[I]>) {
        self._images = images
    }
    
    @State private var currentIndex: Int = 0
    
    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                VStack {
                    Center(.horizontal) {
                        if let image = images[currentIndex].image {
                            ThumbnailImage(
                                image,
                                height: 200,
                                cacheID: images[currentIndex].idString
                            ) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .shimmering()
                        }
                    }
                    .padding(.horizontal, 40)
                    .frame(height: geometry.size.height * 0.78)
                    .overlay {
                        HStack {
                            Button {
                                currentIndex = max(0, currentIndex - 1)
                                withAnimation(.easeInOut(duration: 2)) {
                                    proxy.scrollTo(images[currentIndex].id, anchor: .center)
                                }
                            } label: {
                                Image(systemSymbol: .chevronBackward)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 20)
                            }
                            .contentShape(Rectangle())
                            .disabled(currentIndex <= 0)
                            
                            Spacer()
                            
                            Button {
                                currentIndex = min(currentIndex + 1, images.count - 1)
                                withAnimation(.easeInOut(duration: 2)) {
                                    proxy.scrollTo(images[currentIndex].id, anchor: .center)
                                }
                            } label: {
                                Image(systemSymbol: .chevronForward)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 20)
                            }
                            .contentShape(Rectangle())
                            .disabled(currentIndex >= images.count - 1)
                        }
                        .buttonStyle(.text(square: true))
                        .controlSize(.large)
                        .opacity(self.images.count > 1 ? 1 : 0)
                    }
                    
                    navigator(
                        proxy,
                        itemSize: min(geometry.size.width / 6, geometry.size.height * 0.2)
                    )
                    .frame(maxWidth: geometry.size.width / 3 * 2)
                }
            }
        }
    }
    
    @ViewBuilder
    func navigator(_ proxy: ScrollViewProxy, itemSize: CGFloat) -> some View {
        let spacing: CGFloat = 10
        let maxCount = 5
        let count = min(maxCount, self.images.count)
        Center(.horizontal) {
            Group {
                if #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) {
                    ScrollView(.horizontal) {
                        HStack(spacing: spacing) {
                            navigatorItems(proxy, size: itemSize)
                                .scrollTransition(
                                    .animated.threshold(.visible(0.9)),
                                    axis: .horizontal
                                ) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.75)
                                }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                } else {
                    ScrollView(.horizontal) {
                        HStack(spacing: spacing) {
                            navigatorItems(proxy, size: itemSize)
                        }
                    }
                }
            }
            .frame(width: Double(count) * itemSize + max(0, Double(count)) * spacing)
        }
    }
        
    
    @ViewBuilder
    func navigatorItems(_ proxy: ScrollViewProxy, size: CGFloat) -> some View {
        ForEach(Array(images.enumerated()), id: \.element) { i, item in
            if let image = item.image {
                ThumbnailImage(image, height: 40, cacheID: item.idString) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .id(item.id)
                        .frame(width: max(0, size-2), height: max(0, size-2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay {
                            if currentIndex == i {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            }
                        }
                        .padding(2)
                        .onTapGesture {
                            currentIndex = i
                            withAnimation(.easeInOut(duration: 2)) {
                                proxy.scrollTo(images[i].id, anchor: .center)
                            }
                        }
                }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .id(item.id)
                    .shimmering()
                    .frame(width: size, height: size)
            }
        }
    }
}

#if DEBUG
struct CarouselImage: CarouselItem {
    #if os(macOS)
    typealias PlatformImage = NSImage
    #elseif os(iOS)
    typealias PlatformImage = UIImage
    #endif
    
    static var preview: [CarouselImage] {
        [
            .init(id: UUID(), image: PlatformImage(named: "testimg0")),
            .init(id: UUID(), image: PlatformImage(named: "testimg1"))
        ]
    }
    
    var id: UUID
    var image: PlatformImage?
    
    init(id: UUID, image: PlatformImage?) {
        self.id = id
        self.image = image
    }
}

#Preview {
    Carousel(images: .constant(CarouselImage.preview))
}
#endif
