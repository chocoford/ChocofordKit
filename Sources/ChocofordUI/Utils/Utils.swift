//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/4/13.
//

import SwiftUI

#if os(macOS)
public func togglePreferenceView() {
    if #available(macOS 13, *) {
      NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
      NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
#endif
