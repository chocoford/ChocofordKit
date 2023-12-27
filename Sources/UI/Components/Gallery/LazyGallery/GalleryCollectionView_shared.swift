//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/26.
//

import Foundation

extension GalleryCollectionView {
    struct Changes {
        var inserts: Set<IndexPath> = []
        var reloads: Set<IndexPath> = []
        var deletes: Set<IndexPath> = []
    }
    internal func calculateChanges(oldSections: [Section]) -> Changes {
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

}
