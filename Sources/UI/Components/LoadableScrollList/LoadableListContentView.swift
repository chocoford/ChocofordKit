//
//  LoadableListContentView.swift
//  
//
//  Created by Dove Zachary on 2023/7/24.
//

import SwiftUI

//public enum LoadableListContentEvent {
//    case onLoadingAbove
//    case onLoadingBelow
//    case onScrollOffTop
//    case onScrollOnTop
//
//    func mappingToLoadableListEvent() -> LoadableListEvent {
//        switch self {
//            case .onLoadingAbove:
//                return LoadableListEvent.onLoadingAbove
//            case .onLoadingBelow:
//                return LoadableListEvent.onLoadingBelow
//        }
//    }
//}

public struct LoadableListContentView<
    Content: View,
    Items: RandomAccessCollection,
    ID: Hashable,
    VID: Hashable
>: View where Items: Hashable, Items.Element: Equatable {
    var viewID: VID
    
    var items: Items
    var id: KeyPath<Items.Element, ID>
    
    var content: (Items.Element) -> Content

    public init(
        viewID: VID = "",
        items: Items,
        id: KeyPath<Items.Element, ID>,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) {
        self.viewID = viewID
        self.items = items
        self.id = id
        self.content = content
    }
    
    public init(
        viewID: VID = "",
        items: Items,
        @ViewBuilder content: @escaping (Items.Element) -> Content
    ) where Items.Element: Identifiable, ID == Items.Element.ID {
        self.init(
            viewID: viewID,
            items: items,
            id: \.id,
            content: content
        )
    }
    
    
    var config = Config()
    
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
        Color.clear.frame(height: self.config.anchorTopHeight).id("top")
            .apply(listRowStyle)
            .onAppear {
                Task {
                    await self.config.onEvents(.onReachTop)
                }
            }
            .onDisappear {
                Task {
                    await self.config.onEvents(.onLeaveTop)
                }
            }
        
        contentView()
            .onChange(of: viewID) { _ in
                refreshView(config.scrollProxy)
            }
            .onAppear {
                print("LoadableListContentView onAppear")
                if self.config.startFromBottom {
                    self.config.scrollProxy?.scrollTo("bottom")
                    DispatchQueue.main.async {
                        self.config.scrollProxy?.scrollTo("bottom")
                    }
                }
                DispatchQueue.main.async {
                    makeReadyAbove()
                    makeReadyBelow()
                }
            }
            .onDisappear {
                print("LoadableListContentView onDisappear")
//                stopGoing = true
            }
        
        Color.clear.frame(height: self.config.anchorBottomHeight).id("bottom")
            .apply(listRowStyle)
            .onAppear {
                Task {
                    await self.config.onEvents(.onReachBottom)
                }
            }
            .onDisappear {
                Task {
                    await self.config.onEvents(.onLeaveBottom)
                }
            }
    }
    
    
    @ViewBuilder
    private func contentView() -> some View {
        if config.hasAbove || isLoadingAbove {
            if readyToLoadAbove {
                self.config.loadingIndicator
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
            self.config.placeholder
        }
        
        if config.hasBelow || isLoadingBelow {
            if readyToLoadBelow || !config.manuallyLoad {
                self.config.loadingIndicator
                    .onAppear(perform: onLoadingBelow)
            } else {
                loadTrigger(makeReadyBelow)
            }
        }
    }
    
    @ViewBuilder
    private func loadTrigger(_ action: @escaping () async throws -> Void) -> some View {
        self.config.loadMoreActivator(action)
    }
    
    @ViewBuilder
    private func listRowStyle<ListRow: View>(content: ListRow) -> some View {
        Group {
            if #available(macOS 13.0, iOS 15.0, *) {
                content
                    .listRowSeparator(.hidden)
            } else {
                content
            }
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

internal extension LoadableListContentView {
    private func refreshView(_ proxy: ScrollViewProxy?) {
        firstToList = true
        initScrollPos(proxy)
        firstToList = false
        inScreenElements.removeAll()
    }
    
    private func initScrollPos(_ proxy: ScrollViewProxy?) {
        if self.config.startFromBottom {
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
    
    private func makeReadyAbove() {
        readyToLoadAbove = true
    }
    
    private func makeReadyBelow() {
        readyToLoadBelow = true
    }
    
    private func onLoadingAbove() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            guard !isLoadingAbove && !stopGoing else { return }
            isLoadingAbove = true
            let oldTop = self.items.first
            Task {
                await config.onEvents(.onLoadingAbove)
                if !inScreenElements.isEmpty,
                   let id = inScreenElements.sorted(by: {$0.index < $1.index}).first?.id {
                    self.config.scrollProxy?.scrollTo(id, anchor: .top)
                } else if let top = oldTop {
                    self.config.scrollProxy?.scrollTo(top[keyPath: id], anchor: .bottom)
                }
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
                isLoadingBelow = false
            }
        }
    }
}


extension LoadableListContentView {
    class Config: ObservableObject {
        var scrollProxy: ScrollViewProxy? = nil

        var hasBelow: Bool = false
        var hasAbove: Bool = false
        var startFromBottom: Bool = false
        var manuallyLoad: Bool = false
                
        var onEvents: (_ event: LoadableListEvent) async -> Void = {_ in return}
        
        var placeholder: AnyView = AnyView(EmptyView())
        var loadingIndicator: AnyView = AnyView(Center(.horizontal) {ProgressView().controlSize(.small)})
        var loadMoreActivator: (_ action: @escaping () async throws -> Void) -> AnyView = { _ in AnyView(EmptyView()) }
        
        var anchorTopHeight: CGFloat = 1
        var anchorBottomHeight: CGFloat = 1
    }
    
    public func scrollProxy(_ proxy: ScrollViewProxy?) -> LoadableListContentView {
        self.config.scrollProxy = proxy
        return self
    }
    
    public func hasBelow(_ flag: Bool) -> LoadableListContentView {
        self.config.hasBelow = flag
        return self
    }
    
    public func hasAbove(_ flag: Bool) -> LoadableListContentView {
        self.config.hasAbove = flag
        return self
    }
    
    public func appearFromBottom(_ flag: Bool = true) -> LoadableListContentView {
        self.config.startFromBottom = flag
        return self
    }
    
    public func onEvents(
        _ callback: @escaping (_ event: LoadableListEvent) async -> Void
    ) -> LoadableListContentView {
        self.config.onEvents = callback
        return self
    }
    
    public func loadingIndicator<Indicator: View>(@ViewBuilder indicator: () -> Indicator) -> LoadableListContentView {
        self.config.loadingIndicator = AnyView(indicator())
        return self
    }
    
    public func manullyLoad<Activator: View>(
        _ flag: Bool = true,
        @ViewBuilder activator: @escaping (_ action: @escaping () async throws -> Void) -> Activator
    ) -> LoadableListContentView {
        self.config.manuallyLoad = flag
        self.config.loadMoreActivator = { action in
            AnyView(activator(action))
        }
        return self
    }
    
    public func placeholder<P: View>(@ViewBuilder placeholder: () -> P) -> LoadableListContentView {
        self.config.placeholder = AnyView(placeholder())
        return self
    }
    
    
    /// Set the height of top/bottom anchor, default is `20`.
    public func anchorHeight(_ anchor: UnitPoint? = nil, _ height: CGFloat) -> LoadableListContentView {
        switch anchor {
            case .some(.top):
                self.config.anchorTopHeight = height
            case .some(.bottom):
                self.config.anchorBottomHeight = height
            default:
                self.config.anchorTopHeight = height
                self.config.anchorBottomHeight = height
        }
        return self
    }
}
