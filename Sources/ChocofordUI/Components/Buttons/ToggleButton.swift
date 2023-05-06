//
//  File.swift
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
public struct RadioButton: NSViewRepresentable {
    @Binding var isOn: Bool
    
    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    public func makeNSView(context: Context) -> NSButton {
        NSButton(radioButtonWithTitle: "", target: context.coordinator, action: #selector(context.coordinator.onToggle))
    }
    public func updateNSView(_ button: NSButton, context: Context) {
        button.state = isOn ? .on : .off
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

extension RadioButton {
    public class Coordinator: NSObject {
        var parent: RadioButton
        
        
        public init(parent: RadioButton) {
            self.parent = parent
        }
        
        @objc
        func onToggle(sender: NSButton) {
            self.parent.isOn = sender.state == .on
        }
    }
}
#elseif os(iOS)

public struct RadioButton: View {
    @Binding var isOn: Bool
    
    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    public var body: some View {
        FakeRadioButton(isOn: $isOn)
    }
}

#endif

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
