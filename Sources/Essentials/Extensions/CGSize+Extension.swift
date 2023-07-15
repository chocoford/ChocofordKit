//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/22.
//

import Foundation

public extension CGSize {

#if os(macOS)
    init?(_ nsSize: NSSize?) {
        guard let nsSize = nsSize else { return nil }
        self = CGSize(width: nsSize.width, height: nsSize.height)
    }
#elseif os(iOS)
    init?(_ cgSize: CGSize?) {
        guard let cgSize = cgSize else { return nil }
        self = CGSize(width: cgSize.width, height: cgSize.height)
    }
#endif
}
