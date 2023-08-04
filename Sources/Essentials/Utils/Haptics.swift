//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/7/24.
//

import CoreHaptics

public final class HapticsCenter {
    public static let shared: HapticsCenter = HapticsCenter()
    
    var isSupported: Bool = false
    var engine: CHHapticEngine
    
    
    init() {
        let hapticCapability = CHHapticEngine.capabilitiesForHardware()
        self.isSupported = hapticCapability.supportsHaptics
        do {
            self.engine = try CHHapticEngine()
        } catch let error {
            fatalError("Fail to create engine: \(error)")
        }
    }
 
    public func playSingleTapHaptics() {
        let hapticDict = [
            CHHapticPattern.Key.pattern: [
                [CHHapticPattern.Key.event: [
                    CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                    CHHapticPattern.Key.time: CHHapticTimeImmediate,
                    CHHapticPattern.Key.eventDuration: 1.0] as [CHHapticPattern.Key : Any]
                ]
            ]
        ]
        do {
            let pattern = try CHHapticPattern(dictionary: hapticDict)
            let player = try engine.makePlayer(with: pattern)
            engine.notifyWhenPlayersFinished { error in
                return .stopEngine
            }
            try engine.start()
            try player.start(atTime: 0)
        } catch {
            dump(error)
        }
    }
}


