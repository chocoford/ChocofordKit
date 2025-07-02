//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/7/24.
//

import SwiftUI
import ChocofordEssentials

struct PulldownViewModifier<V: View, I: View>: ViewModifier {
    @Binding var showPulldown: Bool
    var pulldownView: () -> V
    var pulldownIndicator: () -> I

    init(
        showPulldown: Binding<Bool>,
        @ViewBuilder content: @escaping () -> V,
        @ViewBuilder indicator: @escaping () -> I = { EmptyView() }
    ) {
        self._showPulldown = showPulldown
        self.pulldownView = content
        self.pulldownIndicator = indicator
    }
    
    @State private var translateY: CGFloat = .zero
    @State private var alreadyPlayedHaptics: Bool = false
    
    var threshold: CGFloat { 200 }
    
    func body(content: Content) -> some View {
        ZStack {
            if showPulldown {
                self.pulldownView()
            } else {
                content
                    .overlay(alignment: .top) {
                        self.pulldownIndicator()
                            .offset(y: -100)
                    }
                    .offset(y: translateY)
                    .task{ self.translateY = .zero }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged{ val in
                                self.translateY = max(0, val.translation.height / 2.5)
                                if val.translation.height > self.threshold && !alreadyPlayedHaptics {
                                    HapticsCenter.shared.playSingleTapHaptics()
                                    alreadyPlayedHaptics = true
                                }
                            }
                            .onEnded { val in
                                if val.translation.height > threshold {
                                    withAnimation { self.showPulldown.toggle() }
                                } else {
                                    withAnimation { self.translateY = .zero }
                                }
                                alreadyPlayedHaptics = false
                            }
                    )
                    .transition(.move(edge: .bottom))
            }
        }
    }
}

extension View {
    @ViewBuilder
    public func pulldown<Content: View, Indicator: View>(
        _ isPresent: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder indicator: @escaping () -> Indicator = { EmptyView() }
    ) -> some View {
        self
            .modifier(PulldownViewModifier(showPulldown: isPresent, content: content, indicator: indicator))
    }
}
