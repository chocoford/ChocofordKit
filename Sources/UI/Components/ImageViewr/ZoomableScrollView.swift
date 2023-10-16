//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI

#if os(macOS)
class CenteredClipView: NSClipView {
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {

            if (rect.size.width > containerView.frame.size.width) {
                rect.origin.x = (containerView.frame.width - rect.width) / 2
            }

            if(rect.size.height > containerView.frame.size.height) {
                rect.origin.y = (containerView.frame.height - rect.height) / 2
            }
        }

        return rect
    }
}

struct ZoomableScrollView<Content: View>: NSViewRepresentable {
    var size: CGSize
    private var content: () -> Content
    
    init(size: CGSize, @ViewBuilder content: @escaping () -> Content) {
        self.size = size
        self.content = content
    }
    
    @State private var previousSize: CGSize = .zero

  func makeNSView(context: Context) -> NSScrollView {
      let scrollView = NSScrollView()
      scrollView.contentView = CenteredClipView()
      scrollView.maxMagnification = 20
      scrollView.minMagnification = 0.1
      scrollView.allowsMagnification = true
      
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalScroller = true
      
      scrollView.borderType = .noBorder
      scrollView.backgroundColor = .clear
      
      scrollView.autoresizingMask = [.width, .height]
      let view = NSView(frame: .init(origin: .zero, size: size))
      let imageView = NSHostingView(rootView: content())
      view.addSubview(imageView)
      scrollView.documentView = view
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
//      print("updateNSView", scrollView.documentVisibleRect, size)
    // update the hosting controller's SwiftUI content
//    context.coordinator.hostingController.rootView = self.content
//    assert(context.coordinator.hostingController.view.superview == uiView)
//      nsView.documentView?.setBoundsSize(size)
//      print(size)
      let view = NSView(frame: .init(origin: .zero, size: size))
      let imageView = NSHostingView(rootView: content())
      view.addSubview(imageView)
      scrollView.documentView = view

      if previousSize != size {
          let initialScale = min(scrollView.documentVisibleRect.size.width / size.width, scrollView.documentVisibleRect.size.height / size.height)
          scrollView.setMagnification(initialScale,
                                      centeredAt: .init(x: 0, y: 0))
          scrollView.maxMagnification = max(10, initialScale * 50)
          scrollView.minMagnification = min(0.01, initialScale * 0.01)
      }
      DispatchQueue.main.async {
          previousSize = size
    }
      
      
//      if let url = url,
//         let image = NSImage(contentsOf: url) {
//          print("image loadeed.", image)
//          let view = NSView(frame: .init(origin: .zero, size: .init(width: 1000, height: 2000)))
//          view.addSubview(NSImageView(image: image))
//          view.layout()
//          let imageView = NSImageView(image: image)
//          imageView.image = image
//          scrollView.documentView = view
//      }
  }
}
#elseif os(iOS)
class CenteredZoomingScrollView: UIScrollView {
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        let contentSize = self.contentSize
        let scrollViewSize = self.bounds.size
        var contentOffset = contentOffset
        
        if (contentSize.width < scrollViewSize.width) {
            contentOffset.x = -(scrollViewSize.width - contentSize.width) / 2.0
        }
        
        if (contentSize.height < scrollViewSize.height) {
            contentOffset.y = -(scrollViewSize.height - contentSize.height) / 2.0
        }
        
        super.setContentOffset(contentOffset, animated: animated)
    }
}


struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: () -> Content
    private var size: CGSize
    
    init(size: CGSize, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.size = size
    }
    
    @State private var previousSize: CGSize = .zero

    
    func makeUIView(context: Context) -> UIScrollView {
        // set up the UIScrollView
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator  // for viewForZooming(in:)
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 0.1
        scrollView.bouncesZoom = true
        
        // create a UIHostingController to hold our SwiftUI content
        // UIHostingController(rootView: contentView).view! //
        let hostedView = context.coordinator.hostingController.view!
        hostedView.backgroundColor = .clear
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        return scrollView
    }
    
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // update the hosting controller's SwiftUI content
        context.coordinator.hostingController.rootView = self.content()
        assert(context.coordinator.hostingController.view.superview == scrollView)
    }
    
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content()))
    }

    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIScrollViewDelegate {
//        let scrollView = UIScrollView()
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let offsetX = max((scrollView.bounds.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height) * 0.5, 0)
            if scrollView.contentSize.width < scrollView.bounds.width && scrollView.contentSize.height < scrollView.bounds.height {
                scrollView.subviews.first?.center = .init(x: offsetX, y: offsetY)
            }
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scrollView.contentSize.width >= scrollView.bounds.width || scrollView.contentSize.height >= scrollView.bounds.height {
                view?.center = .init(x: scrollView.contentSize.width / 2, y: scrollView.contentSize.height / 2)
            }
        }
    }
}
#endif



#if DEBUG
struct ZoomableScrollView_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerView(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
            .previewLayout(.fixed(width: 800, height: 800))
    }
}
#endif
