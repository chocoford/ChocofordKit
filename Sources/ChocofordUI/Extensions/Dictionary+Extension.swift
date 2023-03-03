//
//  Dictionary+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/8.
//

import Foundation
 
extension Dictionary {
    public static func + (lhs: [Key : Value], rhs: Self) -> Self  {
//        var result: Self = rhs
//
//        for (key, value) in lhs {
//            result[key] = value
//        }
//
//        return result
        
        return rhs.merging(lhs) { (_, new) in
            new
        }
    }
    
    public func decodeTo<T: Decodable>(_ type: T.Type) -> T? where Self.Key == String, Self.Value == Any {
        guard let data = try? JSONSerialization.data(withJSONObject: self) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
