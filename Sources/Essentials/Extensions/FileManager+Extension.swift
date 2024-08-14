//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/11/17.
//

import Foundation

extension FileManager {
    public func fileExists(at url: URL) -> Bool {
        let path: String
        if #available(macOS 13.0, iOS 16.0, *) {
            path = url.path(percentEncoded: false)
        } else {
            path = url.standardizedFileURL.path
        }
        return fileExists(atPath: path)
    }
    
    public func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        var _isDirecotry = ObjCBool(false)
        let path: String
        if #available(macOS 13.0, iOS 16.0, *) {
            path = url.path(percentEncoded: false)
        } else {
            path = url.standardizedFileURL.path
        }
        let exist = fileExists(atPath: path, isDirectory: &_isDirecotry)
        isDirectory = _isDirecotry.boolValue
        return exist
    }
    
    
    public func isDirectory(_ url: URL) -> Bool {
        var _isDirecotry = false
        let exist = fileExists(at: url, isDirectory: &_isDirecotry)
        return exist && _isDirecotry
    }
}
