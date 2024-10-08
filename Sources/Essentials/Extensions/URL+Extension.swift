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

    /// Get File size in bytes
    public func getFileSize() -> Int? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: self.path)
        if let fs = attrs?[FileAttributeKey.size] as? NSNumber {
            let bytes = Int64(truncating: fs)
            return Int(bytes)
        }
        return nil
    }
    
    
    /// [ChocofordKit]
    /// Get the file path of the url
    public var filePath: String {
        if #available(macOS 13.0, iOS 16.0, *) {
            path(percentEncoded: false)
        } else {
            standardizedFileURL.path
        }
    }
}
