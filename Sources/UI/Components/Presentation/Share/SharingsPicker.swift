//
//  SharingsPicker.swift
//  
//
//  Created by Chocoford on 2023/4/3.
//

import SwiftUI

#if canImport(AppKit)
public struct SharingsPicker: NSViewRepresentable {
    @Binding var isPresented: Bool
    var sharingItems: [Any] = []
    
    @State private var previousIsPresented = false

    public init(isPresented: Binding<Bool>, sharingItems: [Any]) {
        self._isPresented = isPresented
        self.sharingItems = sharingItems
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented && !previousIsPresented {
            let picker = NSSharingServicePicker(items: sharingItems)
            picker.delegate = context.coordinator
            // !! MUST BE CALLED IN ASYNC, otherwise blocks update
            DispatchQueue.main.async {
                picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
            }
        }
        DispatchQueue.main.async {
            previousIsPresented = isPresented
        }
        
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }

    public class Coordinator: NSObject, NSSharingServicePickerDelegate {
        let owner: SharingsPicker

        init(owner: SharingsPicker) {
            self.owner = owner
        }

        public func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {

            // do here whatever more needed here with selected service
            
            sharingServicePicker.delegate = nil   // << cleanup
            self.owner.isPresented = false        // << dismiss
        }
    }
}

#elseif canImport(UIKit)
public struct SharingsPicker: UIViewRepresentable {
    @Binding var isPresented: Bool
    var sharingItems: [Any] = []
    
    public init(isPresented: Binding<Bool>, sharingItems: [Any]) {
        self._isPresented = isPresented
        self.sharingItems = sharingItems
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
#endif
