//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/23.
//

#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI

extension GalleryCollectionView {
    typealias SectionIdentifierType = Int
    typealias ItemIdentifierType = UUID
    public typealias DataSource = NSCollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>
}

struct GalleryCollectionViewControllerRepresentable: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> GalleryCollectionViewController {
        GalleryCollectionViewController()
    }
    
    func updateNSViewController(_ nsViewController: GalleryCollectionViewController, context: Context) {
        
    }
}

struct GalleryCollectionView<Content: View, Section: GalleryCollectionSection>: NSViewRepresentable {
    var sections: [Section]
//    var size: CGSize

    var content: (IndexPath, Section.Item) -> Content
//    @State private var oldSections: [Section] = []
//    @State private var oldSize: CGSize = .zero
    
    public init(
        sections: [Section],
//        size: CGSize,
        @ViewBuilder content: @escaping (IndexPath, Section.Item) -> Content
    ) {
        self.content = content
        self.sections = sections
//        self.size = size
    }
    
    public init<Item>(
        items: [Item],
//        size: CGSize,
        @ViewBuilder content: @escaping (IndexPath, Section.Item) -> Content
    ) where Item == Section.Item, DefaultGalleryCollectionSection<Item> == Section {
        self.content = content
        self.sections = [DefaultGalleryCollectionSection(items: items)]
//        self.size = size
    }
    
    public init(
        sections: [Section],
//        size: CGSize,
        @ViewBuilder content: @escaping (Section.Item) -> Content
    ) {
        self.content = {_, item in
            content(item)
        }
        self.sections = sections
//        self.size = size
    }
    
    public init<Item>(
        items: [Item],
//        size: CGSize,
        @ViewBuilder content: @escaping (Section.Item) -> Content
    ) where Item == Section.Item, DefaultGalleryCollectionSection<Item> == Section {
        self.content = {_, item in
            content(item)
        }
        self.sections = [DefaultGalleryCollectionSection(items: items)]
//        self.size = size
    }
    
    
    func makeNSView(context: Context) -> NSScrollView {
        let flowLayout: AnimatedCollectionViewFlowLayout = {
            let flowLayout = AnimatedCollectionViewFlowLayout()
            flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
            flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
            flowLayout.minimumInteritemSpacing = 20.0
            flowLayout.minimumLineSpacing = 20.0
            return flowLayout
        }()

        let collectionView = context.coordinator.collectionView
        collectionView.collectionViewLayout = flowLayout
        collectionView.isSelectable = true
//        collectionView.wantsLayer = true
        
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        
        collectionView.register(MyItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("MyItem"))
        
        context.coordinator.oldSections = self.sections
        
        // Scroll View
        let scrollView = NSScrollView()
        scrollView.documentView = collectionView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        print("updateNSView", context.coordinator.collectionView.frame)
        context.coordinator.parent = self
        let changes = self.calculateChanges(oldSections: context.coordinator.oldSections)
        context.coordinator.collectionView.animator().performBatchUpdates {
            context.coordinator.collectionView.insertItems(at: changes.inserts)
            context.coordinator.collectionView.reloadItems(at: changes.reloads)
            context.coordinator.collectionView.deleteItems(at: changes.deletes)
        }
//        if context.coordinator.collectionView.frame.size != self.size {
//
//            let oldSize = context.coordinator.collectionView.frame.size
//            context.coordinator.collectionView.setFrameSize(oldSize)
//            DispatchQueue.main.async {
//                context.coordinator.collectionView.animator().setFrameSize(self.size)
//            }
//        }
        
        
        DispatchQueue.main.async {

            context.coordinator.oldSections = self.sections
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
        var parent: GalleryCollectionView
        
        var collectionView = NSCollectionView() //AnimatedCollectionView()
        var oldSections: [Section] = []
        
        init(_ parent: GalleryCollectionView) {
            self.parent = parent
        }
        
        func numberOfSections(in collectionView: NSCollectionView) -> Int {
            return self.parent.sections.count
        }
        
        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            return self.parent.sections[section].items.count
        }
        
        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            guard let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("MyItem"), for: indexPath) as? MyItem else {
                fatalError("Expected to dequeue MyItem. Check the configuration in makeNSView.")
            }
            let contentView = self.parent.content(indexPath, self.parent.sections[indexPath.section].items[indexPath.item])
            item.setSwiftUIView(AnyView(contentView))
            return item
        }
        
        func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
            let contentView = self.parent.content(indexPath, self.parent.sections[indexPath.section].items[indexPath.item])
            
            return NSHostingView(rootView: contentView).fittingSize //NSSize(width: 100.0, height: 100.0)
        }
        
        var selectedRow: Int? = nil
        
        func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
            for indexPath in indexPaths { // { .first {
                if self.selectedRow != nil && self.selectedRow! == indexPath.item {
                    self.selectedRow = nil
                } else {
                    self.selectedRow = indexPath.item
                }
                
                if let cell = collectionView.item(at: indexPath.item) {
                    CATransaction.begin()
                    let animation = CABasicAnimation(keyPath: "transform.scale")
                    animation.duration = 2.0
                    animation.fromValue = 1.0
                    animation.toValue = 1.5
                    cell.view.layer!.zPosition = 1
                    cell.view.layer?.add(animation, forKey: "transform.scale")
                    cell.view.layer?.setAffineTransform( CGAffineTransform(scaleX: 1.5, y: 1.5)) //<<--- NEW CODE
                    CATransaction.commit()
                }
            }
        }
        
        func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
            for indexPath in indexPaths {
                let theItem = indexPath.item
                
                if let cell = collectionView.item(at: theItem) {
                    CATransaction.begin()
                    let animation = CABasicAnimation(keyPath: "transform.scale")
                    animation.duration = 1.0
                    animation.fromValue = 1.5
                    animation.toValue = 1.0
                    cell.view.layer!.zPosition = -1
                    cell.view.layer?.add(animation, forKey: "transform.scale")
                    cell.view.layer?.setAffineTransform( CGAffineTransform(scaleX: 1, y: 1))
                    CATransaction.commit()
                }
            }
        }
    }

    private func calculateChanges(oldSections: [Section]) -> Changes {
        var inserts = Set<IndexPath>()
        var deletes = Set<IndexPath>()
        var reloads = Set<IndexPath>()
        
        for (i, section) in sections.enumerated() {
            let oldSection = oldSections.value(at: i)
            guard section != oldSection else { continue }
            
            let new = section.items
            let old = oldSection?.items ?? []
            let oldSet = Set(old)
            let newSet = Set(new)
            // 计算插入和删除的项目
            let insertedItems = newSet.subtracting(oldSet)
            let deletedItems = oldSet.subtracting(newSet)
            
            // 为了简化，这里我们只计算插入和删除，而不是重载
            // 重载通常用于那些标识符未改变，但内容改变的项目
            // 需要更精细的逻辑来处理重载

            for (index, newItem) in new.enumerated() {
                if insertedItems.contains(newItem) {
                    inserts.insert(IndexPath(item: index, section: i))
                }
            }
            
            for (index, oldItem) in old.enumerated() {
                if deletedItems.contains(oldItem) {
                    deletes.insert(IndexPath(item: index, section: i))
                }
            }
            
        }
        
        
        // 重载逻辑
        // 例如，如果你的数据项有一个改变的属性，你可以在这里检查并添加到重载集合中

        return Changes(inserts: inserts, reloads: reloads, deletes: deletes)
    }
    
    
    class MyItem: NSCollectionViewItem {
        var hostingView: NSHostingView<AnyView>?
      
        func setSwiftUIView(_ view: AnyView) {
            if hostingView == nil {
                hostingView = NSHostingView(rootView: view)
                hostingView?.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(hostingView!)
//                hostingView?.needsLayout = true
                NSLayoutConstraint.activate([
                    hostingView!.topAnchor.constraint(equalTo: self.view.topAnchor),
                    hostingView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    hostingView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    hostingView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                ])
            } else {
                hostingView?.rootView = view
            }
        }
        
        override func loadView() {
            self.view = NSView()
//            self.view.wantsLayer = true
        }
    }
    
    struct Changes {
        var inserts: Set<IndexPath> = []
        var reloads: Set<IndexPath> = []
        var deletes: Set<IndexPath> = []
    }
}


class GalleryCollectionViewController: NSViewController {
    var collectionView: NSCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // 初始化和配置 collectionView
    }
}

class AnimatedCollectionViewFlowLayout : NSCollectionViewFlowLayout {
//    var indexPathsToAnimate: [IndexPath] = []
    var oldLayoutAttributes: [IndexPath: NSCollectionViewLayoutAttributes] = [:]

    override func prepare() {
        print("prepare")
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        guard let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath),
              let oldAttributes = oldLayoutAttributes[itemIndexPath] else {
            return nil
        }
        print("initialLayoutAttributesForAppearingItem at", itemIndexPath, attributes.frame, oldAttributes.frame)
//        attributes.frame = oldAttributes.frame
        attributes.alpha = 0
        return attributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        guard let oldBounds = self.collectionView?.bounds else { return false }
        print("shouldInvalidateLayout", oldBounds.size != newBounds.size)
        return oldBounds.size != newBounds.size
    }
    
    override func prepare(forCollectionViewUpdates updateItems: [NSCollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        print("prepare forCollectionViewUpdates", updateItems)
        // 在更新之前，存储旧的布局属性
        for sectionIndex in 0..<(self.collectionView?.numberOfSections ?? 0) {
            for itemIndex in 0..<(self.collectionView?.numberOfItems(inSection: sectionIndex) ?? 0) {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)
                oldLayoutAttributes[indexPath] = attributes
            }
        }
        
//        oldLayoutAttributes = self.layoutAttributesForElements(in: collectionView!.visibleRect).reduce(into: [:]) { (result, attributes) in
//            if let indexPath = attributes.indexPath {
//                result[indexPath] = attributes
//            }
//        }
//        print(oldLayoutAttributes.map{$0.value.frame})
    }
    
    override func prepare(forAnimatedBoundsChange oldBounds: NSRect) {
        print("prepare forAnimatedBoundsChange", oldBounds)
        super.prepare(forAnimatedBoundsChange: oldBounds)
    }
    
    override func prepareForTransition(from oldLayout: NSCollectionViewLayout) {
        print("prepareForTransition from", oldLayout)
        super.prepareForTransition(from: oldLayout)
    }
    
    override func prepareForTransition(to newLayout: NSCollectionViewLayout) {
        print("prepareForTransition to", newLayout)
        super.prepareForTransition(to: newLayout)
    }
    
    override func finalizeAnimatedBoundsChange() {
        print("finalizeAnimatedBoundsChange")
        super.finalizeAnimatedBoundsChange()
        
        // 清空旧的布局信息
        oldLayoutAttributes = [:]
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: NSPoint) -> NSPoint {
        print("targetContentOffset forProposedContentOffset", proposedContentOffset)
        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    
}

class AnimatedCollectionView: NSCollectionView {
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        print("setFrameSize", newSize)
    }
    
    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        print("viewWillStartLiveResize")
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        print("viewDidEndLiveResize")
    }
}
#endif
