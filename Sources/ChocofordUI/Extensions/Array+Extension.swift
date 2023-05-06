//
//  File.swift
//  
//
//  Created by Chocoford on 2023/4/4.
//

import Foundation

extension Array {
    public func value(at index: Array.Index) -> Self.Element? {
        if self.count > index {
            return self[index]
        } else {
            return nil
        }
    }
    
    /// Updating element if found. And return it without mutating self.
    public func updatingItem(_ item: Element) -> Self where Element: Identifiable {
        guard let index = self.firstIndex(where: {
            $0.id == item.id
        }) else { return self }
        var items = self
        items[index] = item
        return items
    }
    
    public func removingItem(where condition: (Element) -> Bool) -> Self {
        guard let index = self.firstIndex(where: condition) else { return self }
        var items = self
        items.remove(at: index)
        return items
    }
    
    
    public func removingItem(of item: Element) -> Self where Element: Equatable {
        return removingItem(where: {$0 == item})
    }
    
    
    public func removingItem(_ item: Element) -> Self where Element: Identifiable {
        return removingItem(where: {$0.id == item.id})
    }
    
    public func insertingItem(_ item: Element, at: Int) -> Self {
        var array = self
        array.insert(item, at: at)
        return array
    }
    
    public func replacingItem(_ item: Element, at: Int) -> Self {
        var array = self
        array[at] = item
        return array
    }
    
    public func removingDuplicate() -> Self where Element: Identifiable {
        return self.removingDuplicate(id: \.id)
    }
    
    public func removingDuplicate<ID: Hashable>(id: KeyPath<Element, ID>) -> Self {
        var result: [Element] = []
        var existingIDs: Set<ID> = Set()
        for element in self {
            if !existingIDs.contains(element[keyPath: id]) {
                result.append(element)
                existingIDs.insert(element[keyPath: id])
            }
        }
        return result
    }
}
