//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/5/24.
//

import SwiftUI

public extension Timer {
    @MainActor
    static func wait(_ interval: TimeInterval) async {
        _ = await withCheckedContinuation { continuation in
            Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { timer in
                continuation.resume(with: .success(timer))
            }
        }
    }
}
