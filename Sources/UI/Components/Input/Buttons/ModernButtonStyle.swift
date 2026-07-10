//
//  ModernButtonStyle.swift
//
//
//  Created by Chocoford on 2026/7/2.
//

#if canImport(SwiftUI)
import SwiftUI

/// A prominent button modifier that uses SwiftUI's glass prominent style where available.
///
/// On glass-capable platforms this maps to `.glassProminent`. On older systems and
/// visionOS it falls back to `.borderedProminent`.
public struct ProminentButtonModifier: ViewModifier {
    /// Creates a prominent button modifier.
    public init() {}
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .buttonStyle(.borderedProminent)
        #else
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
        } else {
            content
                .buttonStyle(.borderedProminent)
        }
        #endif
    }
}

/// Applies a platform-aware SwiftUI button style, control size, and border shape.
///
/// Use this modifier when a button should opt into iOS/macOS 26 glass button styling
/// while still rendering with an appropriate bordered fallback on older systems.
public struct ModernButtonStyleModifier: ViewModifier {
    
    /// The control size to apply to the button.
    public enum Size: Sendable {
        /// SwiftUI's small control size.
        case small
        /// SwiftUI's regular control size.
        case regular
        /// SwiftUI's large control size.
        case large
        /// SwiftUI's extra large control size, falling back to large where unavailable.
        case extraLarge
    }
    
    /// The border shape to apply to bordered and glass button styles.
    public enum BorderShape: Sendable {
        /// A capsule border shape.
        case capsule
        /// A rounded rectangle border shape, optionally with a custom radius.
        case roundedRectangle(CGFloat? = nil)
        /// A circular border shape, falling back to rounded rectangle where unavailable.
        case circle
        /// Capsule on glass-capable platforms, rounded rectangle before then.
        case modern
        /// Circle on glass-capable platforms, rounded rectangle before then.
        case modernCircle
    }
    
    /// The SwiftUI button style to apply.
    public enum Style: Sendable {
        /// SwiftUI's automatic button style.
        case automatic
        /// SwiftUI's bordered button style.
        case bordered
        /// SwiftUI's bordered prominent button style.
        case borderedProminent
        /// SwiftUI's plain button style.
        case plain
        /// SwiftUI's borderless button style.
        case borderless
        /// SwiftUI's glass button style, falling back to bordered where unavailable.
        case glass
        /// SwiftUI's glass prominent button style, falling back to bordered prominent where unavailable.
        case glassProminent
    }
    
    private var style: Style?
    private var size: Size?
    private var shape: BorderShape?
    
    /// Creates a modifier that applies the provided button style options.
    ///
    /// Pass `nil` for any parameter to leave that aspect unchanged.
    ///
    /// - Parameters:
    ///   - style: The button style to apply.
    ///   - size: The control size to apply.
    ///   - shape: The button border shape to apply.
    public init(
        style: Style? = nil,
        size: Size? = nil,
        shape: BorderShape? = nil
    ) {
        self.style = style
        self.size = size
        self.shape = shape
    }
    
    public func body(content: Content) -> some View {
        styledContent(content)
            .modifier(ModernButtonControlSizeModifier(size: size))
            .modifier(ModernButtonBorderShapeModifier(shape: shape))
    }
    
    @ViewBuilder
    private func styledContent(_ content: Content) -> some View {
        switch style {
        case .automatic:
            content.buttonStyle(.automatic)
        case .bordered:
            content.buttonStyle(.bordered)
        case .borderedProminent:
            content.buttonStyle(.borderedProminent)
        case .borderless:
            content.buttonStyle(.borderless)
        case .plain:
            content.buttonStyle(.plain)
        case .glass:
            #if os(visionOS)
            content.buttonStyle(.bordered)
            #else
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                content.buttonStyle(.glass)
            } else {
                content.buttonStyle(.bordered)
            }
            #endif
        case .glassProminent:
            #if os(visionOS)
            content.buttonStyle(.borderedProminent)
            #else
            if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.borderedProminent)
            }
            #endif
        case nil:
            content
        }
    }
}

private struct ModernButtonControlSizeModifier: ViewModifier {
    var size: ModernButtonStyleModifier.Size?
    
    @ViewBuilder
    func body(content: Content) -> some View {
        switch size {
        case .small:
            content.controlSize(.small)
        case .regular:
            content.controlSize(.regular)
        case .large:
            content.controlSize(.large)
        case .extraLarge:
            if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *) {
                content.controlSize(.extraLarge)
            } else {
                content.controlSize(.large)
            }
        case nil:
            content
        }
    }
}

private struct ModernButtonBorderShapeModifier: ViewModifier {
    var shape: ModernButtonStyleModifier.BorderShape?
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *) {
            switch shape {
            case .capsule:
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *) {
                    content.buttonBorderShape(.capsule)
                } else {
                    content
                }
            case .roundedRectangle(let radius):
                if let radius {
                    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *) {
                        content.buttonBorderShape(.roundedRectangle(radius: radius))
                    } else {
                        content.buttonBorderShape(.roundedRectangle)
                    }
                } else {
                    content.buttonBorderShape(.roundedRectangle)
                }
            case .circle:
                if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, watchOS 10.0, *) {
                    content.buttonBorderShape(.circle)
                } else {
                    content.buttonBorderShape(.roundedRectangle)
                }
            case .modern:
                modernButtonBorderShape(content)
            case .modernCircle:
                modernCircleButtonBorderShape(content)
            case nil:
                content
            }
        } else {
            content
        }
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    @ViewBuilder
    private func modernButtonBorderShape(_ content: Content) -> some View {
        #if os(visionOS)
        content.buttonBorderShape(.roundedRectangle)
        #else
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            content.buttonBorderShape(.capsule)
        } else {
            content.buttonBorderShape(.roundedRectangle)
        }
        #endif
    }
    
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
    @ViewBuilder
    private func modernCircleButtonBorderShape(_ content: Content) -> some View {
        #if os(visionOS)
        content.buttonBorderShape(.roundedRectangle)
        #else
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, *) {
            content.buttonBorderShape(.circle)
        } else {
            content.buttonBorderShape(.roundedRectangle)
        }
        #endif
    }
}

public extension View {
    /// Applies a prominent button style with glass styling where available.
    ///
    /// This is a convenience wrapper around `ProminentButtonModifier`.
    @ViewBuilder
    func prominentButtonStyle() -> some View {
        modifier(ProminentButtonModifier())
    }
    
    /// Applies a platform-aware SwiftUI button style, control size, and border shape.
    ///
    /// Use this for buttons that should adopt modern glass styling on supported systems
    /// and automatically fall back on older systems.
    ///
    /// - Parameters:
    ///   - style: The button style to apply. Pass `nil` to keep the existing style.
    ///   - size: The control size to apply. Pass `nil` to keep the existing size.
    ///   - shape: The border shape to apply. Pass `nil` to keep the existing shape.
    @ViewBuilder
    func modernButtonStyle(
        style: ModernButtonStyleModifier.Style? = nil,
        size: ModernButtonStyleModifier.Size? = nil,
        shape: ModernButtonStyleModifier.BorderShape? = nil
    ) -> some View {
        modifier(
            ModernButtonStyleModifier(
                style: style,
                size: size,
                shape: shape
            )
        )
    }
}
#endif
