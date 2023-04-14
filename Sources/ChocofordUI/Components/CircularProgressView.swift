//
//  LoadingView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

public struct CircularProgressView<Content: View>: View {
    var content: ((_ progress: Int) -> Content)?
    
    @ObservedObject var config = Config()

    /// Create a circular progress.
    /// - Parameters:
    ///   - size: The size of circular progress.
    ///   - lineWidth: The line width of circular progress line.
    ///   - progress: The progress value.
    ///   - strokeColor: The color that stroke the circular progress ring.
    ///   - content: A view that displays on the center of circular progress.
    public init(@ViewBuilder content: @escaping ((_ progress: Int) -> Content) = { _ in EmptyView() }) {
        self.content = content
    }

    var animationDuration: Double = 0.8
    
    @State private var loading: Bool = false
    @State private var degree: CGFloat = 0
    
    @State private var trimLength: CGFloat = 0

    @State private var indeterminateLoading = true
    @State private var isProgessReady = false
    
    @State private var progressValue: Int = 0
    @State private var progressTimer: Timer? = nil
    
    var rotatingAnimation: Animation {
        Animation.linear(duration: animationDuration)
            .repeatForever(autoreverses: false)
    }
    
    var trimAnimation: Animation {
        Animation.easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
    }
    
    public var body: some View {
        ZStack {
            if let progress = config.progress {
                ZStack {
                    Circle()
                        .stroke(
                            Color.gray.opacity(0.5),
                            lineWidth: config.lineWidth
                        )
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            config.strokeColor,
                            style: StrokeStyle(lineWidth: config.lineWidth, lineCap: .round)
                        )
                        .rotationEffect(Angle(degrees: -90))
                }
                .animation(.linear(duration: 0.5), value: progress)
                .frame(width: config.size, height: config.size)
            } else {
                Circle()
                    .trim(from: 0.2 + trimLength, to: 1 - trimLength)
                    .stroke(
                        config.strokeColor,
                        style: StrokeStyle(lineWidth: config.lineWidth, lineCap: .round)
                    )
                    .frame(width: config.size, height: config.size)
                    .rotationEffect(Angle(degrees: degree))
                    .onAppear {
                        withAnimation(rotatingAnimation) {
                            degree = 360
                        }
                        withAnimation(trimAnimation) {
                            trimLength = 0.38
                        }
                    }
            }
            if let content = content {
                content(progressValue)
            }
        }
        .onChange(of: config.progress) { p in
            if let progress = p {
                var localProgrss: Double = Double(self.progressValue)
                self.progressTimer?.invalidate()
                let difference = 100 * progress - localProgrss
                /// 默认500ms
                self.progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    localProgrss += difference / 50
                    self.progressValue = Int(localProgrss)
                    if localProgrss >= 100 * progress {
                        timer.invalidate()
                    }
                }
            }
        }
    }
}

extension CircularProgressView {
    class Config<S: ShapeStyle>: ObservableObject {
        var progress: Double? = nil
        
        var size: CGFloat = 50
        var lineWidth: CGFloat = 4
        var strokeColor: Color = .accentColor
        var storkeGradient: Gradient? = nil
        
        enum Style {
            case ring
            case pie
        }
        
        var style: Style = .ring
        
        init() where S == Color {
            self.strokeColor = .accentColor
        }
    }
    
    public func size(_ size: CGFloat) -> CircularProgressView {
        self.config.size = size
        return self
    }
    
    public func lineWidth(_ width: CGFloat) -> CircularProgressView {
        self.config.lineWidth = width
        return self
    }
    
    public func stroke(_ color: Color) -> CircularProgressView {
        self.config.storkeGradient = nil
        self.config.strokeColor = color
        return self
    }
    
    public func stroke(_ gradient: Gradient) -> CircularProgressView {
        self.config.storkeGradient = gradient
        return self
    }
    
//    public func progress(_ progress: Progress) -> CircularProgressView {
//        self.config.progress = progress.fractionCompleted
//        return self
//    }
    
    public func progress(_ progress: Double?) -> CircularProgressView {
        self.config.progress = progress
        return self
    }
}

#if DEBUG
struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            CircularProgressView()
                .progress(0.4)
        }
        .frame(width: 200, height: 200)
    }
}
#endif
