//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/10/26.
//

import Foundation

public struct UnexpectedError: LocalizedError {
    public var errorDescription: String? { "Unexpected" }
}

extension Error where Self == UnexpectedError {
    public static var unexpected: UnexpectedError {
        UnexpectedError()
    }
}
