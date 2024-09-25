//
//  HelpPopover.swift
//
//
//  Created by Dove Zachary on 2024/1/15.
//

import SwiftUI

struct HelpPopoverModifier: ViewModifier {
    var helpView: AnyView
    var delay: TimeInterval
    var arrowEdge: Edge
    var attachmentAnchor: PopoverAttachmentAnchor
    @State private var isPresented = false
    
    init<H: View>(
        delay: TimeInterval,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge = .top,
        @ViewBuilder helpView: () -> H
    ) {
        self.delay = delay
        self.arrowEdge = arrowEdge
        self.attachmentAnchor = attachmentAnchor
        self.helpView = AnyView(helpView())
    }
    
    init(
        _ help: LocalizedStringKey,
        delay: TimeInterval,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge = .top
    ) {
        self.delay = delay
        self.attachmentAnchor = attachmentAnchor
        self.arrowEdge = arrowEdge
        self.helpView = AnyView(
            Text(help)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        )
    }
    
    func body(content: Content) -> some View {
        content
            .onHover(delay: delay) { self.isPresented = $0 }
            .popover(isPresented: $isPresented, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge) {
                helpView
            }
    }
}



extension View {
    @ViewBuilder
    public func popoverHelp(
        _ titleKey: LocalizedStringKey,
        delay: TimeInterval = 0.0,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge = .top
    ) -> some View {
        modifier(
            HelpPopoverModifier(titleKey, delay: delay, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge)
        )
    }
    
    @ViewBuilder
    public func popoverHelp<H: View>(
        delay: TimeInterval = 0.0,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge = .top,
        @ViewBuilder helpView: @escaping () -> H
    ) -> some View {
        modifier(
            HelpPopoverModifier(delay: delay, attachmentAnchor: attachmentAnchor, arrowEdge: arrowEdge, helpView: helpView)
        )
    }
}
