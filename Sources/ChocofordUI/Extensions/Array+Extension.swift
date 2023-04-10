//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/4/4.
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
}
