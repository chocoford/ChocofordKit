//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/22.
//

import SwiftUI

//struct BlockButtonStyle: PrimitiveButtonStyle {
////    var config: Config
//    
//    func makeBody(configuration: Configuration) -> some View {
//        PrimitiveButtonWrapper {
//            configuration.trigger()
//        } content: { _ in
//            HStack {
//                Spacer(minLength: 0)
//                configuration.label
//                Spacer(minLength: 0)
//            }
//            .border(.red)
//        }
//    }
//}

struct BlockButtonStyle: ButtonStyle {
//    var config: Config
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer(minLength: 0)
            configuration.label
            Spacer(minLength: 0)
        }
        .border(.red)
    }
}

//extension BlockButtonStyle

#if DEBUG
#Preview {
    VStack {
        Button {
            
        } label: {
            Text("123")
        }
        
        .buttonStyle(.borderedProminent)
        .buttonStyle(BlockButtonStyle())
    }
    .frame(width: 200)
    .padding()
}
#endif
