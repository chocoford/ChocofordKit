//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/15.
//

import Foundation
extension CGRect {
    public func absoluted() -> CGRect {
        if size.width > 0 && size.height > 0 {
            return self
        }
        
        var newRect = self
        
        if size.width < 0 {
            newRect.origin.x += size.width
            newRect.size.width = abs(size.width)
        }
        
        if size.height < 0 {
            newRect.origin.y += size.height
            newRect.size.height = abs(size.height)
        }
        
        return newRect
    }
}
