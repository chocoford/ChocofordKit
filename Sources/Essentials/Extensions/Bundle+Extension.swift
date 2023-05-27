//
//  File.swift
//  
//
//  Created by Chocoford on 2023/4/29.
//

import Foundation

public extension Bundle {
    var displayName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }
}
