//
//  UserNotificationCenter.swift
//  
//
//  Created by Chocoford on 2023/5/8.
//

import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public class UserNotificationCenter {
    public static let shared = UserNotificationCenter()
    
    var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }
    
    var granted: Bool = false
    
    var badgeLabel: Int = 0
    
    init() {}
}


public extension UserNotificationCenter {
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            self.granted = granted
        }
    }
    
    func pushNormalNotification(title: String, subtitle: String, body: String, sound: UNNotificationSound = .default) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = sound
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }
    
    func setBadgeLabel(_ label: Int) {
#if os(iOS)
        UIApplication.shared.applicationIconBadgeNumber = label
#elseif os(macOS)
        NSApp.dockTile.badgeLabel = "\(label)"
#endif
    }
    
    func clearBadgeLabel() {
#if os(iOS)
        UIApplication.shared.applicationIconBadgeNumber = 0
#elseif os(macOS)
        NSApp.dockTile.badgeLabel = ""
#endif
    }
}
