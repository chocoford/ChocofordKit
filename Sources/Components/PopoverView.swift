//
//  PopoverView.swift
//  
//
//  Created by Chocoford on 2023/3/30.
//

import SwiftUI
#if os(macOS)
public struct PopoverView<L: View, Content: View>: View {
    var preferredEdge: NSRectEdge = .minY
    var label: () -> L
    
    var content: () -> Content
    
    public init(_ preferredEdge: NSRectEdge = .minY, @ViewBuilder label: @escaping () -> L, @ViewBuilder content: @escaping () -> Content) {
        self.preferredEdge = preferredEdge
        self.label = label
        self.content = content
    }
    
    @State private var isVisible = false

    public var body: some View {
        Button {
            isVisible.toggle()
        } label: {
            self.label()
        }
        .background(NSPopoverHolderView(isVisible: $isVisible, preferredEdge: preferredEdge) {
            content()
        })
    }
}

struct NSPopoverHolderView<T: View>: NSViewRepresentable {
    @Binding var isVisible: Bool
    var preferredEdge: NSRectEdge = .minY
    var content: () -> T

    func makeNSView(context: Context) -> NSView {
        NSView()
        
        // This will cause crash...
        // return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.preferredEdge = preferredEdge
        context.coordinator.setVisible(isVisible, in: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(state: _isVisible, content: content)
    }

    class Coordinator: NSObject, NSPopoverDelegate {
        var preferredEdge: NSRectEdge = .minY

        private let popover: NSPopover
        private let state: Binding<Bool>

        init<V: View>(state: Binding<Bool>, content: @escaping () -> V) {
            self.popover = NSPopover()
            self.state = state
            super.init()

            popover.delegate = self
            popover.contentViewController = NSHostingController(rootView: content())
            popover.behavior = .transient
        }

        func setVisible(_ isVisible: Bool, in view: NSView) {
            if isVisible {
//                print(popover.contentViewController?.view.bounds.width)
                popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
            } else {
                popover.close()
            }
        }

        func popoverDidClose(_ notification: Notification) {
            DispatchQueue.main.async {
                self.state.wrappedValue = false
            }
        }

        func popoverShouldDetach(_ popover: NSPopover) -> Bool {
            true
        }
    }
}

#if DEBUG
struct PopoverView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverView {
            Text("Popover")
        } content: {
            Text("I'm in NSPopover")
                .padding()
        }
    }
}
#endif


#endif

