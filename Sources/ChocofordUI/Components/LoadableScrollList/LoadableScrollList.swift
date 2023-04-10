//
//  LoadableScrollList.swift
//  
//
//  Created by Dove Zachary on 2023/3/24.
//

import SwiftUI

public struct LoadableScrollList<Content: View,
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
    
    var onEvents: (_ event: LoadableListView<Content, Header, Footer, A, P, E, C, Items, VID, ID>.Event) async -> Void
    
    @State private var isLoadingAbove: Bool = false
    @State private var isLoadingBelow: Bool = false
    
    @State private var firstToList: Bool = true
    
    @State private var inScreenElements: [(index: Int, id: ID)] = []
    
    public init(viewID: VID = "",
                items: Items,
                id: KeyPath<Items.Element, ID>,
                spacing: CGFloat? = nil,
                hasBelow: Bool = false,
                hasAbove: Bool = false,
                startFromBottom: Bool = false,
                manuallyLoad: Bool = false,
                listContainer: C = EmptyModifier(),
                onEvents: @escaping (_ event: LoadableListView<Content, Header, Footer, A, P, E, C, Items, VID, ID>.Event) async -> Void,
                @ViewBuilder content: @escaping (Items.Element) -> Content,
                @ViewBuilder header: @escaping () -> Header = { EmptyView() },
                @ViewBuilder footer: @escaping () -> Footer = { EmptyView() },
                @ViewBuilder loadingActivator: @escaping (_ action: @escaping () -> Void) -> A = { _ in EmptyView() },
                @ViewBuilder loadingPlaceholder: @escaping () -> P = { CircularProgressView(size: 20, strokeColor: Color.accentColor) },
                @ViewBuilder emptyPlaceholder: @escaping () -> E) {
        self.viewID = viewID
        self.items = items
        self.id = id
        self.spacing = spacing
        self.hasBelow = hasBelow
        self.hasAbove = hasAbove
        self.startFromBottom = startFromBottom
        self.manuallyLoad = manuallyLoad
        self.listContainer = listContainer
        self.onEvents = onEvents
        self.content = content
        self.header = header
        self.footer = footer
        self.loadingActivator = loadingActivator
        self.loadingPlaceholder = loadingPlaceholder
        self.emptyPlaceholder = emptyPlaceholder
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LoadableListView(viewID: viewID,
                                 proxy: proxy,
                                 items: items,
                                 id: id,
                                 spacing: spacing,
                                 hasBelow: hasBelow,
                                 hasAbove: hasAbove,
                                 startFromBottom: startFromBottom,
                                 listContainer: listContainer,
                                 onEvents: onEvents,
                                 content: content,
                                 header: header,
                                 footer: footer,
                                 loadingActivator: loadingActivator,
                                 loadingPlaceholder: loadingPlaceholder,
                                 emptyPlaceholder: emptyPlaceholder)
            }
        }
    }
}


#if DEBUG
struct ListContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.red)
    }
}

struct LoadableScrollList_Previews: PreviewProvider {
    @State private static var items: [Int] = Array(0..<10)
    
    static var previews: some View {
        ZStack(alignment: .bottomTrailing) {
            LoadableScrollList(items: items,
                               id: \.self,
                               hasBelow: true,
                               hasAbove: true,
                               startFromBottom: true,
                               listContainer: ListContainer()) { event in
                switch event {
                    case .onLoadingBelow:
                        break
                    default:
                        break
                }
            } content: { i in
                Text(String(i))
                    .id(i)
                    .padding()
                    .background()
            } loadingPlaceholder: {
                ForEach(0..<10) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 200, height: 50)
                        .shimmering()
                }
            } emptyPlaceholder: {
                
            }
            
            VStack {
                Button {
                    items.insert(contentsOf: Array(-10..<0), at: 0)
                } label: {
                    Text("add above 10")
                }
                
                Button {
                    items.append(contentsOf: Array(10..<20))

                } label: {
                    Text("add below 10")
                }
            }
        }
    }
}
#endif
