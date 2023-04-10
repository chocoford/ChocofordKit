//
//  SharingsPicker.swift
//  
//
//  Created by Dove Zachary on 2023/4/3.
//

import SwiftUI

#if os(macOS)
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
#endif
