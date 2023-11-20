//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/18.
//

import SwiftUI

struct LazyGallery: View {
    var body: some View {
        GalleryCollectionView()
            .border(.red)
    }
}

struct GalleryCollectionView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSCollectionView {
        let collectionView = NSCollectionView()
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        collectionView.collectionViewLayout = flowLayout
        // 2
        collectionView.wantsLayer = true
        // 3
        collectionView.backgroundColors = [NSColor.black]
        
        return collectionView
    }
    
    func updateNSView(_ nsView: NSCollectionView, context: Context) {
        //        collectionView.dataSource =
    }
}

//class GalleryCollectionDataSource: NSCollectionViewDataSource {
//    
//}

#if DEBUG
#Preview {
//    LazyGallery()
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 20, maximum: 200))], spacing: 10) {
        ForEach(0..<5) { i in
//            Rectangle()
//                .frame(width: 200, height: 200)
//            Color.red
            GeometryReader { geometry in
                Color.red
            }
            .frame(height: 100)
        }
    }
    .frame(width: 500, height: 500)
}
#endif
