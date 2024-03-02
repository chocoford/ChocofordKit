//
//  View+OnHover.swift
//
//
//  Created by Dove Zachary on 2024/1/15.
//

#if canImport(SwiftUI)
import SwiftUI
//public enum DelayPhase {
//    case start
//    case end
//}

extension View {
    @ViewBuilder
    public func onHover(
        delay: TimeInterval,
//        phase: DelayPhase? = nil,
        perform action: @escaping (_ isHovered: Bool) -> Void
    ) -> some View {
        if #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) {
            Hover { isHovered in
                self.onChange(of: isHovered, debounce: delay) { _, newVal in
                    action(newVal)
                }
            }
        } else {
            Hover { isHovered in
                self.onChange(of: isHovered, debounce: delay) { newVal in
                    action(newVal)
                }
            }
        }
    }
}

#endif
