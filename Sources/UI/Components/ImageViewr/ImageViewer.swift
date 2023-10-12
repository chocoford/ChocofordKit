//
//  ImageViewer.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/8.
//

import SwiftUI
import Shimmer
import CachedAsyncImage

public struct ImageViewer<Content: View/*, Activator: View*/>: View {
    var isPresent: Binding<Bool>?
    
    var image: Image?
    var url: URL?
    var imageSize: CGSize?
    var imageRenderer: ImageViewerView.ImageRenderer
    
    var disabled: Bool = false
    var content: () -> Content
    
//    typealias ActivatorBuilder<V> = (_ action: () -> Void, _ content: V) -> Activator
//    var activator: ActivatorBuilder?
    
#if os(macOS)
    @State private var currentWindow: NSWindow? = nil
#elseif os(iOS)
    @State private var showViewer = false
    @State var dragOffset: CGSize = CGSize.zero
    @State var dragOffsetPredicted: CGSize = CGSize.zero
    @State private var backgroundOpacity: Double = 1.0
#endif
    
//    public init(url: URL?, imageSize: CGSize? = nil, disabled: Bool = false, 
//                @ViewBuilder content: @escaping () -> Content,
//                @ViewBuilder activator: @escaping (_ action: () -> Void) -> Activator) {
//        self.image = nil
//        self.url = url
//        self.disabled = disabled
//        self.imageSize = imageSize
//        self.content = content
//        self.activator = activator
//    }
    public init(isPresent: Binding<Bool>? = nil, url: URL?, imageSize: CGSize? = nil, disabled: Bool = false,
                imageRenderer: ImageViewerView.ImageRenderer = .animatableCached,
                @ViewBuilder content: @escaping () -> Content) /*where Activator == EmptyView*/ {
        self.isPresent = isPresent
        self.image = nil
        self.url = url
        self.disabled = disabled
        self.imageSize = imageSize
        self.content = content
        self.imageRenderer = imageRenderer
//        self.activator = nil
    }
    
//    public init(image: Image, imageSize: CGSize? = nil, disabled: Bool = false,
//                @ViewBuilder content: @escaping () -> Content,
//                @ViewBuilder activator: @escaping (_ action: () -> Void) -> Activator) {
//        self.image = image
//        self.url = nil
//        self.disabled = disabled
//        self.content = content
//        self.imageSize = imageSize
//        self.activator = activator
//    }

    public init(isPresent: Binding<Bool>? = nil, image: Image, imageSize: CGSize? = nil, disabled: Bool = false,
                imageRenderer: ImageViewerView.ImageRenderer = .animatableCached,
                @ViewBuilder content: @escaping () -> Content)/* where Activator == EmptyView*/ {
        self.isPresent = isPresent
        self.image = image
        self.url = nil
        self.disabled = disabled
        self.content = content
        self.imageSize = imageSize
        self.imageRenderer = imageRenderer
//        self.activator = nil
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
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if let window = notification.object as? NSWindow,
                   window == self.currentWindow {
                    self.currentWindow?.close()
                    self.isPresent?.wrappedValue = false
                }
            }
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
                        ImageViewerView(url: url, image: image)
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


extension ImageViewer {
    func openViewer() {
#if os(macOS)
        if let window = currentWindow {
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
            self.currentWindow = window
        }
        
        guard let window = self.currentWindow else { return }
        
        let view: ImageViewerView = ImageViewerView(url: url, image: image, imageRenderer: imageRenderer)
        
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
        
        currentWindow = window
#elseif os(iOS)
        withAnimation {
            showViewer = true
            backgroundOpacity = 1
        }
#endif
    }
    
    func closeViewer() {
#if os(macOS)
        self.currentWindow?.close()
#elseif os(iOS)
        withAnimation {
            showViewer = false
            backgroundOpacity = 0
        }
#endif
    }
}

extension View {
//    @ViewBuilder
//    public func imageViewer<A: View>(image: Image, imageSize: CGSize? = nil, disabled: Bool = false,
//                            @ViewBuilder activator: @escaping (_ action: () -> Void) -> A) -> some View {
//        ImageViewer(image: image, imageSize: imageSize, disabled: disabled) {
//            self
//        } activator: { action in
//            activator(action)
//        }
//    }
    @ViewBuilder
    public func imageViewer(isPresent: Binding<Bool>? = nil, image: Image, imageSize: CGSize? = nil, disabled: Bool = false, imageRenderer: ImageViewerView.ImageRenderer = .animatableCached) -> some View {
        ImageViewer(isPresent: isPresent, image: image, imageSize: imageSize, disabled: disabled, imageRenderer: imageRenderer) {
            self
        }
    }
    
//    @ViewBuilder
//    public func imageViewer<A: View>(url: URL?, imageSize: CGSize? = nil, disabled: Bool = false,
//                                     @ViewBuilder activator: @escaping (_ action: () -> Void) -> A) -> some View {
//        ImageViewer(url: url, imageSize: imageSize, disabled: disabled) {
//            self
//        } activator: { action in
//            activator(action)
//        }
//    }
    @ViewBuilder
    public func imageViewer(isPresent: Binding<Bool>? = nil, url: URL?, imageSize: CGSize? = nil, disabled: Bool = false, imageRenderer: ImageViewerView.ImageRenderer = .animatableCached) -> some View {
        ImageViewer(isPresent: isPresent, url: url, imageSize: imageSize, disabled: disabled, imageRenderer: imageRenderer) {
            self
        }
    }
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
        ImageViewer(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"), imageSize: .init(width: 896, height: 1344)) {
            CachedAsyncImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large")) {
                $0
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                
            }
            
            .frame(width: 200, height: 200)
            
        }
    }
}
#endif
