//
//  Encodable+Extension.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import Foundation
extension Encodable {
    public subscript(key: String) -> Any? {
        return dictionary[key]
    }
    public var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
    
    public  var description: String {
        return String(describing: self)
    }
    
    public func jsonStringified(percentEncoding: Bool = false) throws -> String {
        let data = try JSONEncoder().encode(self)
        let stringified = String(data: data, encoding: String.Encoding.utf8) ?? ""
        if !percentEncoding {
            return stringified
        }
        if let encoded = stringified.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return encoded
        }
        return ""
    }
}



//extension JSONDecoder.DateDecodingStrategy {
//    static let multiple = custom {
//        let container = try $0.singleValueContainer()
//        do {
//            return try Date(timeIntervalSince1970: container.decode(Double.self))
//        } catch DecodingError.typeMismatch {
//            let string = try container.decode(String.self)
//            if let date = Formatter.iso8601withFractionalSeconds.date(from: string) ??
//                Formatter.iso8601.date(from: string) ??
//                Formatter.ddMMyyyy.date(from: string) {
//                return date
//            }
//            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
//        }
//    }
//}
