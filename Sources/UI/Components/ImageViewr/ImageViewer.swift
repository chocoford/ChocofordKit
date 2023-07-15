//
//  ImageViewer.swift
//  TrickleAnyway
//
//  Created by Chocoford on 2023/2/8.
//

import SwiftUI
import Shimmer
import SDWebImageSwiftUI

public struct ImageViewer<Content: View>: View {
    var image: Image?
    var url: URL?
    var imageSize: CGSize?
    
    var disabled: Bool = false
    var content: () -> Content
    
    
#if os(macOS)
    @State private var currentWindow: NSWindow? = nil
#elseif os(iOS)
    @State private var showViewer = false
    @State var dragOffset: CGSize = CGSize.zero
    @State var dragOffsetPredicted: CGSize = CGSize.zero
    @State private var backgroundOpacity: Double = 1.0
#endif
    
    public init(url: URL?, imageSize: CGSize? = nil, disabled: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.image = nil
        self.url = url
        self.disabled = disabled
        self.content = content
        self.imageSize = imageSize
    }
    
    public init(image: Image, imageSize: CGSize? = nil, disabled: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.image = image
        self.url = nil
        self.disabled = disabled
        self.content = content
        self.imageSize = imageSize
    }
    
    public var body: some View {
        content()
            .onTapGesture {
#if os(macOS)
                openViewer()
#elseif os(iOS)
                withAnimation {
                    showViewer = true
                    backgroundOpacity = 1
                }
#endif
            }
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
    
#if os(macOS)
    func openViewer() {
        if let window = currentWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        let window = NSWindow(contentRect: .init(origin: .zero, size: .init(width: 800, height: 500)),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: true)
        window.animationBehavior = .documentWindow
        let view: ImageViewerView = ImageViewerView(url: url, image: image)

        let contentView = NSHostingView(rootView: view)
        window.contentView = contentView
        window.isReleasedWhenClosed = false // important
        NSApp.activate(ignoringOtherApps: true)
        window.animator().makeKeyAndOrderFront(nil)
        window.animator().center()
        window.isMovable = true
        window.backgroundColor = .black
        window.level = .modalPanel
        window.titleVisibility = .hidden
        
        if let screen = window.screen,
           let imageSize = self.imageSize {
            window.animator().setContentSize(.init(width: min(imageSize.width, screen.frame.width * 0.9),
                                        height: min(imageSize.height, screen.frame.height * 0.9)))
        }
        
        currentWindow = window
        var observer: NSKeyValueObservation? = nil
        observer = window.observe(\.screen) { window, screen in
            if screen.newValue == nil {
                currentWindow = nil
                observer?.invalidate()
                observer = nil
            }
        }
    }
#elseif os(iOS)
    func openViewer() {
        
    }
#endif
}

extension View {
    @ViewBuilder
    public func imageViewer(image: Image, imageSize: CGSize? = nil, disabled: Bool = false) -> some View {
        ImageViewer(image: image, imageSize: imageSize, disabled: disabled) {
            self
        }
    }
    
    @ViewBuilder
    public func imageViewer(url: URL?, imageSize: CGSize? = nil, disabled: Bool = false) -> some View {
        ImageViewer(url: url, imageSize: imageSize, disabled: disabled) {
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
            WebImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)

        }
    }
}
#endif
