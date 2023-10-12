//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/4.
//

import SwiftUI

public enum LoadableListEvent {
    case onLoadingAbove
    case onLoadingBelow
    case onScrollOffTop
    case onScrollOnTop
}

/// Known issue: Use with SplitView(H/W) will cause task cancelled.
public struct LoadableLazyVStack<
    Content: View,
    Header: View,
    Footer: View,
    A: View,
    P: View,
    E: View,
    Items: RandomAccessCollection,
    VID: Hashable,
    ID: Hashable
>: View where Items: Hashable, Items.Element: Equatable {
    
    @ObservedObject var config = Config()
    
    var viewID: VID
    
    var items: Items
    var id: KeyPath<Items.Element, ID>
    
    var spacing: CGFloat?
    var content: (Items.Element) -> Content
    var header: () -> Header
    var footer: () -> Footer
    var loadingActivator: (_ action: @escaping () -> Void) -> A
    var loadingPlaceholder: () -> P
    var emptyPlaceholder: () -> E
    
    public init(viewID: VID = "",
                items: Items,
                id: KeyPath<Items.Element, ID>,
                spacing: CGFloat? = nil,
                isLoadingAbove: Bool = false,
                isLoadingBelow: Bool = false,
                @ViewBuilder content: @escaping (Items.Element) -> Content,
                @ViewBuilder loadingActivator: @escaping (_ action: @escaping () -> Void) -> A = { _ in EmptyView() },
                @ViewBuilder loadingPlaceholder: @escaping () -> P = { ProgressView().controlSize(.small) },
                @ViewBuilder emptyPlaceholder: @escaping () -> E = { EmptyView() },
                @ViewBuilder header: @escaping () -> Header = { EmptyView() },
                @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }) {
        self.viewID = viewID
        self.items = items
        self.id = id
        self.spacing = spacing
        self.content = content
        self.header = header
        self.footer = footer
        self.loadingActivator = loadingActivator
        self.loadingPlaceholder = loadingPlaceholder
        self.emptyPlaceholder = emptyPlaceholder
        
        self.isLoadingAbove = isLoadingAbove
        self.isLoadingBelow = isLoadingBelow
    }
    
    @State private var readyToLoadAbove: Bool = false
    @State private var readyToLoadBelow: Bool = false
    
    @State private var isLoadingAbove: Bool = false
    @State private var isLoadingBelow: Bool = false
    
    @State private var firstToList: Bool = true
    
    @State private var inScreenElements: [(index: Int, id: ID)] = []
    
    /// `NavigationStack + .navigationDestination` will make view appear twice.
    /// in a result, we must prevent loading twice. This is `stopGoing` propose to do.
    @State private var stopGoing = false
    
    public var body: some View {
        LazyVStack(spacing: spacing, pinnedViews: config.pinnedViews) {
            Section {
                LoadableListContentView(
                    items: self.items,
                    id: self.id,
                    content: self.content,
                    loadingPlaceholder: self.loadingPlaceholder,
                    loadingActivator: self.loadingActivator,
                    emptyPlaceholder: self.emptyPlaceholder
                )
                .scrollProxy(self.config.scrollProxy)
                .onEvents(self.config.onEvents)
                .hasBelow(self.config.hasBelow)
                .hasAbove(self.config.hasAbove)
                .manullyLoad(self.config.manuallyLoad)
                .appearFromBottom(self.config.startFromBottom)
            } header: {
                header()
            } footer: {
                footer()
            }
        }
    }
}

extension LoadableLazyVStack {
    class Config: ObservableObject {
        var scrollProxy: ScrollViewProxy? = nil
        var pinnedViews: PinnedScrollableViews = []
        
        var hasBelow: Bool = false
        var hasAbove: Bool = false
        var startFromBottom: Bool = false
        var manuallyLoad: Bool = false
        
        var spacing: CGFloat = 0
        
        var onEvents: (_ event: LoadableListEvent) async -> Void = {_ in return}
    }
    
    public func scrollProxy(_ proxy: ScrollViewProxy) -> LoadableLazyVStack {
        self.config.scrollProxy = proxy
        return self
    }
    
    public func pinnedViews(_ views: PinnedScrollableViews) -> LoadableLazyVStack {
        self.config.pinnedViews = views
        return self
    }
    
    public func hasBelow(_ flag: Bool) -> LoadableLazyVStack {
        self.config.hasBelow = flag
        return self
    }
    
    public func hasAbove(_ flag: Bool) -> LoadableLazyVStack {
        self.config.hasAbove = flag
        return self
    }
    
    public func appearFromBottom(_ flag: Bool = true) -> LoadableLazyVStack {
        self.config.startFromBottom = flag
        return self
    }
    
    public func manullyLoad(_ flag: Bool = true) -> LoadableLazyVStack {
        self.config.manuallyLoad = flag
        return self
    }
    
    public func onEvents(_ callback: @escaping (_ event: LoadableListEvent) async -> Void) -> LoadableLazyVStack {
        self.config.onEvents = callback
        return self
    }
}


//#if DEBUG
//struct LoadableLazyVStack_Previews: PreviewProvider {
//    static var previews: some View {
//        LoadableLazyVStack()
//
//    }
//}
//#endif
