//
//  RadioButton.swift
//  
//
//  Created by Chocoford on 2023/4/16.
//

import SwiftUI


struct FakeRadioButton: View {
    @Binding var isOn: Bool
    
    public var body: some View {
        content
            .onTapGesture {
                isOn = true
            }
    }
    
    @ViewBuilder
    public var content: some View {
        if isOn {
            backgroundCircle()
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 6, height: 6)
                        .shadow(radius: 1)
                )
        } else {
            Circle()
                .stroke(.gray)
                .frame(width: 14, height: 14)
        }
        
    }
    
    @ViewBuilder
    func backgroundCircle() -> some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            Circle()
                .fill(Color.accentColor.shadow(.inner(radius: 1)))
        } else {
            // Fallback on earlier versions
            Circle()
                .fill(Color.accentColor)
        }
    }
}


#if os(macOS)
struct SystemRadioButton: NSViewRepresentable {
    @Binding var isOn: Bool
    
    init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    func makeNSView(context: Context) -> NSButton {
        NSButton(radioButtonWithTitle: "", target: context.coordinator, action: #selector(context.coordinator.onToggle))
    }
    func updateNSView(_ button: NSButton, context: Context) {
        button.state = isOn ? .on : .off
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

extension SystemRadioButton {
    class Coordinator: NSObject {
        var parent: SystemRadioButton
        
        init(parent: SystemRadioButton) {
            self.parent = parent
        }
        
        @objc
        func onToggle(sender: NSButton) {
            self.parent.isOn = sender.state == .on
        }
    }
}
#endif

public struct RadioButton<L: View>: View {
    public enum Style {
        case labelLeading
        case labelTop
    }
    
    var label: () -> L
    var spacing: CGFloat
    var style: Style
    @Binding var isOn: Bool
    
    public init(
        isOn: Binding<Bool>,
        spacing: CGFloat = 4,
        style: Style = .labelLeading,
        @ViewBuilder label: @escaping (() -> L) = {EmptyView()}
    ) {
        self._isOn = isOn
        self.label = label
        self.spacing = spacing
        self.style = style
    }
    
    public var body: some View {
        if style == .labelLeading {
            HStack(spacing: spacing) {
                content()
            }
        } else if style == .labelTop {
            VStack(spacing: spacing) {
                content()
            }
        }
//        .onChange(of: isOn) { newValue in
//            print("on change \(newValue)")
//        }
    }
    
    @MainActor @ViewBuilder
    private func content() -> some View {
        label()
            .onTapGesture {
                self.isOn = true
            }
#if os(iOS)
        FakeRadioButton(isOn: $isOn)
#elseif os(macOS)
        SystemRadioButton(isOn: $isOn)
            .fixedSize()
#endif
    }
}


public struct RadioToggleStyleView<Content: View>: View {
    @Binding var isOn: Bool
    var content: () -> Content
    
    public init(isOn: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isOn = isOn
        self.content = content
    }
    
    public var body: some View {
        Circle()
    }
}


public struct RadioToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        RadioToggleStyleView(isOn: configuration.$isOn) {
            configuration.label
        }
    }
}

#if DEBUG
struct RadioButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            Toggle(isOn: .constant(true)) {
                
            }
            .toggleStyle(RadioToggleStyle())
            FakeRadioButton(isOn: .constant(true))
            RadioButton(isOn: .constant(true))
        }
    }
}
#endif
