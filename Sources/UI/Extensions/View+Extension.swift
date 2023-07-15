//
//  View+Extension.swift
//  CSWang
//
//  Created by Chocoford on 2022/11/28.
//

import SwiftUI

// MARK: - Condition
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<TrueContent: View, FalseContent: View>(_ condition: @autoclosure () -> Bool,
                                          transform: @escaping (Self) -> TrueContent,
                                          falseTransform: ((Self) -> FalseContent)? = nil) -> some View {
        if condition() {
            transform(self)
        } else if falseTransform != nil {
            falseTransform!(self)
        } else {
            self
        }
    }
    
    
    @ViewBuilder func `if`<TrueContent: View>(_ condition: @autoclosure () -> Bool,
                                          transform: @escaping (Self) -> TrueContent) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func show(_ condition: @autoclosure () -> Bool) -> some View {
        if condition() {
            self
        } else {
            self
                .opacity(0)
                .frame(width: 0, height: 0, alignment: .center)
        }
    }

    // MARK: - Refreshable
    @ViewBuilder
    public func disableRefreshable() -> some View {
        environment(\EnvironmentValues.refresh as! WritableKeyPath<EnvironmentValues, RefreshAction?>, nil)
    }

    public func border(_ edges: [Edge], width: CGFloat = 1, color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
    public func border(_ edge: Edge, width: CGFloat = 1, color: Color) -> some View {
        border([edge], width: width, color: color)
    }
    
    @ViewBuilder
    public func watchImmediately<V : Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        onAppear {
            action(value)
        }
        .onChange(of: value) { newValue in
            action(newValue)
        }
    }
    
    /// show a badge without text
    public func badge(show: Bool = true) -> some View {
        overlay(alignment: .topTrailing) {
            if show {
                Circle().fill(Color.accentColor).frame(width: 8, height: 8).offset(x: 4, y: -4)
            }
        }
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}


// MARK: - VisualEffect
#if os(macOS)
struct VisualEffectBackground: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let isEmphasized: Bool
    
    init(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode,
        emphasized: Bool) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = emphasized
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        
        // Not certain how necessary this is
        view.autoresizingMask = [.width, .height]

        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = isEmphasized
    }
}

extension View {
    public func visualEffect(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false
    ) -> some View {
        background(
            VisualEffectBackground(
                material: material,
                blendingMode: blendingMode,
                emphasized: emphasized
            )
        )
    }
}
//#elseif os(iOS)
//extension View {
//    @ViewBuilder
//    public func visualEffect(
//        material: Any,
//        blendingMode: Any,
//        emphasized: Any
//    ) -> some View {
//        self
//    }
//}
#endif

#if os(macOS)
//extension View {
//    public func window(_ callback: @escaping (_ window: NSWindow) -> Void) -> some View {
//        background(
//            List{}
//                .frame(width: 0, height: 0)
//                .opacity(0)
//                .introspectTableView(customize: { view in
//                    if let window = view.window {
//                        callback(window)
//                    } else {
//                        fatalError("no window")
//                    }
//                })
//        )
//    }
//}
#endif


// MARK: - Styles

public extension View {
    @ViewBuilder
    func chipStyle() -> some View {
        padding(.vertical, 2)
            .padding(.horizontal, 8)
            .foregroundColor(.accentColor)
            .background(Capsule().fill(Color.accentColor.opacity(0.2)))
    }
    
    @ViewBuilder
    func outlinedStyle(size: ButtonSize = .normal,
                       block: Bool = false,
                       square: Bool = false,
                       color: Color = .secondary,
                       loading: Bool = false) -> some View {
        OutlinedButtonStyleView(isPressed: false,
                                colors: .init(default: color,
                                              hovered: color.opacity(0.1),
                                              pressed: color.opacity(0.5)),
                                size: size,
                                block: block, square: square) {
            LoadableButtonStyleView(loading: loading,
                                    color: color) {
                self
            }
        }
    }
}
