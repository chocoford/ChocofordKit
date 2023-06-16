//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/16.
//

import Foundation

public extension Int {
    init?(_ double: Double?) {
        guard let double = double else { return nil }
        self = Int(double)
    }
}
