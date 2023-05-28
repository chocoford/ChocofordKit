//
//  CheckboxToggleStyleCompatible.swift
//  
//
//  Created by Dove Zachary on 2023/5/1.
//

import SwiftUI

public struct CheckboxToggleStyleCompatible: ToggleStyle {
    var color: Color = .accentColor
    
    public func makeBody(configuration: Configuration) -> some View {
        let status: Binding<CheckboxStatus> = Binding {
            if #available(macOS 13.0, iOS 16.0, *) {
                return configuration.isMixed ? .indeterminate : configuration.isOn ? .checked : .unchecked
            } else {
                return configuration.isOn ? .checked : .unchecked
            }
        } set: { val in
            configuration.$isOn.wrappedValue = val == .checked
        }

        CheckboxButtonStyleView(status: status, color: color) {
            configuration.label
        }
    }
}

#if os(iOS)
public extension ToggleStyle where Self == CheckboxToggleStyleCompatible {
    static var checkboxStyle: CheckboxToggleStyleCompatible { CheckboxToggleStyleCompatible() }
    static func checkboxStyle(color: Color = .accentColor) -> CheckboxToggleStyleCompatible { CheckboxToggleStyleCompatible(color: color) }
}
#elseif os(macOS)
public extension ToggleStyle where Self == CheckboxToggleStyleCompatible {
    static var checkboxStyle: CheckboxToggleStyle { CheckboxToggleStyle() }
    static func checkboxStyle(color: Color = .accentColor) -> CheckboxToggleStyle { CheckboxToggleStyle() }
}
#endif
