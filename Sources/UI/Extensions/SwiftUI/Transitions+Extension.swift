//
//  Transitions+Extension.swift
//  ChocofordUI
//
//  Created by SwiftUI-Lab on 04-Jul-2020.
//  https://swiftui-lab.com/matchedGeometryEffect-part1
//

#if canImport(SwiftUI)
import SwiftUI

extension AnyTransition {
    /// This transition will pass a value (0.0 - 1.0), indicating how much of the
    /// transition has passed. To communicate with the view, it will
    /// use the custom environment key .modalTransitionPercent
    /// it will also make sure the transitioning view is not faded in or out and it
    /// stays visible at all times.
    static var modal: AnyTransition {
        AnyTransition.modifier(
            active: ThumbnailExpandedModifier(pct: 0),
            identity: ThumbnailExpandedModifier(pct: 1)
        )
    }
    
    struct ThumbnailExpandedModifier: AnimatableModifier {
        var pct: CGFloat
        
        var animatableData: CGFloat {
            get { pct }
            set { pct = newValue }
        }
        
        func body(content: Content) -> some View {
            return content
                .environment(\.modalTransitionPercent, pct)
                .opacity(1)
        }
    }
    
    /// This transition will cause the view to disappear,
    /// until the last frame of the animation is reached
    static var invisible: AnyTransition {
        AnyTransition.modifier(
            active: InvisibleModifier(pct: 0),
            identity: InvisibleModifier(pct: 1)
        )
    }
    
    struct InvisibleModifier: AnimatableModifier {
        var pct: Double
        
        var animatableData: Double {
            get { pct }
            set { pct = newValue }
        }
        
        
        func body(content: Content) -> some View {
            content.opacity(pct == 1.0 ? 1 : 0)
        }
    }
}

extension EnvironmentValues {
    var heroConfig: HeroConfiguration {
        get { return self[HeroConfigKey.self] }
        set { self[HeroConfigKey.self] = newValue }
    }

    var modalTransitionPercent: CGFloat {
        get { return self[ModalTransitionKey.self] }
        set { self[ModalTransitionKey.self] = newValue }
    }
}

public struct HeroConfigKey: EnvironmentKey {
    public static let defaultValue: HeroConfiguration = .default
}

public struct ModalTransitionKey: EnvironmentKey {
    public static let defaultValue: CGFloat = 0
}

var sourceImagesSize = CGSize(width: 600, height: 400)

public struct HeroConfiguration {
    
    private var _thumbnailScalingFactor: CGFloat = sourceImagesSize.width / sourceImagesSize.height

    /// Separation between rows in the grid
    var verticalSeparation: CGFloat = 30
    
    /// Separation between columns in the grid
    var horizontalSeparation: CGFloat = 30

    /// Thumbnail size
    var thumbnailSize: CGSize = CGSize(width: 350, height: 350)
    
    /// Thumbnail corner radius
    var thumbnailRadius: CGFloat = 15

    var modalImageHeight: CGFloat = 400
    var modalSize: CGSize = CGSize(width: 600, height: 400)
    var modalRadius: CGFloat = 15
    
    /// Use dark mode
    var darkMode: Bool = true
    
    /// Aspect ratio of provided images
    var aspectRatio: CGFloat = sourceImagesSize.width / sourceImagesSize.height
    
    /// Zoomed factor of thumbnail images. It is kept valid by checking with lowestFactor and
    /// highestFactor. These are determine by the thumbnail size.
    var thumbnailScalingFactor: CGFloat {
        get { min(max(_thumbnailScalingFactor, lowestFactor), highestFactor) }
        set { _thumbnailScalingFactor = min(max(newValue, lowestFactor), highestFactor) }
    }
    
    /// A default configuration
    public static let `default` = HeroConfiguration()
    
    /// The default configuration for portrait layouts
    public static let defaultPortrait = HeroConfiguration(
        verticalSeparation: 20,
        horizontalSeparation: 20,
        thumbnailSize: CGSize(width: 700, height: 200),
        thumbnailScalingFactor: 1.5,
        thumbnailRadius: 12,
        modalImageHeight: 400,
        modalSize: CGSize(width: 600, height: 800),
        modalRadius: 20,
        darkMode: true,
        aspectRatio: sourceImagesSize.width / sourceImagesSize.height)
    
    /// The default configuration for landscape layouts
    public static let defaultLandscape = HeroConfiguration(
        verticalSeparation: 0,
        horizontalSeparation: 0,
        thumbnailSize: CGSize(width: 280, height: 280),
        thumbnailScalingFactor: 1.5,
        thumbnailRadius: 0,
        modalImageHeight: 400,
        modalSize: CGSize(width: 600, height: 700),
        modalRadius: 20,
        darkMode: true,
        aspectRatio: sourceImagesSize.width / sourceImagesSize.height)
    
    /// Thumbnail's aspect ratio (read-only)
    var thumbnailAspectRatio: CGFloat {
        return (thumbnailSize.width / thumbnailSize.height)
    }
    
    /// Lowest scaling factor possible for the current thumbnail size
    var lowestFactor: CGFloat {
        return max(aspectRatio / thumbnailAspectRatio, 1)
    }
    
    /// Highest scaling factor possible for the current thumbnail size
    var highestFactor: CGFloat {
        return lowestFactor * 6;
    }
    
    init() {
        self.thumbnailScalingFactor = _thumbnailScalingFactor // make sure it is in bounds
    }
    
    init(verticalSeparation: CGFloat, horizontalSeparation: CGFloat, thumbnailSize: CGSize, thumbnailScalingFactor: CGFloat,  thumbnailRadius: CGFloat, modalImageHeight: CGFloat, modalSize: CGSize, modalRadius: CGFloat, darkMode: Bool, aspectRatio: CGFloat) {
        self.verticalSeparation = verticalSeparation
        self.horizontalSeparation = horizontalSeparation
        self.thumbnailSize = thumbnailSize
        self.thumbnailScalingFactor = thumbnailScalingFactor
        self.thumbnailRadius = thumbnailRadius
        self.modalSize = modalSize
        self.modalRadius = modalRadius
        self.darkMode = darkMode
        self.aspectRatio = aspectRatio
    }
}

#endif
