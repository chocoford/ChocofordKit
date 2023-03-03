//
//  ImageViewer.swift
//  TrickleAnyway
//
//  Created by Dove Zachary on 2023/2/8.
//

import SwiftUI
import Shimmer

public struct ImageViewer<Content: View>: View {
    var url: URL
    var disabled: Bool = false
    var content: () -> Content

    public init(url: URL, disabled: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.url = url
        self.disabled = disabled
        self.content = content
    }
    
    public var body: some View {
        content()
            .onTapGesture {
                openViewer()
            }
    }
    
#if os(macOS)
    func openViewer() {
        let window = NSWindow(contentRect: .zero,
                              styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered,
                              defer: true)
        let contentView = NSHostingView(rootView: ImageWindowView(url: url,
                                                                  window: window))
        window.contentView = contentView
        window.isReleasedWhenClosed = true // important
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.center()
        window.isMovable = true
        window.backgroundColor = .black
        window.level = .floating
    }
#elseif os(iOS)
    func openViewer() {
        
    }
    
#endif
}

#if os(macOS)
struct ImageWindowView: View {
    var url: URL
    var window: NSWindow?

    @State private var hovering = false
    @State private var hoveringButton = false
    
    @State private var isMouseIn = false
    @State private var mouseMoveHandler: Any? = nil
    
    @State private var scale: CGFloat = 1.0
    @State private var scaleAnchor: UnitPoint = .zero
    @State private var offset: CGSize = .zero
    
    @State private var originSize: CGSize = .zero
    
    // TODO: can not handle image which width lager than 1440
    var body: some View {
//        navigationWrapper {
        ZStack {
            if url.pathExtension == "gif" {
                SwiftyGifView(url: url)
            } else {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .scaleEffect(scale, anchor: scaleAnchor)
                            .offset(offset)
                            .onAppear {
                                DispatchQueue.main.async {
                                    window?.center()
                                    originSize = window?.frame.size ?? .zero
                                }
                            }
                    } else if phase.error != nil {
                        Text("Error occured!")
                    } else {
                        Rectangle()
                            .frame(width: 500, height: 300)
                            .shimmering()
                    }
                }
            }
//            VStack {
//                Text(scale.description)
//                Text("\(scaleAnchor.x), \(scaleAnchor.y)")
//                Text(offset.description)
//                Text(originSize.description)
//            }
        }
        .onAppear {
            mouseMoveHandler = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) {
                guard isMouseIn else { return $0 }
                originSize = window?.frame.size ?? .zero
                offset.width += $0.scrollingDeltaX * (1 / scale)
                offset.height += $0.scrollingDeltaY * (1 / scale)
                scaleAnchor = UnitPoint(x: 1 - (offset.width / originSize.width + 0.5),
                                        y: 1 - (offset.height / originSize.height + 0.5))
                return $0
            }
        }
        .onDisappear {
            if let handler = mouseMoveHandler {
                NSEvent.removeMonitor(handler)
                mouseMoveHandler = nil
            }
        }
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged({ value in
                    originSize = window?.frame.size ?? .zero
                    scale *= (value - 1) * 0.1 + 1
                })
        )
        .onHover { hover in
            withAnimation {
                hovering = hover
            }
            isMouseIn = hover
        }
        .frame(maxWidth: 1440, maxHeight: 900)
//        }
    }
    
    @ViewBuilder
    func navigationWrapper<V: View>(@ViewBuilder content: @escaping () -> V) -> some View {
        if #available(macOS 13.0, *), #available(iOS 16.0, *) {
            NavigationStack {
                content()
            }
        } else {
            // Fallback on earlier versions
            NavigationView {
                content()
            }
        }
    }
}
#endif

#if os(macOS)
struct ZoomableScrollView<Content: View>: NSViewRepresentable {
    var url: URL
    private var content: () -> Content
    
    init(url: URL, @ViewBuilder content: @escaping () -> Content) {
        self.url = url
        self.content = content
    }

  func makeNSView(context: Context) -> NSScrollView {
    // set up the UIScrollView
      let scrollView = NSScrollView()
//    scrollView.delegate = context.coordinator  // for viewForZooming(in:)
      scrollView.maxMagnification = 20
      scrollView.minMagnification = 0.1
      scrollView.allowsMagnification = true
      
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalScroller = true
      
      scrollView.borderType = .noBorder
      
      scrollView.autoresizingMask = [.width, .height]
//      scrollView.horizontalScroller =
    // create a UIHostingController to hold our SwiftUI content
//      let hostedView = NSHostingView(rootView: content())
//    let hostedView = context.coordinator.hostingController.view!
//    hostedView.translatesAutoresizingMaskIntoConstraints = true
//    hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//    hostedView.frame = scrollView.bounds
//    scrollView.addSubview(hostedView)
//      scrollView.documentView = NSImageView(image: )
//      NSView(frame: .init(origin: .zero, size: .init(width: 400, height: 400)))

    return scrollView
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }

  func updateNSView(_ nsView: NSScrollView, context: Context) {
    // update the hosting controller's SwiftUI content
//    context.coordinator.hostingController.rootView = self.content
//    assert(context.coordinator.hostingController.view.superview == uiView)
  }

  // MARK: - Coordinator

  class Coordinator {
    
  }
}
#elseif os(iOS)
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
  private var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  func makeUIView(context: Context) -> UIScrollView {
    // set up the UIScrollView
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator  // for viewForZooming(in:)
    scrollView.maximumZoomScale = 20
    scrollView.minimumZoomScale = 1
    scrollView.bouncesZoom = true

    // create a UIHostingController to hold our SwiftUI content
    let hostedView = context.coordinator.hostingController.view!
    hostedView.translatesAutoresizingMaskIntoConstraints = true
    hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    hostedView.frame = scrollView.bounds
    scrollView.addSubview(hostedView)

    return scrollView
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(hostingController: UIHostingController(rootView: self.content))
  }

  func updateUIView(_ uiView: UIScrollView, context: Context) {
    // update the hosting controller's SwiftUI content
    context.coordinator.hostingController.rootView = self.content
    assert(context.coordinator.hostingController.view.superview == uiView)
  }

  // MARK: - Coordinator

  class Coordinator: NSObject, UIScrollViewDelegate {
    var hostingController: UIHostingController<Content>

    init(hostingController: UIHostingController<Content>) {
      self.hostingController = hostingController
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return hostingController.view
    }
  }
}
#endif

#if DEBUG
struct ImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewer(url: URL(string: "https://devres.trickle.so/upload/users/515970908439969793/workspaces/76957788663709699/1675831346133/eberhard-grossgasteiger-HglEta1FvXE-unsplash.jpg?x-oss-process=image/format,jpg/auto-orient,1/resize,w_1440/")!) {
            EmptyView()
        }
    }
}

//struct ImageWindowView_Previews: PreviewProvider {
//    static var previews: some View {
//        ImageWindowView(url: URL(string: "https://devres.trickle.so/upload/users/515970908439969793/workspaces/76957788663709699/1675831346133/eberhard-grossgasteiger-HglEta1FvXE-unsplash.jpg?x-oss-process=image/format,jpg/auto-orient,1/resize,w_2048/")!)
////            .frame(width: 1000, height: 1000)
//    }
//}

#endif
