//
//  PopoverView.swift
//  
//
//  Created by Chocoford on 2023/3/30.
//

import SwiftUI
#if os(macOS)
@available(*, deprecated)
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
#endif


/// - Parameters:
///   - attachmentAnchor: The positioning anchor that defines the
///     attachment point of the popover. The default is
///     ``Anchor/Source/bounds``.
///   - arrowEdge: The edge of the `attachmentAnchor` that defines the
///     location of the popover's arrow in macOS. The default is ``Edge/top``.
///     iOS ignores this parameter.
///   - content: A closure returning the content of the popover.
///   - label: A closure returning the content of the activator label..
public struct Popover<Content: View, Label: View>: View {
    var attachmentAnchor: PopoverAttachmentAnchor
    var arrowEdge: Edge
    
    var content: () -> Content
    var label: () -> Label
    
    public init(
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge = .top,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.attachmentAnchor = attachmentAnchor
        self.arrowEdge = arrowEdge
        self.content = content
        self.label = label
    }
    
    @State private var showPopover: Bool = false
    
    public var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            label()
        }
        .popover(isPresented: $showPopover, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge) {
            content()
        }
    }
}

struct SimplePopoverModifier<V: View>: ViewModifier {
    var arrowEdge: Edge = .top
    var popoverContent: () -> V
    
    @State private var showPopover: Bool = false
    
    func body(content: Content) -> some View {
        Button {
            showPopover.toggle()
        } label: {
            content
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $showPopover, arrowEdge: arrowEdge) {
            popoverContent()
        }
    }
}

public extension View {
    @ViewBuilder
    func popover<V: View>(arrowEdge: Edge = .top,
                          @ViewBuilder content: @escaping () -> V) -> some View {
        self
            .modifier(SimplePopoverModifier(arrowEdge: arrowEdge, popoverContent: content))
    }
}


