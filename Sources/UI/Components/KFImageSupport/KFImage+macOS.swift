//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/9.
//

#if os(macOS)
import Foundation
import SwiftUI
import Kingfisher

public struct AnimatedImage: NSViewRepresentable {
    public typealias NSViewType = NSImageView

    let resource: KF.ImageResource
    var options: KingfisherOptionsInfo?
    var isLoaded: Binding<Bool>?
    var animates = true
    var imageScaling: NSImageScaling = .scaleProportionallyDown

    public func makeNSView(context: Context) -> NSViewType {
        let nsView = NSViewType()
        nsView.wantsLayer = true
        nsView.translatesAutoresizingMaskIntoConstraints = false
        nsView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        nsView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return nsView
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.imageScaling = imageScaling
        nsView.animates = animates

        nsView.kf.setImage(with: resource, options: options) { _ in
            DispatchQueue.main.async {
                self.isLoaded?.wrappedValue = true
            }
        }
    }
}

public extension AnimatedImage {
    init(
        url: URL,
        options: KingfisherOptionsInfo? = nil,
        isLoaded: Binding<Bool>? = nil,
        animates: Bool = true,
        imageScaling: NSImageScaling = .scaleProportionallyDown
    ) {
        let resource = KF.ImageResource(downloadURL: url)

        self.init(
            resource: resource,
            options: options,
            isLoaded: isLoaded,
            animates: animates,
            imageScaling: imageScaling
        )
    }
}

#endif
