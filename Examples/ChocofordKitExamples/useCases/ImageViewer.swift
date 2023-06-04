//
//  ImageViewer.swift
//  ChocofordKitExamples
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI
import ChocofordUI
import SDWebImageSwiftUI
import SDWebImage

struct ImageViewerExample: View {
    var body: some View {
        ImageViewer(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large")) {
            Center {
                WebImage(url: URL(string: "https://pbs.twimg.com/media/Fxl_6mmagAA4ahV?format=jpg&name=large"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
            }
            .background(Color.red)
        }
    }
}


#if DEBUG
struct ImageViewerExample_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerExample()
    }
}
#endif
