//
//  KeyPathListable.swift
//  
//
//  Created by Dove Zachary on 2023/5/12.
//

import Foundation

//protocol KeyPathListable {
//    var allKeyPaths: [String: ReferenceWritableKeyPath<Self, Any>] { get }
//}
//
//extension KeyPathListable {
//
//    private subscript(checkedMirrorDescendant key: String) -> Any {
//        return Mirror(reflecting: self).descendant(key)!
//    }
//
//    var allKeyPaths: [String: ReferenceWritableKeyPath<Self, Any>] {
//        var membersTokeyPaths = [String: ReferenceWritableKeyPath<Self, Any>]()
//        let mirror = Mirror(reflecting: self)
//        for case (let key?, _) in mirror.children {
//            membersTokeyPaths[key] = \Self.[checkedMirrorDescendant: key] as ReferenceWritableKeyPath
//        }
//        return membersTokeyPaths
//    }
//
//}
