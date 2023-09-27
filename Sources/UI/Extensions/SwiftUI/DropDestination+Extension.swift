//
//  View+onDrop.swift
//
//
//  Created by Dove Zachary on 2023/9/27.
//

#if canImport(SwiftUI)

import SwiftUI
import UniformTypeIdentifiers
import ChocofordEssentials


// MARK: - SizeLimitedDropDestination
public struct MaskDropDestination<Mask: View>: ViewModifier {
    var supportedContentTypes: [UTType]
    var maxSize: Int?
    var action: (_ providers: [NSItemProvider], _ location: CGPoint, _ sizeChecker: @escaping (Int) -> Bool) -> Bool
    var dropMask: () -> Mask

    public init(
        supportedContentTypes: [UTType],
        action: @escaping (_ providers: [NSItemProvider], _ location: CGPoint) -> Bool,
        @ViewBuilder dropMask: @escaping () -> Mask
    ) {
        self.supportedContentTypes = supportedContentTypes
        self.maxSize = nil
        self.action = { providers, location, _ in
            action(providers, location)
        }
        self.dropMask = dropMask
        self.isTargeted = isTargeted
    }
    
    
    public init(
        supportedContentTypes: [UTType],
        maxSize: Int? = nil,
        action: @escaping (_ providers: [NSItemProvider], _ location: CGPoint, _ sizeChecker: @escaping (Int) -> Bool) -> Bool,
        @ViewBuilder dropMask: @escaping () -> Mask
    ) {
        self.supportedContentTypes = supportedContentTypes
        self.maxSize = maxSize
        self.action = action
        self.dropMask = dropMask
        self.isTargeted = isTargeted
    }
    
    @State private var isTargeted: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .blur(radius: isTargeted ? 8.0 : 0.0)
            .onDrop(of: supportedContentTypes,
                    isTargeted: $isTargeted,
                    maxSize: maxSize,
                    perform: action)
            .overlay {
                if isTargeted {
                    dropMask()
                }
            }
            .animation(.easeInOut, value: isTargeted)
    }
}

public struct SizeLimitedDropDestination: ViewModifier {
    var supportedContentTypes: [UTType]
    var isTargeted: Binding<Bool>?
    var maxSize: Int?
    var action: ([NSItemProvider], CGPoint, _ sizeChecker: @escaping (Int) -> Bool) -> Bool

    public init(
        of supportedContentTypes: [UTType],
        isTargeted: Binding<Bool>? = nil,
        maxSize: Int?,
        perform action: @escaping ([NSItemProvider], CGPoint, @escaping (Int) -> Bool) -> Bool
    ) {
        self.supportedContentTypes = supportedContentTypes
        self.isTargeted = isTargeted
        self.maxSize = maxSize
        self.action = action
    }
    
    @State private var showAlert = false

    public func body(content: Content) -> some View {
        content
            .onDrop(of: supportedContentTypes, isTargeted: isTargeted) { providers, location in
                return self.action(providers, location) { size in
                    if let maxSize = self.maxSize, size > maxSize {
                        self.showAlert = true
                        return false
                    }
                    return true
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button {
                    showAlert.toggle()
                } label: {
                    Text("OK")
                }
            } message: {
                Text("Some of them have exceeded the maximum size limit: \(maxSize?.fileSizeFormatted() ?? "")")
            }
    }
}


extension View {
    @ViewBuilder
    public func onDrop(
        of supportedContentTypes: [UTType],
        isTargeted: Binding<Bool>?,
        maxSize: Int? = nil,
        perform action: @escaping (_ providers: [NSItemProvider], _ location: CGPoint, _ sizeChecker: @escaping (Int) -> Bool) -> Bool
    ) -> some View {
        modifier(
            SizeLimitedDropDestination(
                of: supportedContentTypes,
                isTargeted: isTargeted,
                maxSize: maxSize,
                perform: action
            )
        )
    }
    
    @ViewBuilder
    public func onDrop<Mask: View>(
        of supportedContentTypes: [UTType],
        maxSize: Int? = nil,
        perform action: @escaping (_ providers: [NSItemProvider], _ location: CGPoint, _ sizeChecker: @escaping (Int) -> Bool) -> Bool,
        @ViewBuilder dropMask: @escaping () -> Mask
    ) -> some View {
        modifier(
            MaskDropDestination(
                supportedContentTypes: supportedContentTypes,
                maxSize: maxSize,
                action: action,
                dropMask: dropMask
            )
        )
    }
    
    @ViewBuilder
    public func onDrop<Mask: View>(
        of supportedContentTypes: [UTType],
        perform action: @escaping (_ providers: [NSItemProvider], _ location: CGPoint) -> Bool,
        @ViewBuilder dropMask: @escaping () -> Mask
    ) -> some View {
        modifier(
            MaskDropDestination(
                supportedContentTypes: supportedContentTypes,
                action: action,
                dropMask: dropMask
            )
        )
    }
}
#endif
