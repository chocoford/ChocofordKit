//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/24.
//

import SwiftUI

// MARK: - EmptyView Overlay
extension HPageView {
    public init<Data: RandomAccessCollection, ForEachContent: View>(
        items data: Data,
        @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element, _ geometry: GeometryProxy) -> ForEachContent
    ) where Data.Element: Identifiable, Pages == ForEach<Data, Data.Element.ID, ForEachContent>, Overlay == EmptyView {
        self.init(items: data, id: \.id, builder: builder)
    }
    
    public init<Data: RandomAccessCollection, ForEachContent: View>(
        items data: Data,
        @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element, _ geometry: GeometryProxy) -> ForEachContent
    ) where Data.Element: Hashable, Pages == ForEach<Data, Data.Element, ForEachContent>, Overlay == EmptyView {
        self.init(items: data, id: \.self, builder: builder)
    }
    
    public init<Data: RandomAccessCollection, ID: Hashable, ForEachContent: View>(
        items data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element, _ geometry: GeometryProxy) -> ForEachContent
    ) where Pages == ForEach<Data, ID, ForEachContent>, Overlay == EmptyView {
        let forEachContainer: (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> PageContainer<Pages> = { proxy, geometry in
            PageContainer(count: data.count, content: ForEach(data, id: id, content: ({ data in
                builder(proxy, data, geometry)
            })))
        }
        self.init(builder: forEachContainer)
    }
    
    public init(@PageViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> PageContainer<Pages>) where Overlay == EmptyView {
        self.pages = builder
    }
}




//
//public init<Data: RandomAccessCollection, ForEachContent: View>(
//    items data: Data,
//    @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element) -> ForEachContent,
//    @ViewBuilder overlay: @escaping ((_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay) = { _, _ in EmptyView() }
//) where Data.Element: Identifiable, Pages == ForEach<Data, Data.Element.ID, ForEachContent> {
//    self.init(items: data, id: \.id, builder: builder, overlay: overlay)
//}
//
//public init<Data: RandomAccessCollection, ForEachContent: View>(
//    items data: Data,
//    @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element) -> ForEachContent,
//    @ViewBuilder overlay: @escaping ((_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay) = { _, _ in EmptyView() }
//) where Data.Element: Hashable, Pages == ForEach<Data, Data.Element, ForEachContent> {
//    self.init(items: data, id: \.self, builder: builder, overlay: overlay)
//}
//
//public init<Data: RandomAccessCollection, ID: Hashable, ForEachContent: View>(
//    items data: Data,
//    id: KeyPath<Data.Element, ID>,
//    @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element) -> ForEachContent,
//    @ViewBuilder overlay: @escaping ((_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay) = { _, _ in EmptyView() }
//) where Pages == ForEach<Data, ID, ForEachContent> {
//    let forEachContainer: (_ proxy: PageViewProxy) -> PageContainer<Pages> = { proxy in
//        PageContainer(count: data.count, content: ForEach(data, id: id, content: ({ data in
//            builder(proxy, data)
//        })))
//    }
//    self.init(builder: forEachContainer, overlay: overlay)
//}
//
//public init(@PageViewBuilder builder: @escaping (_ proxy: PageViewProxy) -> PageContainer<Pages>,
//            @ViewBuilder overlay: @escaping ((_ proxy: PageViewProxy, _ geometry: GeometryProxy) -> Overlay) = { _, _ in EmptyView() }) {
//    self.pages = builder
//    self.overlay = overlay
//}


//public init<Data: RandomAccessCollection, ForEachContent: View>(
//    items data: Data,
//    @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element) -> ForEachContent
//) where Data.Element: Identifiable, Pages == ForEach<Data, Data.Element.ID, ForEachContent> {
//    self.init(items: data, id: \.id, builder: builder)
//}
//
//public init<Data: RandomAccessCollection, ForEachContent: View>(
//    items data: Data,
//    @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element) -> ForEachContent
//) where Data.Element: Hashable, Pages == ForEach<Data, Data.Element, ForEachContent> {
//    self.init(items: data, id: \.self, builder: builder)
//}
//
//public init<Data: RandomAccessCollection, ID: Hashable, ForEachContent: View>(
//    items data: Data,
//    id: KeyPath<Data.Element, ID>,
//    @ViewBuilder builder: @escaping (_ proxy: PageViewProxy, _ data: Data.Element) -> ForEachContent
//) where Pages == ForEach<Data, ID, ForEachContent> {
//    let forEachContainer: (_ proxy: PageViewProxy) -> PageContainer<Pages> = { proxy in
//        PageContainer(count: data.count, content: ForEach(data, id: id, content: ({ data in
//            builder(proxy, data)
//        })))
//    }
//    self.init(builder: forEachContainer)
//}
//
//public init(@PageViewBuilder builder: @escaping (_ proxy: PageViewProxy) -> PageContainer<Pages>) {
//    self.pages = builder
//}
