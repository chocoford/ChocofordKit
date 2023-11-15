//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/15.
//

import SwiftUI

import ChocofordEssentials

@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public struct Gallery<Item: Identifiable & Hashable, Content: View>: View {
    var selection: Binding<Set<Item.ID>>?
    var items: [Item]
    var spacing: CGFloat
    var rowSpacing: CGFloat
    var rowHeight: GalleryLayout.RowHeight
    var itemView: (Item) -> Content
    
    var config = Config()
    
    public init(
        selection: Binding<Set<Item.ID>>? = nil,
        items: [Item],
        spacing: CGFloat = 10,
        rowSpacing: CGFloat = 10,
        rowHeight: CGFloat,
        @ViewBuilder itemView: @escaping (Item) -> Content
    ) {
        self.init(selection: selection,
                  items: items,
                  spacing: spacing,
                  rowSpacing: rowSpacing,
                  rowHeight: .fixed(rowHeight),
                  itemView: itemView)
    }
    
    public init(
        selection: Binding<Set<Item.ID>>? = nil,
        items: [Item],
        spacing: CGFloat = 10,
        rowSpacing: CGFloat = 10,
        rowHeight: GalleryLayout.RowHeight,
        @ViewBuilder itemView: @escaping (Item) -> Content
    ) {
        self.selection = selection
        self.items = items
        self.spacing = spacing
        self.rowSpacing = rowSpacing
        self.rowHeight = rowHeight
        self.itemView = itemView
    }
    
    @State private var frames: [CGRect] = []
    let coordinateSpaceName = "Gallery"
    
    @State private var selectRect: CGRect? = nil

    public var body: some View {
        GalleryLayout(
            rowHeight: rowHeight,
            spacing: spacing,
            rowSpacing: rowSpacing
        ) {
            ForEach(Array(items.enumerated()), id: \.element) { i, item in
                itemView(item)
                    //MARK: Otherwise it will be delay
                    .simultaneousGesture(TapGesture().onEnded {
                        guard self.selection != nil else { return }
                        if NSEvent.modifierFlags.contains(.command) {
                            self.selection?.wrappedValue.insertOrRemove(item.id)
                            //                            } else if NSEvent.modifierFlags.contains(.shift) {
                            //                                galleryStore.selectedItemIDs = [clipItem.id]
                        } else {
                            selection?.wrappedValue = [item.id]
                        }
                    })
                    .background {
                        GeometryReader { proxy in
                            let frame = proxy.frame(in: .named(coordinateSpaceName))
                            Color.clear
                                .watchImmediately(of: frame) { newValue in
                                    if self.frames.count != items.count {
                                        self.frames = .init(repeating: .zero, count: items.count)
                                    }
                                    self.frames[i] = newValue
                                }
                        }
                    }
            }
        }
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if NSEvent.modifierFlags.contains(.command) {
                        
                    } else {
                        selection?.wrappedValue.removeAll()
                    }
                }
        }
        .apply(coordinateSpace)
        .apply(dragSelectGesture, isActive: self.selection != nil)
    }
    
    @ViewBuilder
    func coordinateSpace<C: View>(content: C) -> some View {
        if #available(macOS 14.0, *) {
            content
                .coordinateSpace(.named(coordinateSpaceName))
        } else {
            content
                .coordinateSpace(name: coordinateSpaceName)
        }
    }
    
    @ViewBuilder
    func dragSelectGesture<C: View>(content: C) -> some View {
        content
            .overlay {
                Canvas { context, size in
                    if let rect = selectRect {
                        context.stroke(
                            Path(roundedRect: rect, cornerRadius: 0),
                            with: .color(.accentColor)
                        )
                        context.fill(Path(roundedRect: rect, cornerRadius: 0),
                                     with: .color(.accentColor.opacity(0.2)))
                    }
                }
                .allowsHitTesting(false)
            }
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        selectRect = CGRect(
                            origin: value.startLocation,
                            size: value.translation
                        )
                        .absoluted()
                    })
                    .onEnded({ _ in
                        calculateDragSelection()
                        selectRect = nil
                    })
                )
    }
    
    func calculateDragSelection() {
        guard let selectRect = selectRect else { return }
        
        if NSEvent.modifierFlags.contains(.command) {
//            self.selection?.wrappedValue.insertOrRemove(item.id)
        } else if NSEvent.modifierFlags.contains(.shift) {
            //                                galleryStore.selectedItemIDs = [clipItem.id]
        } else {
            selection?.wrappedValue = []
        }
        
        for i in 0 ..< items.count {
//            print(frames[i], selectRect)
            if CGRectIntersectsRect(frames[i], selectRect) {
                selection?.wrappedValue.insert(items[i].id)
            }
        }
//        print("calculateDragSelection", selection)
    }
}

@available(macOS 13.0, iOS 16.0, macCatalyst 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
extension Gallery {
    class Config {
        var seletable = false
    }
    
//    public func seletable(_ enabled: Bool = true) -> some View {
//        self.config.seletable = enabled && self.selection != nil
//        return self
//    }
}

#if DEBUG
//#Preview {
//    Gallery()
//}
#endif
