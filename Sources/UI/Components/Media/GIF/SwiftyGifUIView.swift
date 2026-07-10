//
//  File.swift
//  
//
//  Created by Chocoford on 2023/2/25.
//
/*
import SwiftUI
import SwiftyGif

#if os(iOS)
public final class SwiftyGifUIView: UIView {
    fileprivate var _animate = true

    private let imageView: UIImageView

    var isAnimating: Bool {
        get { _animate }
        set {
            _animate = newValue
            if newValue {
                imageView.startAnimatingGif()
            } else {
                imageView.stopAnimatingGif()
            }
        }
    }
    var currentFrame: Int {
        get { imageView.currentFrameIndex() }
        set { imageView.showFrameAtIndex(newValue) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(url: URL, quality: GifLevelOfIntegrity, width: Double? = nil, height: Double? = nil) {
        imageView = UIImageView()
        imageView.setGifFromURL(url, levelOfIntegrity: quality)
        super.init(frame: .zero)
        imageView.delegate = self

        addSubview(imageView)
    }

}

extension SwiftyGifUIView: SwiftyGifDelegate {
    public func gifDidStart(sender: UIImageView) {
        // Ensure the real animating state never desyncs from the required state
        if !_animate {
            isAnimating = false
        } else {
            _animate = true // Update underlying var
        }
    }
    public func gifDidStop(sender: UIImageView) {
        if _animate {
            isAnimating = true
        } else {
            _animate = false // Update underlying var
        }
    }
}

#endif

*/
