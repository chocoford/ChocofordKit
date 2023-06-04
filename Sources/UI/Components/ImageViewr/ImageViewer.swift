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
    var url: URL?
    var imageSize: CGSize?
    
    var disabled: Bool = false
    var content: () -> Content
    
    @State private var showViewer = false
    
    @State var dragOffset: CGSize = CGSize.zero
    @State var dragOffsetPredicted: CGSize = CGSize.zero
    @State private var backgroundOpacity: Double = 1.0
    
    public init(url: URL?, imageSize: CGSize? = nil, disabled: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.url = url
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
                        ImageViewerView(url: url)
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
        let window = NSWindow(contentRect: .init(origin: .zero, size: .init(width: 800, height: 500)),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: true)
        
        let view = ImageViewerView(url: url)
        let contentView = NSHostingView(rootView: view)
        window.contentView = contentView
        window.isReleasedWhenClosed = false // important
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.center()
        window.isMovable = true
        window.backgroundColor = .black
        window.level = .floating
        
        if let screen = window.screen,
           let imageSize = self.imageSize {
            window.setContentSize(.init(width: min(imageSize.width, screen.frame.width * 0.9),
                                        height: min(imageSize.height, screen.frame.height * 0.9)))
        }
    }
#elseif os(iOS)
    func openViewer() {
        
    }
    
#endif
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
        ImageViewer(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large")) {
            WebImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)

        }
    }
}
#endif
