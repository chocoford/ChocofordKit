//
//  SwiftyGifView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 28/7/22.
//

import SwiftUI
import SwiftyGif

#if os(macOS)
public struct SwiftyGifView: NSViewRepresentable {
	let url: URL
	var animating = true
	var resetWhenNotAnimating = false
    var quality: GifLevelOfIntegrity = .highestNoFrameSkipping

    public func makeNSView(context: Context) -> SwiftyGifNSView {
		let view = SwiftyGifNSView(url: url, quality: quality)
		view.isAnimating = animating
		if !animating { view.currentFrame = 0 }
		return view
	}

    public func updateNSView(_ view: SwiftyGifNSView, context: Context) {
		view.isAnimating = animating
		if resetWhenNotAnimating, !animating { view.currentFrame = 0 }
	}
}
#elseif os(iOS)
@available(iOS 13.0, *)
public struct SwiftyGifView: UIViewRepresentable {
    let url: URL
    var animating = true
    var resetWhenNotAnimating = false
    var quality: GifLevelOfIntegrity = .highestNoFrameSkipping

    public func makeUIView(context: Context) -> SwiftyGifUIView {
        let view = SwiftyGifUIView(url: url, quality: quality)
        view.isAnimating = animating
        if !animating { view.currentFrame = 0 }
        return view
    }

    public func updateUIView(_ view: SwiftyGifUIView, context: Context) {
        view.isAnimating = animating
        if resetWhenNotAnimating, !animating { view.currentFrame = 0 }
    }
}
#endif


#if DEBUG
struct MacEditorTextView_Previews: PreviewProvider {
	static var previews: some View {
		SwiftyGifView(url: URL(string: "https://c.tenor.com/0KEvxoQb5a4AAAAC/doubt-press-x.gif")!)
	}
}
#endif
