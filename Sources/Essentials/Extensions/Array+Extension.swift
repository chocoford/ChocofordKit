//
//  File.swift
//  
//
//  Created by Chocoford on 2023/4/4.
//

import Foundation

public extension Array {
    func value(at index: Array.Index) -> Self.Element? {
        if index >= 0 && self.count > index {
            return self[index]
        } else {
            return nil
        }
    }
    
    /// Updating element if found. And return it without mutating self.
    func updatingItem(_ item: Element) -> Self where Element: Identifiable {
        guard let index = self.firstIndex(where: {
            $0.id == item.id
        }) else { return self }
        var items = self
        items[index] = item
        return items
    }
    
    func updatingItem(from item: Element, to newItem: Element) -> Self where Element: Hashable {
        guard let index = self.firstIndex(where: {
            $0 == item
        }) else { return self }
        var items = self
        items[index] = newItem
        return items
    }
    
    func removingItem(where condition: (Element) -> Bool) -> Self {
        guard let index = self.firstIndex(where: condition) else { return self }
        var items = self
        items.remove(at: index)
        return items
    }
    
    
    func removingItem(of item: Element) -> Self where Element: Equatable {
        return removingItem(where: {$0 == item})
    }
    
    
    func removingItem(_ item: Element) -> Self where Element: Identifiable {
        return removingItem(where: {$0.id == item.id})
    }
    
    func insertingItem(_ item: Element, at: Int) -> Self {
        var array = self
        array.insert(item, at: at)
        return array
    }
    
    func replacingItem(_ item: Element, at: Int) -> Self {
        var array = self
        array[at] = item
        return array
    }
    
    func removingDuplicate(replace: Bool = false) -> Self where Element: Identifiable, Element: Hashable {
        return self.removingDuplicate(id: \.id, replace: replace)
    }
    func removingDuplicate(replace: Bool = false) -> Self where Element: Identifiable {
        return self.removingDuplicate(id: \.id, replace: replace)
    }
    func removingDuplicate(replace: Bool = false) -> Self where Element: Hashable {
        return self.removingDuplicate(id: \.self, replace: replace)
    }
    
    /// Returns a array with removing duplicate items.
    /// - Parameters:
    ///   - id: The idenfier of object.
    ///   - replace: Indicates where a new one should replace the old one.
    /// - Returns: The filtered array.
    func removingDuplicate<ID: Hashable>(id: KeyPath<Element, ID>, replace: Bool = false) -> Self {
        var result: [Element] = []
        var existingIDs: Set<ID> = Set()
        for element in self {
            if !existingIDs.contains(element[keyPath: id]) {
                result.append(element)
                existingIDs.insert(element[keyPath: id])
            } else if replace,
                      let index = result.firstIndex(where: {$0[keyPath: id] == element[keyPath: id]}) {
                result.remove(at: index)
                result.append(element)
            }
        }
        return result
    }
    
    func merged<K, T>() -> [K : T] where K: Hashable, Element == [K : T]  {
        reduce(into: [K : T]()) { $0.merge($1) { $1 } }
    }
}
