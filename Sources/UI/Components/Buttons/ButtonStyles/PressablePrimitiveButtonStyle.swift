//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/27.
//

import SwiftUI
import ChocofordEssentials

public struct PrimitiveButtonWrapper<Content: View>: View {
    var onTrigger: () -> Void
    var content: (_ isPressed: Bool) -> Content
    
    public init(onTrigger: @escaping () -> Void,
                @ViewBuilder content: @escaping (_ isPressed: Bool) -> Content = { _ in EmptyView() }) {
        self.onTrigger = onTrigger
        self.content = content
    }
        
    public init(
        configuration: PrimitiveButtonStyleConfiguration,
        @ViewBuilder content: @escaping (_ isPressed: Bool) -> Content = { _ in EmptyView() }
    ) {
        self.onTrigger = configuration.trigger
        self.content = content
    }
    
    @State private var isPressed: Bool = false
    @GestureState private var isDetectingTap = false
    
    @State private var frame: CGRect = .zero
    
    public var body: some View {
        content(isPressed)
            .simultaneousGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { val in
                    isPressed = false
                    
                    if frame.contains(val.location) {
                        onTrigger()
                    }
                })
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .watchImmediately(of: geometry.frame(in: .local)) { frame in
                            self.frame = frame
                        }
                }
            }
    }
}

struct PressablePrimitiveButtonStyle: PrimitiveButtonStyle {
//    var content: (_ label: PrimitiveButtonStyleConfiguration.Label, _ isPressed: Bool) -> AnyView
//    
//    init<Content: View>(
//        @ViewBuilder content: @escaping (_ label: PrimitiveButtonStyleConfiguration.Label, _ isPressed: Bool) -> Content
//    ) {
//        self.content = {
//            AnyView(content($0, $1))
//        }
//    }
//    
    func makeBody(configuration: Configuration) -> some View {
        PrimitiveButtonWrapper(configuration: configuration) { isPressed in
            configuration.label
        }
    }
}

#if DEBUG
struct PrimitiveButtonWrapper_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            VStack {
                Button {
                    print("click")
                } label: {
                    Text("Button")
                }
                .buttonStyle(PressablePrimitiveButtonStyle())
                .padding()
                
                
                Button {
                    print("click")
                } label: {
                    Text("Button")
                }
                .buttonStyle(.borderless)
                .padding()
                
                #if os(macOS)
                Button {
                    print("click")
                } label: {
                    Text("Button")
                }
                .buttonStyle(.link)
                .padding()
                #endif
            }
        }
    }
}
#endif
