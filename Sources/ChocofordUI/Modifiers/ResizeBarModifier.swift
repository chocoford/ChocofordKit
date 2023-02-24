//
//  ResizeBarModifier.swift
//  TrickleAnyway
//
//  Created by Dove Zachary on 2023/2/8.
//

import Foundation
import SwiftUI

#if os(macOS)
struct ResizeBarModifier: ViewModifier {
    var edge: Edge
    var width: CGFloat = 8
    var onDragging: (_ event: NSEvent) -> Void
    var onDraggingEnd: (() -> Void)?
    
    @State private var inResizing: Bool = false
    @State private var mouseMoveHandler: Any? = nil
    @State private var mouseUpHandler: Any? = nil
    
    private var alignment: Alignment {
        switch edge {
            case .top:
                return .top
            case .leading:
                return .leading
            case .bottom:
                return .bottom
            case .trailing:
                return .trailing
        }
    }
    
    private var actualWidth: CGFloat? {
        switch edge {
            case .top, .bottom:
                return nil
            case .leading, .trailing:
                return width
        }
    }
    
    private var actualHeight: CGFloat? {
        switch edge {
            case .top, .bottom:
                return width
            case .leading, .trailing:
                return nil
        }
    }
    
    func body(content: Content) -> some View {
            content
            .overlay(
                Rectangle()
                    .opacity(0)
                    .onHover { inside in
                        if inside {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ _ in
                                inResizing = true
                            })
                    )
                    .onChange(of: inResizing, perform: { newValue in
                        if inResizing {
                            mouseMoveHandler = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) {
                                onDragging($0)
                                return $0
                            }
                            mouseUpHandler = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) {
                                inResizing = false
                                if let handler = mouseUpHandler {
                                    NSEvent.removeMonitor(handler)
                                    mouseUpHandler = nil
                                }
                                if let handler = mouseMoveHandler {
                                    NSEvent.removeMonitor(handler)
                                    mouseMoveHandler = nil
                                }
                                if let onDraggingEnd = onDraggingEnd { onDraggingEnd() }
                                return $0
                            }
                        }
                    })
                    .frame(width: actualWidth, height: actualHeight),
                alignment: alignment
            )
        }
}

public struct ResizableView<Content: View>: View {
    var axis: Axis
    var edge: Edge
    var initialSize: CGFloat
    var minSize: CGFloat?
    var maxSize: CGFloat?
    var content: () -> Content

    public init(_ axis: Axis, edge: Edge, initialSize: CGFloat, minSize: CGFloat? = nil, maxSize: CGFloat? = nil , content: @escaping () -> Content) {
        self.axis = axis
        self.edge = edge
        self.initialSize = initialSize
        self.minSize = minSize
        self.maxSize = maxSize
        self.content = content
    }
    
    @State private var width: CGFloat? = nil
    @State private var height: CGFloat? = nil
    
    var realWidth: CGFloat? {
        guard let width = width else { return nil }
        if let minSize = minSize, width < minSize {
            return minSize
        }
        if let maxSize = maxSize, width > maxSize {
            return maxSize
        }
        return width
    }
    
    var realHeight: CGFloat? {
        guard let height = height else { return nil }
        if let minSize = minSize, height < minSize {
            return minSize
        }
        if let maxSize = maxSize, height > maxSize {
            return maxSize
        }
        return height
    }
    
    public var body: some View {
        content()
            .frame(width: realWidth, height: realHeight)
            .onResize(edge: edge, onDragging: { event in
                switch edge {
                    case .top:
                        guard axis == .vertical else { return }
                        height! += -1 * event.deltaY
                    case .leading:
                        guard axis == .horizontal else { return }
                        width! += -1 * event.deltaX
                    case .bottom:
                        guard axis == .vertical else { return }
                        height! += event.deltaY
                    case .trailing:
                        guard axis == .horizontal else { return }
                        width! += event.deltaX
                }
            }, onDraggingEnd: {
                if axis == .horizontal {
                    if let minSize = minSize {
                        width = max(minSize, width!)
                    }
                    if let maxSize = maxSize {
                        width = min(maxSize, width!)
                    }
                } else {
                    if let minSize = minSize {
                        height = max(minSize, height!)
                    }
                    if let maxSize = maxSize {
                        height = min(maxSize, height!)
                    }
                }
            })
            .onAppear {
                if axis == .horizontal {
                    width = initialSize
                } else {
                    height = initialSize
                }
            }
    }
}

extension View {
    public func onResize(edge: Edge, width: CGFloat = 8, onDragging: @escaping (_ event: NSEvent) -> Void, onDraggingEnd: @escaping () -> Void) -> some View {
        modifier(ResizeBarModifier(edge: edge, width: width, onDragging: onDragging, onDraggingEnd: onDraggingEnd))
    }
}
#endif
