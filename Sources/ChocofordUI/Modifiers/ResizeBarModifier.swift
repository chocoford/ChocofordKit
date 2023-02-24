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
                                return $0
                            }
                        }
                    })
                    .frame(width: actualWidth, height: actualHeight),
                alignment: alignment
            )
        }
}


extension View {
    func onResize(edge: Edge, width: CGFloat = 8, onDragging: @escaping (_ event: NSEvent) -> Void) -> some View {
        modifier(ResizeBarModifier(edge: edge, width: width, onDragging: onDragging))
    }
}
#endif
