//
//  AvatarView.swift
//  CSWang
//
//  Created by Chocoford on 2022/11/30.
//

import SwiftUI
import ShapeBuilder
import Kingfisher

public protocol AvatarUserRepresentable: Hashable, Identifiable {
    associatedtype AvatarURL
    
    var name: String? { get }
    var avatarURL: AvatarURL? { get }
}



public struct AvatarView: View {
    var url: URL?
    var fallbackView: AnyView
    var config: Config = .init()
    private var shouldAdjustTextSize = false
    
    public init<S: StringProtocol>(_ url: URL? = nil, fallbackText: S) {
        self.url = url
        self.fallbackView = AnyView(Text(fallbackText))
        self.shouldAdjustTextSize = true
    }
    
    public init<V: View>(_ url: URL? = nil, @ViewBuilder content: @escaping () -> V) {
        self.url = url
        self.fallbackView = AnyView(content())
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
        KFImage(url)
            .placeholder {
                clipShape
                    .fill(self.config.bgColor)
                    .overlay(alignment: .center) {
                        if shouldAdjustTextSize {
                            fallbackView
                                .font(.system(size: config.size / 2))
                                .foregroundColor(.white)
                        } else {
                            fallbackView
                        }
                    }
            }
            .frame(width: config.size, height: config.size, alignment: .center)
            .clipShape(clipShape)
    }
}

public extension AvatarView {
    class Config: ObservableObject {
        public enum AvatarShape {
            case circle
            case rounded
            case tile
        }
        
        var shape: AvatarShape
        var size: CGFloat
        var bgColor: Color
        
        init(shape: AvatarShape = .circle, size: CGFloat = 28, bgColor: Color = .gray) {
            self.shape = shape
            self.size = size
            self.bgColor = bgColor
        }
    }
    
    func size(_ size: CGFloat) -> AvatarView {
        self.config.size = size
        return self
    }
    
    func shape(_ shape: Config.AvatarShape) -> AvatarView {
        self.config.shape = shape
        return self
    }
    
    func fallbackBackgroundColor(_ color: Color) -> AvatarView {
        self.config.bgColor = color
        return self
    }
}

#if DEBUG
#Preview {
    VStack {
        ForEach(Array(stride(from: 10, through: 100, by: 10)), id: \.self) { size in
            AvatarView(nil, fallbackText: "A")
        }
    }
}
#endif
