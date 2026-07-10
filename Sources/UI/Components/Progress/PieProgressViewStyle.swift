//
//  File.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/9/10.
//

import SwiftUI

fileprivate struct PieShape: Shape {
    var progress: Double = 0.0
    
    var animatableData: Double {
        get {
            self.progress
        }
        set {
            self.progress = newValue
        }
    }
    
    private let startAngle: Double = (Double.pi) * 1.5
    private var endAngle: Double {
        get {
            return self.startAngle + Double.pi * 2 * self.progress
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arcCenter =  CGPoint(x: rect.size.width / 2, y: rect.size.width / 2)
        let radius = rect.size.width / 2
        path.move(to: arcCenter)
        path.addArc(center: arcCenter, radius: radius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
        path.closeSubpath()
        return path
    }
}

public struct PieProgressViewStyle: ProgressViewStyle {
    @Environment(\.controlSize) var controlSize
    
    public init() {}
    
    var size: CGFloat {
        switch controlSize {
            case .mini:
                12
            case .small:
                14
            case .regular:
                16
            case .large:
                20
            case .extraLarge:
                28
        }
    }
    
    @State private var isAppeared = false
    
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                if let progress = configuration.fractionCompleted {
                    PieShape(progress: progress)
                        .fill(.foreground)
                } else {
                    Circle()
                        .fill(.foreground)
                        .opacity(isAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 1.5).repeatForever(), value: isAppeared)
                        .onAppear {
                            isAppeared.toggle()
                        }
                }
            }
            .frame(width: size, height: size)
            
            configuration.label//?.font(.system(size: size))
        }
    }
}
extension ProgressViewStyle where Self == PieProgressViewStyle {
    @MainActor @preconcurrency public static var pie: PieProgressViewStyle {
        PieProgressViewStyle()
    }
}


#if DEBUG
struct PieProgressPreview: View {
    
    @State private var value: Double? = nil
    
    var body: some View {
        VStack {
            ProgressView(value: value) { Text("Loading") }
                .progressViewStyle(.pie)
                .controlSize(.mini)
            ProgressView(value: value) { Text("Loading") }
                .progressViewStyle(.pie)
                .controlSize(.small)
            ProgressView(value: value) { Text("Loading") }
                .progressViewStyle(.pie)
                .controlSize(.regular)
            ProgressView(value: value) { Text("Loading") }
                .progressViewStyle(.pie)
                .controlSize(.large)
//            ProgressView { Text("Loading") }
//                .progressViewStyle(.pie)
//                .controlSize(.extraLarge)
        }
    }
}

#Preview {
    PieProgressPreview()
        .padding()
}
#endif
