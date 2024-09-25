//
//  RadioGroup.swift
//  
//
//  Created by Dove Zachary on 2023/5/12.
//

import SwiftUI

public protocol RadioGroupCase: CaseIterable & Identifiable & Equatable where Self.AllCases: RandomAccessCollection {
    
}
//
//extension RadioGroupCase {
//    mutating func binding(_ forItem: Self) -> Binding<Bool> {
//        Binding {
//            return self == forItem
//        } set: { val in
//
//        }
//    }
//}

class RadioGroupViewModel<T: RadioGroupCase>: ObservableObject {
    @Published var selected: T
    
    init(selected: T) {
        self.selected = selected
    }
    
    func binding(for case: T) -> Binding<Bool> {
        Binding {
            return `case` == self.selected
        } set: { val in
            if val {
                self.selected = `case`
            }
        }
    }
}

public struct RadioGroup<O: RadioGroupCase, Content: View>: View {
    @Binding var selected: O
    
    var content: (_ option: O, _ isOn: Binding<Bool>) -> Content
    
    public init<Label: View>(
        selected: Binding<O>,
        radioLabelStyle: RadioButton<Label>.Style = .labelLeading,
        @ViewBuilder label: @escaping (_ option: O) -> Label
    ) where Content == RadioButton<Label> {
        self._selected = selected
        self.content = { option, isOn in
            RadioButton(isOn: isOn, style: radioLabelStyle) {
               label(option)
           }
        }
    }
    
    public init(
        selected: Binding<O>,
        @ViewBuilder content: @escaping (_ option: O, _ isOn: Binding<Bool>) -> Content
    ) {
        self._selected = selected
        self.content = content
    }
    
    public var body: some View {
        ForEach(O.allCases) { option in
            content(option, binding(for: option))
        }
    }
    
    func binding(for case: O) -> Binding<Bool> {
        Binding {
            return `case` == self.selected
        } set: { val in
            if val {
                withAnimation {
                    self.selected = `case`
                }
            }
        }
    }
}


#if DEBUG
struct RadioGroupPreviewView: View {
    enum Options: RadioGroupCase {
        case option1
        case option2
        
        var id: Int {
            switch self {
                case .option1:
                    return 1
                    
                case .option2:
                    return 2
            }
        }
        
        var text: String {
            switch self {
                case .option1:
                    return "option1"
                case .option2:
                    return "option2"
            }
        }
    }
    
    @State private var selected: Options = .option1
    
    var body: some View {
        RadioGroup(selected: $selected) { option, isOn in
            RadioButton(isOn: isOn) {
                Text(option.text)
            }
        }
    }
}


struct RadioGroup_Previews: PreviewProvider {
    static var previews: some View {
        RadioGroupPreviewView()
    }
}
#endif
