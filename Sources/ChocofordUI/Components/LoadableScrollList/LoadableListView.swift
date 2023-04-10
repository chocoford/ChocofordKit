//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/4/4.
//

import SwiftUI

public struct LoadableListView<Content: View,
                               Header: View,
                               Footer: View,
                               A: View,
                               P: View,
                               E: View,
                               C: ViewModifier,
                               Items: RandomAccessCollection,
                               VID: Hashable,
                               ID: Hashable>: View where Items: Hashable, Items.Element: Equatable {
    
    var viewID: VID
    
    var proxy: ScrollViewProxy
    
    var items: Items
    var id: KeyPath<Items.Element, ID>
    
    var hasBelow: Bool
    var hasAbove: Bool
    var startFromBottom: Bool
    var manuallyLoad: Bool
    
    var spacing: CGFloat?
    var content: (Items.Element) -> Content
    var header: () -> Header
    var footer: () -> Footer
    var loadingActivator: (_ action: @escaping () -> Void) -> A
    var loadingPlaceholder: () -> P
    var emptyPlaceholder: () -> E
    var listContainer: C
    
    var onEvents: (_ event: Event) async -> Void
    
    public enum Event {
        case onLoadingAbove
        case onLoadingBelow
        case onScrollOffTop
        case onScrollOnTop
    }

    public init(viewID: VID = "",
                proxy: ScrollViewProxy,
                items: Items,
                id: KeyPath<Items.Element, ID>,
                spacing: CGFloat? = nil,
                hasBelow: Bool = false,
                hasAbove: Bool = false,
                startFromBottom: Bool = false,
                manuallyLoad: Bool = false,
                listContainer: C = EmptyModifier(),
                onEvents: @escaping (_ event: Event) async -> Void,
                @ViewBuilder content: @escaping (Items.Element) -> Content,
                @ViewBuilder header: @escaping () -> Header = { EmptyView() },
                @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
                @ViewBuilder loadingActivator: @escaping (_ action: @escaping () -> Void) -> A = { _ in EmptyView() },
                @ViewBuilder loadingPlaceholder: @escaping () -> P = { CircularProgressView(size: 20, strokeColor: Color.accentColor) },
                @ViewBuilder emptyPlaceholder: @escaping () -> E = { EmptyView() }) {
        self.viewID = viewID
        self.proxy = proxy
        self.items = items
        self.id = id
        self.spacing = spacing
        self.hasBelow = hasBelow
        self.hasAbove = hasAbove
        self.startFromBottom = startFromBottom
        self.manuallyLoad = manuallyLoad
        self.onEvents = onEvents
        self.content = content
        self.header = header
        self.footer = footer
        self.loadingActivator = loadingActivator
        self.loadingPlaceholder = loadingPlaceholder
        self.listContainer = listContainer
        self.emptyPlaceholder = emptyPlaceholder
    }
    
    @State private var readyToLoadAbove: Bool = false
    @State private var readyToLoadBelow: Bool = false
    
    @State private var isLoadingAbove: Bool = false
    @State private var isLoadingBelow: Bool = false
    
    @State private var firstToList: Bool = true
    
    @State private var inScreenElements: [(index: Int, id: ID)] = []
    
    public var body: some View {
        LazyVStack(spacing: spacing) {
            Color.clear.frame(height: 0.1).id("top")
            if hasAbove {
                if readyToLoadAbove || !manuallyLoad {
                    loadingPlaceholder()
                        .task(onLoadingAbove)
                } else {
                    loadTrigger(makeReadyAbove)
                }
            } else {
                header()
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
                                    await onEvents(.onScrollOnTop)
                                }
                            }
                        }
                        .onDisappear {
                            inScreenElements.removeAll { $0.1 == element[keyPath: id] }
                            if i == 0 {
                                Task {
                                    await onEvents(.onScrollOffTop)
                                }
                            }
                        }
                }
            } else if !isLoadingAbove && !isLoadingBelow {
                emptyPlaceholder()
            }
            
            if hasBelow {
                if readyToLoadAbove || !manuallyLoad {
                    loadingPlaceholder()
                        .task(onLoadingBelow)
                } else {
                    loadTrigger(makeReadyBelow)
                }
            } else {
                footer()
            }
            Color.clear.frame(height: 0.1).id("bottom")
        }
        .modifier(listContainer)
        .onAppear {
            refreshView(proxy)
        }
        .onChange(of: viewID) { _ in
            refreshView(proxy)
        }
        .onChange(of: items) { val in
            guard items.count != val.count else { return }
            if firstToList {
                initScrollPos(proxy)
                firstToList = false
                return
            }
            
            if val.first != items.first {
                scrollToFirstElementInScreen(proxy)
            } else if val.last != items.last {
                // do nothing
//                    scrollToLastElementInScreen(proxy)
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
    
    
    private func refreshView(_ proxy: ScrollViewProxy) {
        firstToList = true
        initScrollPos(proxy)
        firstToList = false
        inScreenElements.removeAll()
    }
    
    private func initScrollPos(_ proxy: ScrollViewProxy) {
        if startFromBottom {
            if let id = items.last?[keyPath: id] {
                proxy.scrollTo(id, anchor: .bottom)
            } else {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        } else if hasAbove {
            if let id = items.first?[keyPath: id] {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }
    
    /// scroll to the position of the first element with the anchor is `.top`
    private func scrollToFirstElementInScreen(_ proxy: ScrollViewProxy) {
        if let top = inScreenElements.min(by: {
            $0.index < $1.index
        }) {
            proxy.scrollTo(top.id, anchor: .top)
        }
    }
    
    /// scroll to the position of the last element with the anchor is `.bottom`
    private func scrollToLastElementInScreen(_ proxy: ScrollViewProxy) {
        if let top = inScreenElements.max(by: {
            $0.index < $1.index
        }) {
            proxy.scrollTo(top.id, anchor: .bottom)
        }
    }
    
    @Sendable
    private func onLoadingAbove() async {
        guard !isLoadingAbove else { return }
        readyToLoadAbove = false
        isLoadingAbove = true
        await onEvents(.onLoadingAbove)
        isLoadingAbove = false
    }
    
    @Sendable
    private func onLoadingBelow() async {
        guard !isLoadingBelow else { return }
        readyToLoadBelow = false
        isLoadingBelow = true
        await onEvents(.onLoadingBelow)
        isLoadingBelow = false
    }
}

//#if DEBUG
//struct LoadableListView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoadableListView()
//
//    }
//}
//#endif
