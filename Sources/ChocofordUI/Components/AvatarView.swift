//
//  AvatarView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import SwiftUI
import ShapeBuilder
import SwiftyGif
import SDWebImageSwiftUI

public struct AvatarView<S: StringProtocol>: View {
//    @ObservedObject var imageManager = ImageManager()

    var url: URL?
    var fallbackText: S

    public enum AvatarShape {
        case circle
        case rounded
        case tile
    }
    var shape: AvatarShape = .circle
    var size: CGFloat = 28
    var animating: Bool = true
    
    public init(url: URL?,
                fallbackText: S,
                shape: AvatarShape = .circle,
                size: CGFloat = 28,
                animating: Bool = true) {
        self.url = url
        self.fallbackText = fallbackText
        self.shape = shape
        self.size = size
        self.animating = animating
    }
    
    public init(urlString: String?,
                fallbackText: S,
                shape: AvatarShape = .circle,
                size: CGFloat = 28,
                animating: Bool = true) {
        self.init(url: URL(string: urlString ?? ""), fallbackText: fallbackText, shape: shape, size: size, animating: animating)
    }
    
    var phText: String {
        String(fallbackText).uppercased()
    }
    
    @ShapeBuilder
    var clipShape: some Shape {
        switch shape {
            case .circle:
                Circle()

            case .rounded:
                RoundedRectangle(cornerRadius: ceil(sqrt(size)))

            case .tile:
                Rectangle()
        }
    }
    
    public var body: some View {
        WebImage(url: url, options: [.lowPriority, .scaleDownLargeImages])
            .resizable()
            .placeholder {
                Rectangle()
                    .foregroundColor(.gray)
                    .overlay(alignment: .center) {
                        Text(phText)
                            .font(.system(size: size / 2))
                            .foregroundColor(.white)
                    }
            }
        .frame(width: size, height: size, alignment: .center)
        .clipShape(clipShape)
    }
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(Array(stride(from: 10, through: 100, by: 10)), id: \.self) { size in
                AvatarView(url: nil, fallbackText: "A", size: CGFloat(size))
            }
        }
        
    }
}
#endif
