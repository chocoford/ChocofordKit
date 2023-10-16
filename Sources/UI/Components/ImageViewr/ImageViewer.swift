//
//  ImageViewer.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/8.
//

import SwiftUI
import Shimmer
import CachedAsyncImage

public struct ImageViewer<Content: View>: View {
    @Environment(\.isEnabled) var isEnabled
    
    var isPresent: Binding<Bool>?
    
    var image: Image?
    var url: URL?
    var thumbnailURL: URL?
    var imageSize: CGSize?
    var imageRenderer: ImageViewerView.ImageRenderer
    
    var disabled: Bool { !isEnabled }
    var content: () -> Content
    
#if os(macOS)
//    @State private var currentWindow: NSWindow? = nil
#elseif os(iOS)
    @State private var showViewer = false
    @State var dragOffset: CGSize = CGSize.zero
    @State var dragOffsetPredicted: CGSize = CGSize.zero
    @State private var backgroundOpacity: Double = 1.0
#endif
    
    public init(isPresent: Binding<Bool>? = nil,
                url: URL?,
                thumbnailURL: URL? = nil,
                imageSize: CGSize? = nil,
                imageRenderer: ImageViewerView.ImageRenderer = .animatableCached,
                @ViewBuilder content: @escaping () -> Content) {
        self.isPresent = isPresent
        self.image = nil
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.imageSize = imageSize
        self.content = content
        self.imageRenderer = imageRenderer
    }

    public init(isPresent: Binding<Bool>? = nil, 
                image: Image, imageSize: CGSize? = nil,
                imageRenderer: ImageViewerView.ImageRenderer = .animatableCached,
                @ViewBuilder content: @escaping () -> Content) {
        self.isPresent = isPresent
        self.image = image
        self.url = nil
        self.thumbnailURL = nil
        self.content = content
        self.imageSize = imageSize
        self.imageRenderer = imageRenderer
    }
    
    
    
    public var body: some View {
        content()
            .onTapGesture {
                if self.isPresent != nil { return }
                openViewer()
            }
            .onChange(of: self.isPresent?.wrappedValue) { val in
                guard let val = val else { return }
                if val {
                    openViewer()
                } else {
                    closeViewer()
                }
            }
            .apply(imageViewerOverlay)
#if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if let window = notification.object as? NSWindow,
                   window == imageViewerWindow
                   /*window == self.currentWindow*/ {
                    imageViewerWindow?.close()
                    self.isPresent?.wrappedValue = false
                }
            }
#endif
    }
    
    @ViewBuilder
    private func imageViewerOverlay<C: View>(content: C) -> some View {
        content
#if os(iOS)
            .fullScreenCover(isPresented: $showViewer) {
                let dismissThreshold: Double = 360
                Color.windowBackgroundColor
                    .ignoresSafeArea()
                    .overlay {
                        Group {
                            if let image = image {
                                ImageViewerView(image: image)
                            } else {
                                ImageViewerView(url: url, thumbnailURL: thumbnailURL)
                            }
                        }
                        .offset(x: self.dragOffset.width, y: self.dragOffset.height)
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    self.dragOffset = value.translation
                                    self.dragOffsetPredicted = value.predictedEndTranslation
                                    backgroundOpacity = 1 - Double((abs(self.dragOffset.height) + abs(self.dragOffset.width)) / dismissThreshold)
                                }
                                .onEnded { value in
                                    if (abs(self.dragOffset.height) + abs(self.dragOffset.width) > dismissThreshold) ||
                                        ((abs(self.dragOffsetPredicted.height)) / (abs(self.dragOffset.height)) > 3) ||
                                        ((abs(self.dragOffsetPredicted.width)) / (abs(self.dragOffset.width))) > 3 {
                                        withAnimation(.spring()) {
                                            self.dragOffset = self.dragOffsetPredicted
                                        }
                                        self.showViewer = false
                                        return
                                    }
                                    withAnimation(.interactiveSpring()) {
                                        self.dragOffset = .zero
                                        backgroundOpacity = 1
                                    }
                                }
                        )
                    }
                    .background(BackgroundBlurView())
                    .opacity(backgroundOpacity)
            }
            .onChange(of: showViewer) { show in
                if show {
                    dragOffset = .zero
                    dragOffsetPredicted = .zero
                }
            }
#endif
    }
}

#if os(macOS)
internal var imageViewerWindow: NSWindow? = nil
#endif

extension ImageViewer {
    func openViewer() {
#if os(macOS)
        if let window = imageViewerWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        } else {
            let window = NSWindow(
                contentRect: .init(origin: .zero, size: .init(width: 800, height: 500)),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: true
            )
            window.animationBehavior = .documentWindow
            imageViewerWindow = window
        }
        
        guard let window = imageViewerWindow else { return }
        
        
        let view: ImageViewerView 
        
        if let image = self.image {
            view = ImageViewerView(image: image)
        } else {
            view = ImageViewerView(url: url, thumbnailURL: thumbnailURL, imageRenderer: imageRenderer)
        }
        
        let contentView = NSHostingView(rootView: view)
        window.contentView = contentView
        window.isReleasedWhenClosed = false // important
        window.isMovable = true
        window.backgroundColor = .black
        window.titleVisibility = .hidden
        
        if let screen = window.screen,
           let imageSize = self.imageSize {
            window.animator().setContentSize(.init(width: min(imageSize.width, screen.frame.width * 0.9),
                                                   height: min(imageSize.height, screen.frame.height * 0.9)))
        }
        
        NSApp.activate(ignoringOtherApps: true)
        window.animator().makeKeyAndOrderFront(nil)
        window.animator().center()
        
        imageViewerWindow = window
#elseif os(iOS)
        withAnimation {
            showViewer = true
            backgroundOpacity = 1
        }
#endif
    }
    
    func closeViewer() {
#if os(macOS)
        imageViewerWindow?.close()
#elseif os(iOS)
        withAnimation {
            showViewer = false
            backgroundOpacity = 0
        }
#endif
    }
}

extension View {
    @ViewBuilder
    public func imageViewer(
        isPresent: Binding<Bool>? = nil,
        image: Image,
        imageSize: CGSize? = nil,
        imageRenderer: ImageViewerView.ImageRenderer = .animatableCached
    ) -> some View {
        ImageViewer(isPresent: isPresent, image: image, imageSize: imageSize, imageRenderer: imageRenderer) {
            self
        }
    }
    
    @ViewBuilder
    public func imageViewer(
        isPresent: Binding<Bool>? = nil,
        url: URL?,
        thumbnailURL: URL? = nil,
        imageSize: CGSize? = nil,
        imageRenderer: ImageViewerView.ImageRenderer = .animatableCached
    ) -> some View {
        ImageViewer(isPresent: isPresent, url: url, thumbnailURL: thumbnailURL, imageSize: imageSize, imageRenderer: imageRenderer) {
            self
        }
    }
    
//    @ViewBuilder
//    public func imageViewer(url: Binding<URL?>, disabled: Bool = false) -> some View {
//        modifier(ImageViewerModifier())
//    }
}




#if os(iOS)
struct BackgroundBlurView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif

#if DEBUG
struct ImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack {
                ImageViewer(
                    url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"),
                    imageSize: .init(width: 896, height: 1344)
                ) {
                    CachedAsyncImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large")) {
                        $0
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                    }
                    .frame(width: 200, height: 200)
                }
                
                ImageViewer(
                    url: URL(string: "https://pbs.twimg.com/media/F8Q7Z1aW0AAXGHc?format=jpg&name=medium"),
                    imageSize: .init(width: 896, height: 1344)
                ) {
                    CachedAsyncImage(url: URL(string: "https://pbs.twimg.com/media/F8Q7Z1aW0AAXGHc?format=jpg&name=small")) {
                        $0
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                    }
                    .frame(width: 200, height: 200)
                }

            }
        }
    }
}
#endif
