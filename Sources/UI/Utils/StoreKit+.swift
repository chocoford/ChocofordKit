//
//  StoreKit+.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 7/11/25.
//

import Foundation
import StoreKit
@Sendable
public func isChinaAppStore() async -> Bool {
    // ⚠️ Storefront.current 是 async
    if let storefront = await Storefront.current {
        return storefront.countryCode.uppercased() == "CHN"
    }
    return false
}
