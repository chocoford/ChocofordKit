//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/11.
//

import Foundation

extension Set {
    
    /// Insert element if element not exist in the set, otherwise remove.
    public mutating func insertOrRemove(_ element: Self.Element) {
        if self.contains(element) {
            self.remove(element)
        } else {
            self.insert(element)
        }
    }
}
