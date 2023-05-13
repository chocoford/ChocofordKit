//
//  RadioGroupModel.swift
//  
//
//  Created by Dove Zachary on 2023/5/12.
//

import SwiftUI
import Combine
 
public protocol RadioGroupModel: ObservableObject {
    var allKeyPaths: [ReferenceWritableKeyPath<Self, Bool>] { get set }
}

public extension RadioGroupModel {
    func binding(for keyPath: ReferenceWritableKeyPath<Self, Bool>) -> Binding<Bool> {
        Binding {
            self[keyPath: keyPath]
        } set: { val in
            if val {
                self.allKeyPaths.forEach { keyPath in
                    self[keyPath: keyPath] = false
                }
                self[keyPath: keyPath] = val                
            }
        }
    }
}
