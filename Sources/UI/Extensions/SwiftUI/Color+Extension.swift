#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    public init(_ colorSpace: RGBColorSpace = .sRGB,
                r: Int, g: Int, b: Int, a: Double = 1) {
        self.init(colorSpace, red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0, opacity: a)
    }
    
    /// Create a `Color` from a hexadecimal representation
    /// - Parameter hexString: 3, 6, or 8-character string, with optional (ignored) punctuation such as "#"
    public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let red, green, blue, alpha : UInt64
        switch hex.count {
            case 3: // RGB (12-bit)
                (red, green, blue, alpha) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
            case 6: // RGB (24-bit)
                (red, green, blue, alpha) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
            case 8: // ARGB (32-bit)
                // FIXME: I think we need an an alpha value on this one. See link below.
                // https://stackoverflow.com/a/56874327/4475605
                (red, green, blue, alpha) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (red, green, blue, alpha) = (0, 0, 0, 255)
        }
        self.init(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, opacity: Double(alpha) / 255)
    }
    
    public init(hue: Double, saturation: Double, lightness: Double, opacity: Double = 1) {
        
        precondition(0...1 ~= hue &&
                     0...1 ~= saturation &&
                     0...1 ~= lightness &&
                     0...1 ~= opacity, "input range is out of range 0...1")
        
        //From HSL TO HSB ---------
        var newSaturation: Double = 0.0
        
        let brightness = lightness + saturation * min(lightness, 1-lightness)
        
        if brightness == 0 { newSaturation = 0.0 }
        else {
            newSaturation = 2 * (1 - lightness / brightness)
        }
        //---------
        
        self.init(hue: hue, saturation: newSaturation, brightness: brightness, opacity: opacity)
    }
    
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        
#if canImport(UIKit)
        typealias NativeColor = UIColor
#elseif canImport(AppKit)
        typealias NativeColor = NSColor
#endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
        
        return (r, g, b, o)
    }
    
    var hsbaComponents: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, opacity: CGFloat) {
        
        var r: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
#if canImport(UIKit)
        UIColor(self).getHue(&r, saturation: &s, brightness: &b, alpha: &o)
#elseif canImport(AppKit)
        /// NSColor:  This method works only with objects representing colors in the calibratedRGB or deviceRGB color space. Sending it to other objects raises an exception.
        /// Need to transform ColorSpace first
        if let color = NSColor(self).usingColorSpace(.deviceRGB) {
            color.getHue(&r, saturation: &s, brightness: &b, alpha: &o)
        }
#endif
        return (r, s, b, o)
    }
    
    public var hexString: String {
        #if canImport(UIKit)
        // 将SwiftUI的Color转换为UIColor
        let platformColor = UIColor(self)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        guard let platformColor = nsColor.usingColorSpace(.sRGB) else {
            return "#000000"  // 默认值，以防颜色空间转换失败
        }
        #else
        // 如果没有 UIKit 或 AppKit，则直接返回默认值
        return "#000000FF"
        #endif
        
        // 获取颜色的RGBA组件
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        platformColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 转换成16进制字符串
        let redHex = String(format: "%02X", Int(red * 255))
        let greenHex = String(format: "%02X", Int(green * 255))
        let blueHex = String(format: "%02X", Int(blue * 255))
        let alphaHex = String(format: "%02X", Int(alpha * 255))

        // 拼接成完整的16进制颜色代码
        return "#\(redHex)\(greenHex)\(blueHex)\(alphaHex)"
    }
}


public extension Color {
    #if os(macOS)
    static var textColor: Color {
        Color(nsColor: .textColor)
    }
    static var placeholderTextColor: Color {
        Color(nsColor: .placeholderTextColor)
    }
    static var textBackgroundColor: Color {
        Color(nsColor: .textBackgroundColor)
    }
    static var secondaryTextBackgroundColor: Color {
        Color(nsColor: .textBackgroundColor)
    }
    static var separatorColor: Color {
        Color(nsColor: .separatorColor)
    }
    static var controlBackgroundColor: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    static var windowBackgroundColor: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    static var shadowColor: Color {
        Color(nsColor: .shadowColor)
    }
    #elseif os(iOS)
    static var textColor: Color {
        Color(uiColor: .init(dynamicProvider: { trait in
            switch trait.userInterfaceStyle {
                case .light, .unspecified:
                    return .lightText
                case .dark:
                    return .darkText
                @unknown default:
                    return .lightText
            }
        }))
    }
    static var placeholderTextColor: Color {
        Color(uiColor: .placeholderText)
    }
    static var textBackgroundColor: Color {
        Color(uiColor: .systemBackground)
    }
    static var secondaryTextBackgroundColor: Color {
        Color(uiColor: .secondarySystemBackground)
    }
    static var separatorColor: Color {
        Color(uiColor: .separator)
    }
    static var controlBackgroundColor: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)
    }
    static var windowBackgroundColor: Color {
        Color(uiColor: .systemBackground)
    }
    static var shadowColor: Color {
        Color(uiColor: .lightGray)
    }
    #endif
}
#endif
