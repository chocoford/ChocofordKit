//
//  CGSize+Extension.swift
//  
//
//  Created by Dove Zachary on 2023/6/22.
//

import Foundation

extension CGSize {

#if os(macOS)
     public init?(_ nsSize: NSSize?) {
         guard let nsSize = nsSize else { return nil }
         self = CGSize(width: nsSize.width, height: nsSize.height)
     }
#elseif os(iOS)
     public init?(_ cgSize: CGSize?) {
         guard let cgSize = cgSize else { return nil }
         self = CGSize(width: cgSize.width, height: cgSize.height)
     }
#endif
     
     public var distance: CGFloat { sqrt(pow(width, 2) + pow(height, 2)) }
     public var areaSize: CGFloat { width * height }
     public var aspectRatio: CGFloat { width / height }
     
     public static func / (lhs: CGSize, rhs: CGSize) -> CGFloat {
         lhs.areaSize / rhs.areaSize
     }
     public static func - (lhs: CGSize, rhs: CGSize) -> CGFloat {
         lhs.areaSize - rhs.areaSize
     }
     
 }
