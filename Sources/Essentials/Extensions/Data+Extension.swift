//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/22.
//

import Foundation

//
//struct ImageHeaderData {
//    static var PNG: [UInt8] = [0x89]
//    static var JPEG: [UInt8] = [0xFF]
//    static var GIF: [UInt8] = [0x47]
//    static var TIFF_01: [UInt8] = [0x49]
//    static var TIFF_02: [UInt8] = [0x4D]
//}
//
//public enum ImageFormat {
//    case Unknown, PNG, JPEG, GIF, TIFF
//    public var `extension`: String? {
//        switch self {
//            case .Unknown:
//                return nil
//            case .PNG:
//                return "png"
//            case .JPEG:
//                return "jpeg"
//            case .GIF:
//                return "gif"
//            case .TIFF:
//                return "tiff"
//        }
//    }
//}
//
//public extension Data {
//    var imageFormat: ImageFormat {
//        var buffer = [UInt8](repeating: 0, count: 1)
//        self.copyBytes(to: &buffer, from: 0..<1)//.getBytes(&buffer, range: NSRange(location: 0,length: 1))
//        if buffer == ImageHeaderData.PNG
//        {
//            return .PNG
//        } else if buffer == ImageHeaderData.JPEG
//        {
//            return .JPEG
//        } else if buffer == ImageHeaderData.GIF
//        {
//            return .GIF
//        } else if buffer == ImageHeaderData.TIFF_01 || buffer == ImageHeaderData.TIFF_02{
//            return .TIFF
//        } else{
//            return .Unknown
//        }
//    }
//}
//

extension Data {
    private static let mimeTypeSignatures: [UInt8 : String] = [
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x47 : "image/gif",
        0x49 : "image/tiff",
        0x4D : "image/tiff",
        0x25 : "application/pdf",
        0xD0 : "application/vnd",
        0x46 : "text/plain",
        ]
    
    public var mimeType: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c] ?? "application/octet-stream"
    }
    
    public var fileExtension: String {
        switch mimeType {
        case "image/jpeg":
            return "jpeg"
        case "image/png":
            return "png"
        case "image/gif":
            return "gif"
        case "image/tiff":
            return "tiff"
        case "application/pdf":
            return "pdf"
        case "application/vnd":
            return "vnd"
        case "text/plain":
            return "txt"
        default:
            return "uknown"
        }
    }
    
    public func getSize(allowedUnits: ByteCountFormatter.Units = .useAll) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = allowedUnits
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(self.count))
    }
}
