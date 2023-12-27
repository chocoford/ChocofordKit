//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/23.
//

#if canImport(UIKit) && canImport(SwiftUI)
import SwiftUI
import UIKit

struct GalleryCollectionView<Content: View, Section: GalleryCollectionSection>: UIViewRepresentable {
    var sections: [Section]
    var content: (IndexPath, Section.Item) -> Content

    public init(
        sections: [Section],
        @ViewBuilder content: @escaping (IndexPath, Section.Item) -> Content
    ) {
        self.content = content
        self.sections = sections
    }
    
    public init<Item>(
        items: [Item],
        @ViewBuilder content: @escaping (IndexPath, Section.Item) -> Content
    ) where Item == Section.Item, DefaultGalleryCollectionSection<Item> == Section {
        self.content = content
        self.sections = [DefaultGalleryCollectionSection(items: items)]
    }
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = context.coordinator.collectionView
//        collectionView.collectionViewLayout = flowLayout
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")

        collectionView.isScrollEnabled = true
        
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
                
        context.coordinator.oldSections = self.sections
        
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        let changes = self.calculateChanges(oldSections: context.coordinator.oldSections)
        print(changes)
        context.coordinator.collectionView.performBatchUpdates {
            context.coordinator.collectionView.insertItems(at: Array(changes.inserts))
            context.coordinator.collectionView.reloadItems(at: Array(changes.reloads))
            context.coordinator.collectionView.deleteItems(at: Array(changes.deletes))
        }
        
        DispatchQueue.main.async {

            context.coordinator.oldSections = self.sections
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
    
extension GalleryCollectionView {
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var parent: GalleryCollectionView
        let flowLayout: UICollectionViewFlowLayout = {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.itemSize = CGSize(width: 160.0, height: 140.0)
            flowLayout.sectionInset = UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
            flowLayout.minimumInteritemSpacing = 20.0
            flowLayout.minimumLineSpacing = 20.0
            return flowLayout
        }()
        lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        
        var oldSections: [Section] = []
        
        
        init(parent: GalleryCollectionView) {
            self.parent = parent
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return self.parent.sections.count
        }
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.parent.sections[section].items.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath)
            let contentView = self.parent.content(indexPath, self.parent.sections[indexPath.section].items[indexPath.item])

            let hostingVC = UIHostingController(rootView: AnyView(contentView))
            
//            cell.contentView.addSubview(<#T##view: UIView##UIView#>)
//            cell.contentView = UIHostingController(rootView: AnyView(contentView))
            cell.backgroundColor = .red
            return cell
        }
        
    }
    
    class GalleryCell: UICollectionViewCell {
        var hostingView: UIHostingController<AnyView>?
      
        func setSwiftUIView(_ view: AnyView) {
            if hostingView == nil {
//                hostingView = NSHostingView(rootView: view)
//                hostingView?.translatesAutoresizingMaskIntoConstraints = false
//                self.view.addSubview(hostingView!)
////                hostingView?.needsLayout = true
//                NSLayoutConstraint.activate([
//                    hostingView!.topAnchor.constraint(equalTo: self.view.topAnchor),
//                    hostingView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
//                    hostingView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
//                    hostingView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
//                ])
            } else {
                hostingView?.rootView = view
            }
        }
        
        
    }
}

#if DEBUG
#Preview {
    LazyGallery()
}

#endif
#endif

