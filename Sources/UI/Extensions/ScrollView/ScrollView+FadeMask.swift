//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/24.
//

import SwiftUI

extension View {
    public func fadeMask(color: Color, height: CGFloat = 20) -> some View {
        clipped()
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(stops: [
                            .init(color: color.opacity(0.01), location: 0),
                            .init(color: color, location: 1)
                        ]), startPoint: .bottom, endPoint: .top)
                    )
                    .frame(height: 20)
                    .allowsHitTesting(false)  // << now works !!
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(stops: [
                            .init(color: color.opacity(0.01), location: 0),
                            .init(color: color, location: 1)
                        ]), startPoint: .top, endPoint: .bottom)
                    )
                    .frame(height: 20)
                    .allowsHitTesting(false)  // << now works !!
            }
    }
}
