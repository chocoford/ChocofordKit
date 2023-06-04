//
//  ContentView.swift
//  ChocofordKitExamples
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI
import SDWebImage

struct ContentView: View {
    
    enum Route: Hashable {
        case imageViewr
    }
    
    @State private var route: Route?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $route) {
                NavigationLink("Image Viewer", value: Route.imageViewr)
            }
        } detail: {
            switch route {
                case .imageViewr:
                    ImageViewerExample()
                case .none:
                    Text("Select a case.")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
