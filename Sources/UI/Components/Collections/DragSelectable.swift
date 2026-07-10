//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/11/15.
//

import SwiftUI

struct SelectableView: View {
    @Binding var isSelected: Bool
    
    var content: AnyView
    
    init<Content: View>(
        isSelected: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self._isSelected = isSelected
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .onTapGesture {
                isSelected = true
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            proxy.frame(in: .named(""))
                        }
                }
            }
//        _VariadicView.Tree(
//            DividedLayout()
//        ) {
//
//        }
    }
}

struct DividedLayout: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        ForEach(children) { child in
            child
                
        }
    }
}

#if DEBUG
//#Preview {
//    DragSelectable {
//        
//    }
//}
#endif
