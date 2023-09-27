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

public enum FileSizeUnit {
    case bit
    case byte
}

extension Int {
    public func fileSizeFormatted(unit: FileSizeUnit = .byte) -> String {
        let kBytes = Double(self) / 1024
        if kBytes > 1024 {
            let mBytes: Double = kBytes / 1024
            return String(format: "%.1fMB", mBytes)
        } else {
            return String(format: "%.1fKB", kBytes)
        }
    }
}
