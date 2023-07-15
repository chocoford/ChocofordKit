//
//  ImageViewer.swift
//  ChocofordKitExamples
//
//  Created by Dove Zachary on 2023/6/4.
//

import SwiftUI
import ChocofordUI

struct ImageViewerExample: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var images: [URL?] {
        var results: [URL?] = []
        for i in 1..<30 {
            results.append(URL(string: "https://picsum.photos/id/\(i)/200/300"))
        }
        return results
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(images, id: \.self) { url in
                    ImageViewer(url: url) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                    
                                case .empty:
                                    Rectangle()
                                        .frame(maxWidth: 200)
                                        .frame(height: 200)
                                        .shimmering()
                                    
                                case .failure(let error):
                                    Text(error.localizedDescription)
                                        .foregroundStyle(.red)
                                @unknown default:
                                    Text("unknown error")
                                        .foregroundStyle(.red)
                            }
                        }
                        .frame(maxWidth: 200)
                    }
                }
            }
        }
    }
}


#if DEBUG
struct ImageViewerExample_Previews: PreviewProvider {
    static var previews: some View {
        ImageViewerExample()
            .frame(width: 500, height: 500)
    }
}
#endif
