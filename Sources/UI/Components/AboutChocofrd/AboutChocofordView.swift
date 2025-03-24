//
//  AboutChocofordView.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/9/8.
//

import SwiftUI

import SwiftyAlert


public struct AboutChocofordView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var isAppStore: Bool
//    var privacyPolicy: URL?
//    var termsOfUse: URL?
    
    public init(
        isAppStore: Bool//,
//        privacyPolicy: URL?,
//        termsOfUse: URL? = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    ) {
        self.isAppStore = isAppStore
//        self.privacyPolicy = privacyPolicy
//        self.termsOfUse = termsOfUse
    }
    
    @State private var isSupportSheetPresented = false
    
    public var body: some View {
        VStack {
            if #available(iOS 16.0, macOS 13.0, *) {
                ViewThatFits(in: .horizontal) {
                    regularProfile()
                    compactProfile()
                }
            } else if horizontalSizeClass == .compact {
                compactProfile()
            } else {
                regularProfile()
            }

            Divider()

            Section {
                if #available(macOS 13.0, iOS 16.0, *) {
                    FlexStack {
                        myApps()
                    }
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 80, maximum: 80)),
                        ]
                    ) {
                        myApps()
                    }
                }
            } header: {
                HStack {
                    Text("My Apps")
                    Spacer()
                }
                .font(.headline)
                .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isSupportSheetPresented) {
            SupportChocofordView(
                isAppStore: isAppStore
            )
            .contentPadding(40)
            .frame(width: horizontalSizeClass == .compact ? nil : 560)
            .swiftyAlert()
        }
    }
    
    private func avatar() -> Image? {
//        Image("selfie")
#if canImport(AppKit)
        if let nsImage = NSImage(contentsOfFile: Bundle.module.path(forResource: "selfie", ofType: "JPG")!) {
            return Image(nsImage: nsImage)
        }
#elseif canImport(UIKit)
        if let uiImage = UIImage(contentsOfFile: Bundle.module.path(forResource: "selfie", ofType: "JPG")!) {
            return Image(uiImage: uiImage)
        }
#endif
        return nil
    }
    
    @MainActor @ViewBuilder
    private func myLinks() -> some View {
        // twitter
        fastLinkChip(url: URL(string: "https://x.com/Chocoford_")!) {
            HStack(spacing: 4) {
                TwitterLogo()
                    .scaledToFit()
                    .frame(height: 12)
                Text("Chocoford")
                    .font(.footnote)
            }
        }
        fastLinkChip(url: URL(string: "https://github.com/chocoford")!) {
            HStack(spacing: 4) {
                GithubLogo()
                    .scaledToFit()
                    .frame(height: 12)
                Text("Chocoford")
                    .font(.footnote)
            }
        }
        fastLinkChip(url: URL(string: "https://discord.gg/VMJBD6rFA7")!) {
            HStack(spacing: 4) {
                ZStack {
                    DiscordLogo()
                        .scaledToFit()
                        .frame(height: 14)
                }
                .frame(height: 12)
                Text("Chocoford's Server")
                    .font(.footnote)
            }
        }
    }
    
    @MainActor @ViewBuilder
    private func regularProfile() -> some View {
        let height: CGFloat = 80

        HStack(spacing: 20) {
            if let image = avatar() {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: height - 10, height: height - 10)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading) {
                Text("Chocoford")
                    .font(.largeTitle)
                Spacer()
                HStack {
                    myLinks()
                }
            }
            
            Spacer()
            Button {
                isSupportSheetPresented.toggle()
            } label: {
                Text("Support Me")
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .containerShape(Capsule())
        }
        .padding(.vertical, 10)
        .frame(height: height)
    }
    
    @MainActor @ViewBuilder
    private func compactProfile() -> some View {
        let height: CGFloat = 80

        VStack(spacing: 10) {
            HStack(spacing: 20) {
                if let image = avatar() {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: height - 10, height: height - 10)
                        .clipShape(Circle())
                }
                VStack(alignment: .leading) {
                    Text("Chocoford")
                        .font(.title)
                    if #available(macOS 13.0, iOS 16.0, *) {
                        FlexStack {
                            myLinks()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                // twitter
                                fastLinkChip(url: URL(string: "https://x.com/Chocoford_")!) {
                                    HStack(spacing: 4) {
                                        TwitterLogo()
                                            .scaledToFit()
                                            .frame(height: 12)
                                        Text("Chocoford")
                                            .font(.footnote)
                                    }
                                }
                                fastLinkChip(url: URL(string: "https://github.com/chocoford")!) {
                                    HStack(spacing: 4) {
                                        GithubLogo()
                                            .scaledToFit()
                                            .frame(height: 12)
                                        Text("Chocoford")
                                            .font(.footnote)
                                    }
                                }
                            }
                            fastLinkChip(url: URL(string: "https://discord.gg/VMJBD6rFA7")!) {
                                HStack(spacing: 4) {
                                    ZStack {
                                        DiscordLogo()
                                            .scaledToFit()
                                            .frame(height: 14)
                                    }
                                    .frame(height: 12)
                                    Text("Chocoford's Server")
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                isSupportSheetPresented.toggle()
            } label: {
                Text("Support Me")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.regular)
            .buttonStyle(.borderedProminent)
            .containerShape(Capsule())
        }
        .padding(.vertical, 10)
    }
    
    @MainActor @ViewBuilder
    private func myApps() -> some View {
        Link(destination: URL(string: "https://excalidrawz.chocoford.com")!) {
            Image("ExcalidrawZ")
                .resizable()
                .scaledToFit()
                .frame(height: 64)
        }
        .buttonStyle(.borderless)
    }
    
    @MainActor @ViewBuilder
    private func fastLinkChip<Content: View>(
        url: URL,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        Link(destination: url) {
            content()
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule()
                        .fill(.background)
                }
            
        }
    }
}

//@available(iOS 16.0, macOS 13.0, visionOS 1.0, tvOS 16.0, watchOS 9.0, *)


fileprivate struct TwitterLogo: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.879*width, y: 0.86667*height))
        path.addLine(to: CGPoint(x: 0.58583*width, y: 0.43927*height))
        path.addLine(to: CGPoint(x: 0.58633*width, y: 0.43967*height))
        path.addLine(to: CGPoint(x: 0.85067*width, y: 0.13333*height))
        path.addLine(to: CGPoint(x: 0.76233*width, y: 0.13333*height))
        path.addLine(to: CGPoint(x: 0.547*width, y: 0.38267*height))
        path.addLine(to: CGPoint(x: 0.376*width, y: 0.13333*height))
        path.addLine(to: CGPoint(x: 0.14433*width, y: 0.13333*height))
        path.addLine(to: CGPoint(x: 0.41803*width, y: 0.53237*height))
        path.addLine(to: CGPoint(x: 0.418*width, y: 0.53233*height))
        path.addLine(to: CGPoint(x: 0.12933*width, y: 0.86667*height))
        path.addLine(to: CGPoint(x: 0.21767*width, y: 0.86667*height))
        path.addLine(to: CGPoint(x: 0.45707*width, y: 0.58927*height))
        path.addLine(to: CGPoint(x: 0.64733*width, y: 0.86667*height))
        path.addLine(to: CGPoint(x: 0.879*width, y: 0.86667*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.341*width, y: 0.2*height))
        path.addLine(to: CGPoint(x: 0.75233*width, y: 0.8*height))
        path.addLine(to: CGPoint(x: 0.68233*width, y: 0.8*height))
        path.addLine(to: CGPoint(x: 0.27067*width, y: 0.2*height))
        path.addLine(to: CGPoint(x: 0.341*width, y: 0.2*height))
        path.closeSubpath()
        return path
    }
}

fileprivate struct GithubLogo: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.49851*width, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: 0.51268*height), control1: CGPoint(x: 0.22285*width, y: 0), control2: CGPoint(x: 0, y: 0.22917*height))
        path.addCurve(to: CGPoint(x: 0.34087*width, y: 0.99903*height), control1: CGPoint(x: 0, y: 0.7393*height), control2: CGPoint(x: 0.14279*width, y: 0.93114*height))
        path.addCurve(to: CGPoint(x: 0.3747*width, y: 0.97443*height), control1: CGPoint(x: 0.36563*width, y: 1.00414*height), control2: CGPoint(x: 0.3747*width, y: 0.988*height))
        path.addCurve(to: CGPoint(x: 0.37389*width, y: 0.87935*height), control1: CGPoint(x: 0.3747*width, y: 0.96254*height), control2: CGPoint(x: 0.37389*width, y: 0.9218*height))
        path.addCurve(to: CGPoint(x: 0.20634*width, y: 0.81824*height), control1: CGPoint(x: 0.23521*width, y: 0.90992*height), control2: CGPoint(x: 0.20634*width, y: 0.81824*height))
        path.addCurve(to: CGPoint(x: 0.15103*width, y: 0.74355*height), control1: CGPoint(x: 0.18405*width, y: 0.75882*height), control2: CGPoint(x: 0.15103*width, y: 0.74355*height))
        path.addCurve(to: CGPoint(x: 0.15434*width, y: 0.71215*height), control1: CGPoint(x: 0.10564*width, y: 0.71215*height), control2: CGPoint(x: 0.15434*width, y: 0.71215*height))
        path.addCurve(to: CGPoint(x: 0.2311*width, y: 0.76477*height), control1: CGPoint(x: 0.20468*width, y: 0.71554*height), control2: CGPoint(x: 0.2311*width, y: 0.76477*height))
        path.addCurve(to: CGPoint(x: 0.37636*width, y: 0.80721*height), control1: CGPoint(x: 0.27566*width, y: 0.84285*height), control2: CGPoint(x: 0.34747*width, y: 0.82079*height))
        path.addCurve(to: CGPoint(x: 0.40772*width, y: 0.73846*height), control1: CGPoint(x: 0.38048*width, y: 0.7741*height), control2: CGPoint(x: 0.39369*width, y: 0.75119*height))
        path.addCurve(to: CGPoint(x: 0.18076*width, y: 0.48551*height), control1: CGPoint(x: 0.29712*width, y: 0.72657*height), control2: CGPoint(x: 0.18076*width, y: 0.68244*height))
        path.addCurve(to: CGPoint(x: 0.23192*width, y: 0.34801*height), control1: CGPoint(x: 0.18076*width, y: 0.42949*height), control2: CGPoint(x: 0.20055*width, y: 0.38366*height))
        path.addCurve(to: CGPoint(x: 0.23688*width, y: 0.2122*height), control1: CGPoint(x: 0.22697*width, y: 0.33528*height), control2: CGPoint(x: 0.20963*width, y: 0.28265*height))
        path.addCurve(to: CGPoint(x: 0.37388*width, y: 0.26482*height), control1: CGPoint(x: 0.23688*width, y: 0.2122*height), control2: CGPoint(x: 0.27897*width, y: 0.19861*height))
        path.addCurve(to: CGPoint(x: 0.62313*width, y: 0.26482*height), control1: CGPoint(x: 0.5406*width, y: 0.24784*height), control2: CGPoint(x: 0.58351*width, y: 0.25379*height))
        path.addCurve(to: CGPoint(x: 0.76014*width, y: 0.2122*height), control1: CGPoint(x: 0.71805*width, y: 0.19861*height), control2: CGPoint(x: 0.76014*width, y: 0.2122*height))
        path.addCurve(to: CGPoint(x: 0.76509*width, y: 0.34801*height), control1: CGPoint(x: 0.78739*width, y: 0.28265*height), control2: CGPoint(x: 0.77004*width, y: 0.33528*height))
        path.addCurve(to: CGPoint(x: 0.81627*width, y: 0.48551*height), control1: CGPoint(x: 0.79729*width, y: 0.38366*height), control2: CGPoint(x: 0.81627*width, y: 0.42949*height))
        path.addCurve(to: CGPoint(x: 0.58847*width, y: 0.73846*height), control1: CGPoint(x: 0.81627*width, y: 0.68244*height), control2: CGPoint(x: 0.6999*width, y: 0.72572*height))
        path.addCurve(to: CGPoint(x: 0.62231*width, y: 0.83352*height), control1: CGPoint(x: 0.60663*width, y: 0.75458*height), control2: CGPoint(x: 0.62231*width, y: 0.78514*height))
        path.addCurve(to: CGPoint(x: 0.62149*width, y: 0.97442*height), control1: CGPoint(x: 0.62231*width, y: 0.90227*height), control2: CGPoint(x: 0.62149*width, y: 0.95745*height))
        path.addCurve(to: CGPoint(x: 0.65533*width, y: 0.99904*height), control1: CGPoint(x: 0.62149*width, y: 0.988*height), control2: CGPoint(x: 0.63057*width, y: 1.00414*height))
        path.addCurve(to: CGPoint(x: 0.99619*width, y: 0.51268*height), control1: CGPoint(x: 0.85341*width, y: 0.93113*height), control2: CGPoint(x: 0.99619*width, y: 0.7393*height))
        path.addCurve(to: CGPoint(x: 0.49851*width, y: 0), control1: CGPoint(x: 0.99701*width, y: 0.22917*height), control2: CGPoint(x: 0.77335*width, y: 0))
        path.closeSubpath()
        return path
    }
}

fileprivate struct DiscordLogo: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.84654*width, y: 0.18921*height))
        path.addCurve(to: CGPoint(x: 0.643*width, y: 0.12505*height), control1: CGPoint(x: 0.7828*width, y: 0.15949*height), control2: CGPoint(x: 0.71446*width, y: 0.13759*height))
        path.addCurve(to: CGPoint(x: 0.63972*width, y: 0.12663*height), control1: CGPoint(x: 0.6417*width, y: 0.12481*height), control2: CGPoint(x: 0.6404*width, y: 0.12542*height))
        path.addCurve(to: CGPoint(x: 0.61438*width, y: 0.17953*height), control1: CGPoint(x: 0.63093*width, y: 0.14251*height), control2: CGPoint(x: 0.6212*width, y: 0.16324*height))
        path.addCurve(to: CGPoint(x: 0.38576*width, y: 0.17953*height), control1: CGPoint(x: 0.53752*width, y: 0.16784*height), control2: CGPoint(x: 0.46105*width, y: 0.16784*height))
        path.addCurve(to: CGPoint(x: 0.36002*width, y: 0.12663*height), control1: CGPoint(x: 0.37894*width, y: 0.16288*height), control2: CGPoint(x: 0.36885*width, y: 0.14251*height))
        path.addCurve(to: CGPoint(x: 0.35675*width, y: 0.12505*height), control1: CGPoint(x: 0.35935*width, y: 0.12546*height), control2: CGPoint(x: 0.35805*width, y: 0.12485*height))
        path.addCurve(to: CGPoint(x: 0.15321*width, y: 0.18921*height), control1: CGPoint(x: 0.28533*width, y: 0.13755*height), control2: CGPoint(x: 0.21698*width, y: 0.15945*height))
        path.addCurve(to: CGPoint(x: 0.15187*width, y: 0.19038*height), control1: CGPoint(x: 0.15265*width, y: 0.18945*height), control2: CGPoint(x: 0.15218*width, y: 0.18985*height))
        path.addCurve(to: CGPoint(x: 0.00413*width, y: 0.76879*height), control1: CGPoint(x: 0.02222*width, y: 0.3872*height), control2: CGPoint(x: -0.01329*width, y: 0.57919*height))
        path.addCurve(to: CGPoint(x: 0.00543*width, y: 0.77117*height), control1: CGPoint(x: 0.00421*width, y: 0.76972*height), control2: CGPoint(x: 0.00472*width, y: 0.77061*height))
        path.addCurve(to: CGPoint(x: 0.25514*width, y: 0.89944*height), control1: CGPoint(x: 0.09097*width, y: 0.835*height), control2: CGPoint(x: 0.17382*width, y: 0.87375*height))
        path.addCurve(to: CGPoint(x: 0.25865*width, y: 0.89827*height), control1: CGPoint(x: 0.25644*width, y: 0.89985*height), control2: CGPoint(x: 0.25782*width, y: 0.89936*height))
        path.addCurve(to: CGPoint(x: 0.30973*width, y: 0.81383*height), control1: CGPoint(x: 0.27788*width, y: 0.87158*height), control2: CGPoint(x: 0.29503*width, y: 0.84343*height))
        path.addCurve(to: CGPoint(x: 0.30799*width, y: 0.80936*height), control1: CGPoint(x: 0.3106*width, y: 0.8121*height), control2: CGPoint(x: 0.30977*width, y: 0.81004*height))
        path.addCurve(to: CGPoint(x: 0.22999*width, y: 0.77158*height), control1: CGPoint(x: 0.2808*width, y: 0.79887*height), control2: CGPoint(x: 0.2549*width, y: 0.78609*height))
        path.addCurve(to: CGPoint(x: 0.22967*width, y: 0.76617*height), control1: CGPoint(x: 0.22802*width, y: 0.7704*height), control2: CGPoint(x: 0.22786*width, y: 0.76754*height))
        path.addCurve(to: CGPoint(x: 0.24516*width, y: 0.75383*height), control1: CGPoint(x: 0.23492*width, y: 0.76218*height), control2: CGPoint(x: 0.24016*width, y: 0.75802*height))
        path.addCurve(to: CGPoint(x: 0.2484*width, y: 0.75339*height), control1: CGPoint(x: 0.24607*width, y: 0.75307*height), control2: CGPoint(x: 0.24733*width, y: 0.7529*height))
        path.addCurve(to: CGPoint(x: 0.75096*width, y: 0.75339*height), control1: CGPoint(x: 0.41205*width, y: 0.82932*height), control2: CGPoint(x: 0.58923*width, y: 0.82932*height))
        path.addCurve(to: CGPoint(x: 0.75423*width, y: 0.75379*height), control1: CGPoint(x: 0.75202*width, y: 0.75286*height), control2: CGPoint(x: 0.75328*width, y: 0.75303*height))
        path.addCurve(to: CGPoint(x: 0.76976*width, y: 0.76617*height), control1: CGPoint(x: 0.75923*width, y: 0.75798*height), control2: CGPoint(x: 0.76448*width, y: 0.76218*height))
        path.addCurve(to: CGPoint(x: 0.76948*width, y: 0.77158*height), control1: CGPoint(x: 0.77157*width, y: 0.76754*height), control2: CGPoint(x: 0.77145*width, y: 0.7704*height))
        path.addCurve(to: CGPoint(x: 0.69144*width, y: 0.80932*height), control1: CGPoint(x: 0.74457*width, y: 0.78637*height), control2: CGPoint(x: 0.71868*width, y: 0.79887*height))
        path.addCurve(to: CGPoint(x: 0.68974*width, y: 0.81383*height), control1: CGPoint(x: 0.68967*width, y: 0.81*height), control2: CGPoint(x: 0.68888*width, y: 0.8121*height))
        path.addCurve(to: CGPoint(x: 0.74079*width, y: 0.89823*height), control1: CGPoint(x: 0.70476*width, y: 0.84339*height), control2: CGPoint(x: 0.72191*width, y: 0.87154*height))
        path.addCurve(to: CGPoint(x: 0.7443*width, y: 0.89944*height), control1: CGPoint(x: 0.74157*width, y: 0.89936*height), control2: CGPoint(x: 0.743*width, y: 0.89985*height))
        path.addCurve(to: CGPoint(x: 0.99439*width, y: 0.77117*height), control1: CGPoint(x: 0.826*width, y: 0.87375*height), control2: CGPoint(x: 0.90886*width, y: 0.835*height))
        path.addCurve(to: CGPoint(x: 0.9957*width, y: 0.76883*height), control1: CGPoint(x: 0.99514*width, y: 0.77061*height), control2: CGPoint(x: 0.99562*width, y: 0.76976*height))
        path.addCurve(to: CGPoint(x: 0.84784*width, y: 0.19042*height), control1: CGPoint(x: 1.01655*width, y: 0.54963*height), control2: CGPoint(x: 0.96077*width, y: 0.35922*height))
        path.addCurve(to: CGPoint(x: 0.84654*width, y: 0.18921*height), control1: CGPoint(x: 0.84757*width, y: 0.18985*height), control2: CGPoint(x: 0.8471*width, y: 0.18945*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.33417*width, y: 0.65334*height))
        path.addCurve(to: CGPoint(x: 0.2443*width, y: 0.55092*height), control1: CGPoint(x: 0.2849*width, y: 0.65334*height), control2: CGPoint(x: 0.2443*width, y: 0.60737*height))
        path.addCurve(to: CGPoint(x: 0.33417*width, y: 0.4485*height), control1: CGPoint(x: 0.2443*width, y: 0.49446*height), control2: CGPoint(x: 0.28411*width, y: 0.4485*height))
        path.addCurve(to: CGPoint(x: 0.42404*width, y: 0.55092*height), control1: CGPoint(x: 0.38462*width, y: 0.4485*height), control2: CGPoint(x: 0.42483*width, y: 0.49487*height))
        path.addCurve(to: CGPoint(x: 0.33417*width, y: 0.65334*height), control1: CGPoint(x: 0.42404*width, y: 0.60737*height), control2: CGPoint(x: 0.38423*width, y: 0.65334*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.66645*width, y: 0.65334*height))
        path.addCurve(to: CGPoint(x: 0.57658*width, y: 0.55092*height), control1: CGPoint(x: 0.61718*width, y: 0.65334*height), control2: CGPoint(x: 0.57658*width, y: 0.60737*height))
        path.addCurve(to: CGPoint(x: 0.66645*width, y: 0.4485*height), control1: CGPoint(x: 0.57658*width, y: 0.49446*height), control2: CGPoint(x: 0.61639*width, y: 0.4485*height))
        path.addCurve(to: CGPoint(x: 0.75632*width, y: 0.55092*height), control1: CGPoint(x: 0.7169*width, y: 0.4485*height), control2: CGPoint(x: 0.7571*width, y: 0.49487*height))
        path.addCurve(to: CGPoint(x: 0.66645*width, y: 0.65334*height), control1: CGPoint(x: 0.75632*width, y: 0.60737*height), control2: CGPoint(x: 0.7169*width, y: 0.65334*height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    if #available(macOS 13.0, iOS 16.0, *) {
        Form {
            AboutChocofordView(
                isAppStore: true//,
//                privacyPolicy: URL(string: "https://excalidrawz.chocoford.com/privacy/")
            )
                .padding()
        }
        .formStyle(.grouped)
    }
}


#Preview {
    DiscordLogo()
}
