//
//  AvatarView.swift
//  CSWang
//
//  Created by Chocoford on 2022/11/30.
//

import SwiftUI
import ShapeBuilder
import CachedAsyncImage

public protocol AvatarUserRepresentable: Hashable, Identifiable {
    associatedtype AvatarURL
    
    var name: String? { get }
    var avatarURL: AvatarURL? { get }
}



public struct AvatarView<V: View>: View {
    public class Config: ObservableObject {
        public enum AvatarShape {
            case circle
            case rounded
            case tile
        }
        
        var shape: AvatarShape
        var size: CGFloat
        
        
        init(shape: AvatarShape = .circle, size: CGFloat = 28) {
            self.shape = shape
            self.size = size
        }
    }
    
    
    var url: URL?
    var fallbackView: () -> V
    var config: Config = .init()
    private var shouldAdjustTextSize = false
    
    public init<S: StringProtocol>(_ url: URL? = nil, fallbackText: S) where V == Text {
        self.url = url
        self.fallbackView = {
            Text(fallbackText)
        }
        self.shouldAdjustTextSize = true
    }
    
    public init<S: StringProtocol>(urlString: String?, fallbackText: S) where V == Text {
        self.init(URL(string: urlString ?? ""), fallbackText: fallbackText)
        self.shouldAdjustTextSize = true
    }
    
    public init(_ url: URL? = nil, @ViewBuilder content: @escaping () -> V) {
        self.url = url
        self.fallbackView = content
    }
    
    public init(urlString: String?, @ViewBuilder content: @escaping () -> V) {
        self.url = URL(string: urlString ?? "")
        self.fallbackView = content
    }
    
    @ShapeBuilder
    var clipShape: some Shape {
        switch config.shape {
            case .circle:
                Circle()

            case .rounded:
                RoundedRectangle(cornerRadius: ceil(sqrt(config.size)))

            case .tile:
                Rectangle()
        }
    }
    
    public var body: some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
        } placeholder: {
            Rectangle()
                .foregroundColor(.gray)
                .overlay(alignment: .center) {
                    if shouldAdjustTextSize {
                        fallbackView()
                            .font(.system(size: config.size / 2))
                            .foregroundColor(.white)
                    } else {
                        fallbackView()
                    }
                }
        }
        .frame(width: config.size, height: config.size, alignment: .center)
        .clipShape(clipShape)
    }
}

public extension AvatarView {
    func size(_ size: CGFloat) -> AvatarView {
        self.config.size = size
        return self
    }
    
    func shape(_ shape: Config.AvatarShape) -> AvatarView {
        self.config.shape = shape
        return self
    }
    
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(Array(stride(from: 10, through: 100, by: 10)), id: \.self) { size in
                AvatarView(nil, fallbackText: "A")
            }
        }
        
    }
}
#endif
