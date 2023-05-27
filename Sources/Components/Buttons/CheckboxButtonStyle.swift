//
//  CheckboxButtonStyle.swift
//  
//
//  Created by Chocoford on 2023/5/1.
//

import SwiftUI

public struct CheckboxButtonStyle: PrimitiveButtonStyle {
    @Binding var status: CheckboxStatus
    var color: Color = .accentColor
    
    public init(status: Binding<CheckboxStatus>, color: Color = .accentColor) {
        self._status = status
        self.color = color
    }
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        PrimitiveButtonWrapper {
            configuration.trigger()
        } content: { isPressed in
            CheckboxButtonStyleView(status: $status, isPressed: isPressed, color: color) {
                configuration.label
            }
        }
        
    }
}

public enum CheckboxStatus {
    case checked
    case unchecked
    case indeterminate
}


struct CheckboxButtonStyleView<Label: View>: View {
    @Binding var status: CheckboxStatus
    var isPressed: Bool = false
    var color: Color = .accentColor

    var label: () -> Label
    
    init(status: Binding<CheckboxStatus>,
         isPressed: Bool = false,
         color: Color = .accentColor,
         @ViewBuilder label: @escaping () -> Label = { EmptyView() }) {
        self._status = status
        self.isPressed = isPressed
        self.color = color
        self.label = label
    }
    
    @State private var isHover: Bool = false
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(status == .unchecked ? .gray : color)
                .frame(width: 16, height: 16)
                .background{
                    RoundedRectangle(cornerRadius: 4)
                        .fill((status == .unchecked ? .clear : color).opacity(isHover ? 0.2 : 0.1))
                }
                .overlay {
                    if let image = statusImage() {
                        Center {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .padding(4)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                    }
                }
                .padding(2)
                .overlay {
                    if isPressed {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(color.opacity(0.1), lineWidth: 4)
                    }
                }
                .padding(2)
                .padding(1)
            
            label()
        }
        .onHover { hover in
            isHover = hover
        }
    }
    
    func statusImage() -> Image? {
        if case .checked = status {
            return Image(systemName: "checkmark")
        } else if case .indeterminate = status {
            return Image(systemName: "minus")
        }
        return nil
    }
}

#if DEBUG
struct CheckboxButtonStyleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CheckboxButtonStyleView(status: .constant(.unchecked))
            CheckboxButtonStyleView(status: .constant(.checked))
            CheckboxButtonStyleView(status: .constant(.indeterminate))
        }
    }
}
#endif
