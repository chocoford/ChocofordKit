//
//  CGRect+Extension.swift
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
    
    /// inidicate it is a valid rect.
    var isValid: Bool {
        self.size.width > 0 && self.size.height > 0
    }
    
    var center: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }
    
    func substract(_ r2: CGRect) -> [CGRect] {
        guard self.intersects(r2) else { return [self] }
        var results: [CGRect] = []
        
        // top leading
        results.append(
            CGRect(
                origin: self.origin,
                size: CGSize(width: r2.minX - self.minX, height: r2.minY - self.minY)
            )
        )
        // top
        results.append(
            CGRect(
                origin: CGPoint(x: max(self.minX, r2.minX), y: self.minY),
                size: CGSize(
                    width: min(self.maxX, r2.maxX) - max(self.minX, r2.minX),
                    height: r2.minY - self.minY
                )
            )
        )
        // top trailing
        results.append(
            CGRect(
                origin: CGPoint(x: r2.maxX, y: self.minY),
                size: CGSize(
                    width: self.maxX - r2.maxX,
                    height: r2.minY - self.minY
                )
            )
        )
        // leading
        results.append(
            CGRect(
                origin: CGPoint(x: self.minX, y: r2.minY),
                size: CGSize(
                    width: r2.minX - self.minX,
                    height: min(self.maxY, r2.maxY) - max(self.minY, r2.minY)
                )
            )
        )
        // trailing
        results.append(
            CGRect(
                origin: CGPoint(x: r2.maxX, y: r2.minY),
                size: CGSize(
                    width: self.maxX - r2.maxX,
                    height: min(self.maxY, r2.maxY) - max(self.minY, r2.minY)
                )
            )
        )
        // bottom leading
        results.append(
            CGRect(
                origin: CGPoint(x: self.minX, y: r2.minY + r2.height),
                size: CGSize(width: r2.minX - self.minX, height: self.maxY - r2.maxY))
        )
        // bottom
        results.append(
            CGRect(
                origin: CGPoint(x: max(self.minX, r2.minX), y: r2.maxY),
                size: CGSize(
                    width: min(self.maxX, r2.maxX) - max(self.minX, r2.minX),
                    height: self.maxY - r2.maxY
                )
            )
        )
        // bottom trailing
        results.append(
            CGRect(
                origin: CGPoint(x: r2.maxX, y: r2.maxY),
                size: CGSize(
                    width: self.maxX - r2.maxX,
                    height: self.maxY - r2.maxY
                )
            )
        )
        
        return results.filter{$0.isValid}
    }
}


public extension [CGRect] {
    func substract(_ r2: CGRect) -> [CGRect] {
        self.flatMap {
            $0.substract(r2)
        }.filter{$0.isValid}
    }
}
