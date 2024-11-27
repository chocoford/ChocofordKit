//
//  File.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/11/20.
//

import SwiftUI

struct ContainerUISizeClassKey: EnvironmentKey {
//#if os(macOS)
    static var defaultValue: UserInterfaceSizeClass? = .regular
//#else
//    static var defaultValue: UserInterfaceSizeClass? = .regular
//#endif
}

public extension EnvironmentValues {
    /// `horizontalSizeClass` only represents the current view’s state, while `containerHorizontalSizeClass` can retrieve the state of a user-defined container.
    var containerHorizontalSizeClass: UserInterfaceSizeClass? {
        get { self[ContainerUISizeClassKey.self] }
        set { self[ContainerUISizeClassKey.self] = newValue }
    }
    /// `verticalSizeClass` only represents the current view’s state, while `containerVerticalSizeClass` can retrieve the state of a user-defined container.
    var containerVerticalSizeClass: UserInterfaceSizeClass? {
        get { self[ContainerUISizeClassKey.self] }
        set { self[ContainerUISizeClassKey.self] = newValue }
    }
}

struct ContainerSizeClassModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    func body(content: Content) -> some View {
        content
            .environment(\.containerHorizontalSizeClass, horizontalSizeClass)
            .environment(\.containerVerticalSizeClass, verticalSizeClass)
    }
}

extension View {
    @MainActor @ViewBuilder
    public func containerSizeClassInjection() -> some View {
        modifier(ContainerSizeClassModifier())
    }
}
