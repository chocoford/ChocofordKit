//
//  NSWorkspace+Extension.swift
//
//
//  Created by Dove Zachary on 2023/9/6.
//

#if canImport(AppKit)
import AppKit

public extension NSWorkspace {
    enum OpenSettingsType {
        case accessibility(AccessibilitySettingsType)
        case security(SecuritySettingsType)
        case notification(String?)

        
        public enum AccessibilitySettingsType {
            case main
            case display
            case zoom
            case voiceOver
            case descriptions
            case captions
            case audio
            case keyboard
            case mouseAndTrackpad
            case switchControl
            case dictation
        }
        
        public enum SecuritySettingsType {
            case main
            case general
            case fileVault
            case firewall
            case advanced
            case privacy
            case accessibility
            case assistive
            case locationServices
            case contacts
            case diagnosticsAndUsage
            case calendars
            case reminders
            case facebook
            case linkedIn
            case twitter
            case weibo
            case screenCpature
        }
    }
    
    /// reference:
    /// * https://gist.github.com/aerobounce/fa7b0e3d7e3129b269bcafb13059e8c6
    /// * https://gist.github.com/iccir/c1da6e537718b99b0c14ef76765aec45
    func openSettings(_ type: OpenSettingsType) {
        let url: URL
        switch type {
            case .accessibility(let accessibilitySettingsType):
                switch accessibilitySettingsType {
                    case .main:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess")!
                    case .display:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Display")!
                    case .zoom:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_Zoom")!
                    case .voiceOver:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Seeing_VoiceOver")!
                    case .descriptions:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Media_Descriptions")!
                    case .captions:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Captioning")!
                    case .audio:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Hearing")!
                    case .keyboard:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Keyboard")!
                    case .mouseAndTrackpad:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Mouse")!
                    case .switchControl:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?Switch")!
                    case .dictation:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess?SpeakableItems")!
                }
            case .security(let securitySettingsType):
                switch securitySettingsType {
                    case .main:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
                    case .general:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?General")!
                    case .fileVault:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?FDE")!
                    case .firewall:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Firewall")!
                    case .advanced:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Advanced")!
                    case .privacy:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
                    case .accessibility:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    case .assistive:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Assistive")!
                    case .locationServices:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!
                    case .contacts:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")!
                    case .diagnosticsAndUsage:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Diagnostics")!
                    case .calendars:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!
                    case .reminders:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")!
                    case .facebook:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Facebook")!
                    case .linkedIn:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LinkedIn")!
                    case .twitter:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Twitter")!
                    case .weibo:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Weibo")!
                    case .screenCpature:
                        url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
                }
            case .notification(let appName):
                if let name = appName {
                    url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
                } else {
                    url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
                }
        }
        open(url)
    }
}
#endif
