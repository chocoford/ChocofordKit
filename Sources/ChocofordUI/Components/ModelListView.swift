//
//  ModelListView.swift
//  
//
//  Created by Chocoford on 2023/4/29.
//

import SwiftUI

/// A List that click will show a model instaed of navigation
public struct ModelListView<Item: Identifiable, Cell: View, Detail: View>: View {
    var selection: Binding<Item?>?

    var items: [Item]
    
    var cellView: (_ item: Item) -> Cell
    var detailView: (_ item: Item) -> Detail
    
    public init(items: [Item],
                @ViewBuilder cell: @escaping (_ item: Item) -> Cell,
                @ViewBuilder detail: @escaping (_ item: Item) -> Detail) {
        self.selection = nil
        self.items = items
        self.cellView = cell
        self.detailView = detail
    }
    
    
    public init(items: [Item],
                selection: Binding<Item?>,
                @ViewBuilder cell: @escaping (_ item: Item) -> Cell,
                @ViewBuilder detail: @escaping (_ item: Item) -> Detail) {
        self.items = items
        self.selection = selection
        self.cellView = cell
        self.detailView = detail
    }
    
    @Namespace private var changlogNamespace
    
    @State private var currentItem: Item? = nil
    private var currentItemBinding: Binding<Item?> {
        Binding(get: {
            if let selection = selection {
                return selection.wrappedValue
            } else {
                return self.currentItem
            }
        }, set: { val in
            selection?.wrappedValue = val
            self.currentItem = val
        })
    }
    
    @State private var cellHeight: CGFloat = 0
    
    public var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    ForEach(Array(items.enumerated()), id: \.1.id) { i, item in
                        if item.id != currentItemBinding.wrappedValue?.id {
                            cellView(item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        currentItemBinding.wrappedValue = item
                                    }
                                }
                                .matchedGeometryEffect(id: item.id,
                                                       in: changlogNamespace,
                                                       properties: .frame,
                                                       anchor: .center)
                                .background {
                                    if i == 0 {
                                        GeometryReader { geometry in
                                            Color.clear
                                                .watchImmediately(of: geometry.size.height) { height in
                                                    cellHeight = height
                                                }
                                        }
                                    }
                                }
                        } else {
                            Color.clear.frame(width: nil, height: cellHeight)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .zIndex(1)
            .blur(radius: currentItemBinding.wrappedValue != nil ? 10 : 0)
            
            if let item = currentItemBinding.wrappedValue {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            currentItemBinding.wrappedValue = nil
                        }
                    }
                    .overlay(alignment: .center) {
                        detailView(item)
                            .matchedGeometryEffect(id: item.id,
                                                   in: changlogNamespace,
                                                   properties: .frame,
                                                   anchor: .center,
                                                   isSource: false)
                            .shadow(radius: 50)
                            .padding()
                    }
                    .zIndex(2)
            }
        }
    }
}

#if DEBUG
struct MyChangeLogItem: Identifiable {
    var version: String
    var title: String
    var summary: String
    var date: Date
    var detail: AttributedString
    
    var id: String {
        version
    }
}

struct ChangeLogPreviewView: View {
    @State private var items: [MyChangeLogItem] = [
        .init(version: "0.0.1",
              title: "First init",
              summary: "123",
              date: .init(timeIntervalSince1970: 86400 * 100),
              detail: (try? AttributedString(markdown: "Hi")) ?? "")
    ]
    
    var body: some View {
        ModelListView(items: items) { item in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.version)
                        .font(.headline)
                    Spacer()
                    Text(item.date.relativeFormatted(maxRelative: .week))
                }
                Text(item.summary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
#if os(macOS)
                    .fill(.background)
#elseif os(iOS)
                    .fill(.ultraThickMaterial)
#endif
            }
        } detail: { item in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.version)
                        .font(.headline)
                    Spacer()
                    Text(item.date.relativeFormatted(maxRelative: .week))
                }
                Text(item.summary)
                Text(item.detail)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
#if os(macOS)
                    .fill(.background)
#elseif os(iOS)
                    .fill(.ultraThickMaterial)
#endif
            }
        }

    }
}

struct ChangeLogView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeLogPreviewView()
            .previewLayout(.fixed(width: 500, height: 700))
    }
}
#endif
