//
//  MetalView.swift
//  KitUp
//
//  Created by Chocoford on 2023/8/15.
//

import SwiftUI
import MetalKit

#if canImport(AppKit)
struct MetalView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        return context.coordinator.mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
#elseif canImport(UIKit)
struct MetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        return context.coordinator.mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
#endif

extension MetalView {
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MetalView
        var mtkView: MTKView = MTKView()
        
        var metalDevice: MTLDevice?
        var metalCommandQueue: MTLCommandQueue?
        
        init(parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice?.makeCommandQueue()
            super.init()
            self.configureMTKView()
        }
        
        func configureMTKView() {
            self.mtkView.preferredFramesPerSecond = 60
            self.mtkView.enableSetNeedsDisplay = true
            self.mtkView.device = self.metalDevice
            self.mtkView.framebufferOnly = false
            self.mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            self.mtkView.drawableSize = mtkView.frame.size
            self.mtkView.enableSetNeedsDisplay = true
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
            let metalCommandQueue = self.metalCommandQueue else {
                return
            }
            let commandBuffer = metalCommandQueue.makeCommandBuffer()
            let rpd = view.currentRenderPassDescriptor
            rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
            rpd?.colorAttachments[0].loadAction = .clear
            rpd?.colorAttachments[0].storeAction = .store
            let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
            re?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}

#if DEBUG
struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        MetalView()
    }
}
#endif
