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
public struct LoadableLazyVStack<Content: View,
                                 Header: View,
                                 Footer: View,
                                 A: View,
                                 P: View,
                                 E: View,
                                 Items: RandomAccessCollection,
                                 VID: Hashable,
                                 ID: Hashable>: View where Items: Hashable, Items.Element: Equatable {
    
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
                @ViewBuilder loadingPlaceholder: @escaping () -> P = { CircularProgressView().size(20) },
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
//        List {
            Section {
                Color.clear.frame(height: 0.1).id("top")
               
                contentView()
                
                Color.clear.frame(height: 0.1).id("bottom")
            } header: {
                header()
            } footer: {
                footer()
            }
        }
        .onChange(of: viewID) { _ in
            refreshView(config.scrollProxy)
        }
        .onChange(of: items) { val in
            guard items.count != val.count else { return }
            if firstToList {
                initScrollPos(config.scrollProxy)
                firstToList = false
                return
            }
            
            if val.first != items.first && config.hasAbove {
                scrollToFirstElementInScreen(config.scrollProxy)
            } else if val.last != items.last {
                // do nothing
                // scrollToLastElementInScreen(proxy)
            }
        }
        .onDisappear {
            stopGoing = true
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        if config.hasAbove || isLoadingAbove {
            if readyToLoadAbove || !config.manuallyLoad {
                Group {
                    loadingPlaceholder()
                }
                .onAppear(perform: onLoadingAbove)
                /// will be cancelled when use with SplitView
                //                    .task(onLoadingAbove)
            } else {
                loadTrigger(makeReadyAbove)
            }
        }
        
        if items.count > 0 {
            let contents: [EnumeratedSequence<Items>.Element] = Array(items.enumerated())
            let keyPath = \EnumeratedSequence<Items>.Element.element
            ForEach(contents, id: keyPath.appending(path: id)) { i, element in
                content(element)
                    .id(element[keyPath: id])
                    .onAppear {
                        inScreenElements.append((i, element[keyPath: id]))
                        if i == 0 {
                            Task {
                                await config.onEvents(.onScrollOnTop)
                            }
                        }
                    }
                    .onDisappear {
                        inScreenElements.removeAll { $0.1 == element[keyPath: id] }
                        if i == 0 {
                            Task {
                                await config.onEvents(.onScrollOffTop)
                            }
                        }
                    }
            }
        } else if !isLoadingAbove && !isLoadingBelow {
            emptyPlaceholder()
        }
        
        if config.hasBelow || isLoadingBelow {
            if readyToLoadBelow || !config.manuallyLoad {
                Group {
                    loadingPlaceholder()
                }
                .onAppear(perform: onLoadingBelow)
            } else {
                loadTrigger(makeReadyBelow)
            }
        }
    }
    
    @ViewBuilder
    private func loadTrigger(_ action: @escaping () -> Void) -> some View {
        loadingActivator(action)
    }
    
    private func makeReadyAbove() {
        readyToLoadAbove = true
    }
    
    private func makeReadyBelow() {
        readyToLoadBelow = true
    }
    
    
    private func refreshView(_ proxy: ScrollViewProxy?) {
        firstToList = true
        initScrollPos(proxy)
        firstToList = false
        inScreenElements.removeAll()
    }
    
    private func initScrollPos(_ proxy: ScrollViewProxy?) {
        if config.startFromBottom {
            if let id = items.last?[keyPath: id] {
                proxy?.scrollTo(id, anchor: .bottom)
            } else {
                proxy?.scrollTo("bottom", anchor: .bottom)
            }
        } else if config.hasAbove {
            if let id = items.first?[keyPath: id] {
                proxy?.scrollTo(id, anchor: .top)
            }
        }
    }
    
    /// scroll to the position of the first element with the anchor is `.top`
    private func scrollToFirstElementInScreen(_ proxy: ScrollViewProxy?) {
        if let top = inScreenElements.min(by: {
            $0.index < $1.index
        }) {
            proxy?.scrollTo(top.id, anchor: .top)
        }
    }
    
    /// scroll to the position of the last element with the anchor is `.bottom`
    private func scrollToLastElementInScreen(_ proxy: ScrollViewProxy?) {
        if let top = inScreenElements.max(by: {
            $0.index < $1.index
        }) {
            proxy?.scrollTo(top.id, anchor: .bottom)
        }
    }
    
    private func onLoadingAbove() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            guard !isLoadingAbove && !stopGoing else { return }
            isLoadingAbove = true
            Task {
                await config.onEvents(.onLoadingAbove)
                //        readyToLoadAbove = false
                isLoadingAbove = false
            }
        }
    }
    
    private func onLoadingBelow() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            guard !isLoadingBelow && !stopGoing else { return }
            isLoadingBelow = true
            Task {
                await config.onEvents(.onLoadingBelow)
                //        readyToLoadBelow = false
                isLoadingBelow = false
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
