//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/27.
//

import SwiftUI
import ChocofordUIEssentials

public struct PrimitiveButtonWrapper<Content: View>: View {
    var onTrigger: () -> Void
    var content: (_ isPressed: Bool) -> Content
    
    public init(onTrigger: @escaping () -> Void,
                @ViewBuilder content: @escaping (_ isPressed: Bool) -> Content = { _ in EmptyView() }) {
        self.onTrigger = onTrigger
        self.content = content
    }
    
    @State private var isPressed: Bool = false
    @GestureState private var isDetectingTap = false
    
    @State private var frame: CGRect = .zero
    
    public var body: some View {
        content(isPressed)
            .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
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
    func makeBody(configuration: Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
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
