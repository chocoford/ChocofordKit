//
//  URL+Extension.swift
//  
//
//  Created by Dove Zachary on 2023/9/11.
//

import Foundation

extension URL {
    public func removingQuery() -> URL {
        let urlStringWithoutQuery = absoluteString.components(separatedBy: "?").first ?? absoluteString
        return URL(string: urlStringWithoutQuery) ?? self
    }
}
