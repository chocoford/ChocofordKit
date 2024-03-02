//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/13.
//

import Foundation


public func load<T: Decodable>(_ filename: String, type: T.Type) -> T {
    return load(filename)
}

public func load<T: Decodable>(
    _ filename: String,
    decoderConfig: (inout JSONDecoder) -> Void = {
        $0.dateDecodingStrategy = .secondsSince1970
    }
) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        var decoder = JSONDecoder()
        decoderConfig(&decoder)
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

