//
//  AsyncThumbnailImage.swift
//
//
//  Created by Dove Zachary on 2023/9/26.
//

import SwiftUI

public struct AsyncThumbnailImage: View {
#if canImport(AppKit)
    public typealias Image = NSImage
#elseif canImport(UIKit)
    public typealias Image = UIImage
#endif
    var configurations: [(SwiftUI.Image) -> SwiftUI.Image] = []

    var config: Config = .init()

    var url: URL?
    
#if canImport(AppKit)
    var placeholder: AnyView = AnyView(SwiftUI.Image(nsImage: Image()))
#elseif canImport(UIKit)
    var placeholder: AnyView = AnyView(SwiftUI.Image(uiImage: Image()))
#endif

    
    public init(url: URL?) {
        self.url = url
    }
    
    @State private var image: Image? = nil
    @State private var isBeginLoading: Bool = false

    public var body: some View {
        if let image = image {
#if canImport(AppKit)
            SwiftUI.Image(nsImage: image)
#elseif canImport(UIKit)
            SwiftUI.Image(uiImage: image)
#endif
        } else {
            self.placeholder
                .onAppear { loadImage() }
        }
    }
    
    @MainActor
    func loadImage() {
        guard let url = url else {
            return
        }
#if canImport(AppKit)
        guard let image = NSImage(contentsOf: url) else {
            return
        }
#elseif canImport(UIKit)
        guard let image = UIImage(contentsOfFile: url.path) else {
            return
        }
#endif
        
        if let size = self.config.preferThumbnailSize {
            self.image = image.preparingThumbnail(of: size)
        } else {
            self.image = image
        }
    }
}

extension AsyncThumbnailImage {
    final class Config: ObservableObject {
        var preferThumbnailSize: CGSize?
        
        
        init() { }
    }
    
    public func placeholder<P: View>(@ViewBuilder _ placeholder: @escaping () -> P) -> AsyncThumbnailImage {
        var view = self
        view.placeholder = AnyView(placeholder())
        return view
    }
    
    public func preferThumbnailSize(_ size: CGSize) -> AsyncThumbnailImage {
        self.config.preferThumbnailSize = size
        return self
    }
    
    func configure(_ block: @escaping (SwiftUI.Image) -> SwiftUI.Image) -> AsyncThumbnailImage {
        var result = self
        result.configurations.append(block)
        return result
    }
    
    /// Configurate this view's image with the specified cap insets and options.
    /// - Parameter capInsets: The values to use for the cap insets.
    /// - Parameter resizingMode: The resizing mode
    public func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: SwiftUI.Image.ResizingMode = .stretch) -> AsyncThumbnailImage
    {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }
    
    /// Configurate this view's rendering mode.
    /// - Parameter renderingMode: The resizing mode
    public func renderingMode(_ renderingMode: SwiftUI.Image.TemplateRenderingMode?) -> AsyncThumbnailImage {
        configure { $0.renderingMode(renderingMode) }
    }
    
    /// Configurate this view's image interpolation quality
    /// - Parameter interpolation: The interpolation quality
    public func interpolation(_ interpolation: SwiftUI.Image.Interpolation) -> AsyncThumbnailImage {
        configure { $0.interpolation(interpolation) }
    }
    
    /// Configurate this view's image antialiasing
    /// - Parameter isAntialiased: Whether or not to allow antialiasing
    public func antialiased(_ isAntialiased: Bool) -> AsyncThumbnailImage {
        configure { $0.antialiased(isAntialiased) }
    }
}

#if DEBUG
#Preview {
    VStack {
        AsyncThumbnailImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    .frame(width: 500, height: 500)
}
#endif
