//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/6/15.
//

#if canImport(SwiftUI)
import SwiftUI

public enum TitleDisplayModeCompatible {
    case inline
    case large
    case automatic
    
    #if os(iOS)
    var titleDisplayMode: NavigationBarItem.TitleDisplayMode {
        switch self {
            case .automatic:
                return .automatic
            case .large:
                return .large
            case .inline:
                return .inline
        }
    }
    #endif
}

public extension View {
    @ViewBuilder
    func navigationTitleCompatible(_ titleKey: LocalizedStringKey) -> some View {
#if os(iOS)
        navigationTitle(titleKey)
#elseif os(macOS)
        self
#endif
    }
    
    @ViewBuilder
    func navigationTitleCompatible<S>(_ title: S, iOSOnly: Bool = false) -> some View where S : StringProtocol {
        navigationTitleCompatible(Text(title), iOSOnly: iOSOnly)
    }
    
    @ViewBuilder
    func navigationTitleCompatible(_ text: Text, iOSOnly: Bool = false) -> some View {
#if os(iOS)
        navigationTitle(text)
#elseif os(macOS)
        if iOSOnly {
            self
        } else {
            VStack(alignment: .leading, spacing: 6) {
                text
                    .font(.largeTitle)
                
                self
            }
        }
#endif
    }

    @ViewBuilder
    func navigationBarTitleDisplayModeCompatible(_ displayMode: TitleDisplayModeCompatible) -> some View {
#if os(iOS)
        navigationBarTitleDisplayMode(displayMode.titleDisplayMode)
#elseif os(macOS)
        self
#endif
    }
    
    @ViewBuilder
    func navigationBarBackButtonHiddenCompatible(_ hidesBackButton: Bool = true) -> some View {
        if #available(macOS 13.0, iOS 13.0, watchOS 6.0, macCatalyst 13.0, tvOS 13.0, visionOS 1.0, *) {
            navigationBarBackButtonHidden(hidesBackButton)
        } else {
            self
        }
    }
}
#endif
