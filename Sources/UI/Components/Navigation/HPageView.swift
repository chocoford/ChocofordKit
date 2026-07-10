//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/23.
//

import SwiftUI
import SFSafeSymbols

public struct HPageView<Pages: View, Overlay: View>: View {
    var pages: (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> PageContainer<Pages>
//    var overlay: (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay
    @ObservedObject var config: Config<Overlay> = .init()
    @StateObject var proxy: PageViewProxy = .init()
    
    public init<Data: RandomAccessCollection, ForEachContent: View>(
        items data: Data,
        @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element, _ geometry: GeometryProxy) -> ForEachContent
    ) where Data.Element: Identifiable, Pages == ForEach<Data, Data.Element.ID, ForEachContent> {
        self.init(items: data, id: \.id, builder: builder)
    }
    
    public init<Data: RandomAccessCollection, ForEachContent: View>(
        items data: Data,
        @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element, _ geometry: GeometryProxy) -> ForEachContent
    ) where Data.Element: Hashable, Pages == ForEach<Data, Data.Element, ForEachContent> {
        self.init(items: data, id: \.self, builder: builder)
    }
    
    public init<Data: RandomAccessCollection, ID: Hashable, ForEachContent: View>(
        items data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element, _ geometry: GeometryProxy) -> ForEachContent
    ) where Pages == ForEach<Data, ID, ForEachContent> {
        let forEachContainer: (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> PageContainer<Pages> = { proxy, geometry in
            PageContainer(count: data.count, content: ForEach(data, id: id, content: ({ data in
                builder(proxy, data, geometry)
            })))
        }
        self.init(builder: forEachContainer)
    }
    
    public init(@PageViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> PageContainer<Pages>) {
        self.pages = builder
    }
    
    @State private var dragOffset: CGSize = .zero
    
    public var body: some View {
        GeometryReader { geometry in
            LazyHStack(spacing: 0) {
                let offsetX = -1 * CGFloat(proxy.currentPage) * geometry.size.width + dragOffset.width
                pages(proxy, geometry)
                    .onPreferenceChange(PagesCountKey.self) { count in
                        proxy.pagesCount = count
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: offsetX, y: 0)
#if os(iOS)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                        .onChanged { value in
                            self.dragOffset = value.translation
                        }
                        .onEnded { value in
                            self.dragOffset = .zero
                            switch value.translation.width {
                                case ...0: proxy.toggleNext(animation: nil)
                                case 0...: proxy.togglePrev(animation: nil)
                                default: break //print("no clue")
                            }
                        }
                    )
                    .animation(.default, value: offsetX)
#endif
            }
        }
        .overlay {
            GeometryReader { geometry in
                if let overlay = config.overlayView {
                    overlay(proxy, geometry)
                }
            }
        }
    }
}



extension HPageView {
    class Config<Overlay: View>: ObservableObject {
        var pageViewStyle: PageViewStyle = .plain
        var overlayView: ((_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay)?
    }
    
    func pageViewStyle(_ style: PageViewStyle) -> HPageView {
        self.config.pageViewStyle = style
        return self
    }
    
    public func overlay(@ViewBuilder content: @escaping (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay) -> HPageView {
        self.config.overlayView = content
        return self
    }
}

public enum PageViewStyle {
    case plain
    case macTips(_ image: String, _ title: String, _ body: String)
}


public final class PageViewProxy: ObservableObject {
    @Published public var pagesCount: Int = 0
    @Published public var currentPage: Int = 0
    
    public var canPrevPage: Bool { currentPage > 0 }
    public var canNextPage: Bool { currentPage < pagesCount - 1 }
    
    public func togglePrev(animation: Animation? = .default) {
        guard canPrevPage else { return }
        withAnimation(animation) { currentPage -= 1 }
    }
    
    public func toggleNext(animation: Animation? = .default) {
        guard canNextPage else { return }
        withAnimation(animation) { currentPage += 1 }
    }

    
    @ViewBuilder
    public func prevPageButton<L: View>(animation: Animation = .default,
                                        @ViewBuilder label: () -> L = { Image(systemSymbol: .chevronLeft) }) -> some View {
        Button {
            print("togglePrev")
            self.togglePrev(animation: animation)
        } label: {
            label()
        }
        .opacity(canPrevPage ? 1 : 0)
        .disabled(!canPrevPage)
    }
    
    @ViewBuilder
    public func nextPageButton<L: View>(animation: Animation = .default,
                                        @ViewBuilder label: () -> L = { Image(systemSymbol: .chevronRight) }) -> some View {
        Button {
            self.toggleNext(animation: animation)
        } label: {
            label()
        }
        .opacity(canNextPage ? 1 : 0)
        .disabled(!canNextPage)
    }
}

struct HorizontalPageStack<Pages>: View where Pages: View {
    let pages: Pages
    let geometry: GeometryProxy
    
    init(pages: Pages, geometry: GeometryProxy){
        self.pages = pages
        self.geometry = geometry
    }
    
    var body: some View {
        HStack(spacing: 0.0) {
            pages
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#if DEBUG
struct HPageView_Previews: PreviewProvider {
    static var previews: some View {
        HPageView { proxy, _ in
            HStack {
                proxy.prevPageButton(animation: .easeOut)
                Spacer()
                Text("page 1")
                Spacer()
                proxy.nextPageButton(animation: .easeOut)
            }
            .padding(.horizontal)

            HStack {
                Button {
                    proxy.togglePrev()
                } label: {
                    Image(systemSymbol: .chevronLeft)
                }
                Text("page 2")
                Button {
                    proxy.toggleNext()
                } label: {
                    Image(systemSymbol: .chevronRight)
                }
            }

        }
        .buttonStyle(.borderless)
    }
}
#endif
