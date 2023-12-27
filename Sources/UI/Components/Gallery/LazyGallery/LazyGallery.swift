//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/18.
//


import SwiftUI

struct Item: Hashable, Identifiable {
    var id: UUID = UUID()
    var text: String
}

struct LazyGallery: View {
    @State private var items: [Item] = [
        Item(text: "1"),
        Item(text: "2"),
        Item(text: "3"),
        Item(text: "4"),
        Item(text: "5"),
        Item(text: "6"),
        Item(text: "7"),
        Item(text: "8"),
        Item(text: "9"),
        Item(text: "10"),
//        Item(text: "11")
    ]
    
    @State private var size: CGFloat = 500
    
    var body: some View {
        ZStack {
            GalleryCollectionView(
                items: items//,
//                size: CGSize(width: size, height: size)
            ) { indexPath, item in
                Text("\(item.text)")
                    .padding(.horizontal, CGFloat(indexPath.item % 4) * 10)
                    .padding(.vertical)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
//            .frame(width: size, height: size)
            //            .animation(.bouncy, value: geometry.size)
            //        }
        }
//        .frame(width: 800, height: 800)
        .overlay(alignment: .bottomTrailing) {
            HStack {
                Button {
                    if size > 500 {
                        withAnimation(.easeInOut(duration: 1)) {
                            size = 500
                        }
                    } else {
                        //                        withAnimation(.easeInOut(duration: 1)) {
                        size = 700
                        //                        }
                    }
                } label: {
                    Image(systemName: "square.resize")
                }
                
                Button {
                    items.insert(Item(text: "\(items.count+1)"), at: 0)
                } label: {
                    Image(systemSymbol: .plus)
                }
            }
            .padding()
        }
    }
}

protocol GalleryCollectionSection: Hashable {
    associatedtype Item: Hashable, Identifiable
    
    var items: [Item] { get }
}

struct DefaultGalleryCollectionSection<Item: Hashable & Identifiable>: GalleryCollectionSection {
    var items: [Item]
}

#if DEBUG
#Preview {
    LazyGallery()
}
#endif
