//
//  SwiftUIView.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/9/8.
//

//import SwiftUI
//
//public struct AboutChocofordView: View {
//    public init() {}
//    
//    public var body: some View {
//        VStack {
//            let height: CGFloat = 80
//            HStack(spacing: 20) {
//                if let image = avatar() {
//                    image
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: height - 10, height: height - 10)
//                        .clipShape(Circle())
//                }
//                
//                VStack {
//                    Text("Chocoford")
//                        .font(.largeTitle)
//                    Spacer()
//                    HStack {
//                        myLinks()
//                    }
//                }
//                
//                Spacer()
//                
//                Button {
//                    
//                } label: {
//                    Text("Buy me a coffee")
//                }
//                .controlSize(.large)
//                .buttonStyle(.borderedProminent)
//                .containerShape(Capsule())
//            }
//            .padding(.vertical, 10)
//            .frame(height: height)
//            
//            Divider()
//            
//            if #available(macOS 13.0, *) {
//                FlexStack {
//                    
//                }
//            } else {
//                
//            }
//        }
//        
//    }
//    
//    private func avatar() -> Image? {
//#if canImport(AppKit)
//        if let nsImage = NSImage(contentsOfFile: Bundle.module.path(forResource: "selfie", ofType: "JPG")!) {
//            return Image(nsImage: nsImage)
//        }
//#elseif canImport(UIKit)
//        if let uiImage = UIImage(contentsOfFile: Bundle.module.path(forResource: "selfie", ofType: "JPG")) {
//            return Image(uiImage: uiImage)
//        }
//#endif
//        return nil
//    }
//    
//    @MainActor @ViewBuilder
//    private func myLinks() -> some View {
//        // twitter
//        fastLinkChip {
//            HStack {
//                TwitterLogo()
//                    .scaledToFit()
//                    .frame(height: 12)
//                Text("Chocoford")
//            }
//        }
//    }
//    
//    @MainActor @ViewBuilder
//    private func myApps() -> some View {
//        
//    }
//    
//    
////    @MainActor @ViewBuilder
////    private func twitterLogo() -> some View {
//    
//    @MainActor @ViewBuilder
//    private func fastLinkChip<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
//        content()
//            .padding(.horizontal, 4)
//            .padding(.vertical, 2)
//            .background {
//                Capsule()
////                    .shadow(radius: 2)
//            }
//    }
//}
//
//fileprivate struct TwitterLogo: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let width = rect.size.width
//        let height = rect.size.height
//        path.move(to: CGPoint(x: 0.879*width, y: 0.86667*height))
//        path.addLine(to: CGPoint(x: 0.58583*width, y: 0.43927*height))
//        path.addLine(to: CGPoint(x: 0.58633*width, y: 0.43967*height))
//        path.addLine(to: CGPoint(x: 0.85067*width, y: 0.13333*height))
//        path.addLine(to: CGPoint(x: 0.76233*width, y: 0.13333*height))
//        path.addLine(to: CGPoint(x: 0.547*width, y: 0.38267*height))
//        path.addLine(to: CGPoint(x: 0.376*width, y: 0.13333*height))
//        path.addLine(to: CGPoint(x: 0.14433*width, y: 0.13333*height))
//        path.addLine(to: CGPoint(x: 0.41803*width, y: 0.53237*height))
//        path.addLine(to: CGPoint(x: 0.418*width, y: 0.53233*height))
//        path.addLine(to: CGPoint(x: 0.12933*width, y: 0.86667*height))
//        path.addLine(to: CGPoint(x: 0.21767*width, y: 0.86667*height))
//        path.addLine(to: CGPoint(x: 0.45707*width, y: 0.58927*height))
//        path.addLine(to: CGPoint(x: 0.64733*width, y: 0.86667*height))
//        path.addLine(to: CGPoint(x: 0.879*width, y: 0.86667*height))
//        path.closeSubpath()
//        path.move(to: CGPoint(x: 0.341*width, y: 0.2*height))
//        path.addLine(to: CGPoint(x: 0.75233*width, y: 0.8*height))
//        path.addLine(to: CGPoint(x: 0.68233*width, y: 0.8*height))
//        path.addLine(to: CGPoint(x: 0.27067*width, y: 0.2*height))
//        path.addLine(to: CGPoint(x: 0.341*width, y: 0.2*height))
//        path.closeSubpath()
//        return path
//    }
//}
//    
//
//#Preview {
//    AboutChocofordView()
//        .padding()
//}
