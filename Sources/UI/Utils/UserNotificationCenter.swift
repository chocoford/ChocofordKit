//
//  UserNotificationCenter.swift
//  
//
//  Created by Chocoford on 2023/5/8.
//

#if canImport(UserNotifications)
import Foundation
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public class UserNotificationCenter {
    public static let shared = UserNotificationCenter()
    
    public var delegate: UNUserNotificationCenterDelegate? {
        set {
            self.center.delegate = newValue
        }
        get {
            return self.center.delegate
        }
    }
    
    var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }
    
    public var granted: Bool = false
    
    var badgeLabel: Int = 0
    
    init() {}
}


public extension UserNotificationCenter {
    func checkPermission() async throws -> Bool {
        return try await center.requestAuthorization()
    }
    
    func requestPermission() async throws {
        self.granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func pushNormalNotification(title: String, subtitle: String, body: String, sound: UNNotificationSound = .default, userInfo: [AnyHashable : Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = sound
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error {
                dump(error)
            }
        }
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
#endif
