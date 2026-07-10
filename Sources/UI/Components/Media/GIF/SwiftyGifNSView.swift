//
//  SwiftyGifNSView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 28/7/22.
//
/*
import SwiftUI
import SwiftyGif

#if os(macOS)
public final class SwiftyGifNSView: NSView {
	fileprivate var _animate = true

	private let imageView: NSImageView

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
        imageView = ImageAspectFillView()
		imageView.setGifFromURL(url, levelOfIntegrity: quality)
		super.init(frame: .zero)
		imageView.delegate = self

		addSubview(imageView)
	}

    public override func layout() {
		super.layout()
		imageView.frame = bounds
	}
}

extension SwiftyGifNSView: SwiftyGifDelegate {
    public func gifDidStart(sender: NSImageView) {
		// Ensure the real animating state never desyncs from the required state
		if !_animate {
			isAnimating = false
		} else {
			_animate = true // Update underlying var
		}
	}
    public func gifDidStop(sender: NSImageView) {
		if _animate {
			isAnimating = true
		} else {
			_animate = false // Update underlying var
		}
	}
}


class ImageAspectFillView: NSImageView {
    override var image: NSImage? {
        set {
            self.layer = CALayer()
            self.layer?.contentsGravity = .resizeAspectFill
            self.layer?.contents = newValue
            self.wantsLayer = true
            
            super.image = newValue
        }
        
        get {
            return super.image
        }
    }
}

#endif
*/
