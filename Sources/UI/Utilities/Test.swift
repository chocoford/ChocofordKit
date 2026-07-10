//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/24.
//

#if DEBUG
import SwiftUI

struct TheView<Content: View>: View {
    var content: (_ proxy: Proxy) -> PageContainer<Content>
    
    @StateObject private var proxy: Proxy = .init()
    
    init(@PageViewBuilder content: @escaping (_ proxy: Proxy) -> PageContainer<Content>) {
        self.content = content
    }
    
    var body: some View {
        content(proxy)
    }
}

public final class Proxy: ObservableObject {
    @Published public var count: Int = 0
    
    @ViewBuilder
    func addCountButton() -> some View {
        Button("add") {
            self.count += 1
        }
    }
}

struct TestContentView: View {
    var body: some View {
        VStack {
            TheView { proxy in
                Text("Hello \(proxy.count)")
                proxy.addCountButton()
            }
        }
        .frame(width: 100)
        .padding(40)
    }
}


struct Test_Previews: PreviewProvider {
    static var previews: some View {
        TestContentView()
            .previewLayout(.fixed(width: 500, height: 500))
    }
}
#endif
