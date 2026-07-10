//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/9.
//

#if canImport(UIKit)
import Foundation
import SwiftUI

//struct AnimatedImage: UIViewControllerRepresentable {
//    typealias NSViewType = NSImageView
//
//    let resource: ImageResource
//    var options: KingfisherOptionsInfo?
//    var isLoaded: Binding<Bool>?
//    var animates = true
//    var imageScaling: NSImageScaling = .scaleProportionallyDown
//
//    func makeNSView(context: Context) -> NSViewType {
//        let nsView = NSViewType()
//        nsView.wantsLayer = true
//        nsView.translatesAutoresizingMaskIntoConstraints = false
//        nsView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
//        nsView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        return nsView
//    }
//
//    func updateNSView(_ nsView: NSViewType, context: Context) {
//        nsView.imageScaling = imageScaling
//        nsView.animates = animates
//
//        nsView.kf.setImage(with: resource, options: options) { _ in
//            DispatchQueue.main.async {
//                self.isLoaded?.wrappedValue = true
//            }
//        }
//    }
//}

#endif
