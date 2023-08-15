//
//  File.swift
//  
//
//  Created by Dove Zachary on 2023/6/24.
//

import SwiftUI
import ChocofordEssentials
import AVKit
import Introspect
import SDWebImageSwiftUI
import SFSafeSymbols

public struct MacTipsPageViewItem: Hashable {
    public var image: String?
    public var video: URL?
    public var title: String
    public var body: String
    
    public init(image: String, title: String, body: String) {
        self.image = image
        self.video = nil
        self.title = title
        self.body = body
    }
    
    public init(video: URL, title: String, body: String) {
        self.image = nil
        self.video = video
        self.title = title
        self.body = body
    }
}

public struct MacTipsPageViewContent: View {
    var proxy: PageViewProxy
    var index: Int
    var item: MacTipsPageViewItem
    var geometry: GeometryProxy
    
    @State var player = AVPlayer()

    public var body: some View {
        if index == 0 {
            homepage()
        } else {
            VStack(spacing: 20) {
                mediaContent()
#if os(macOS)
                    .frame(width: geometry.size.width, height: geometry.size.height * 3 / 4)
#elseif os(iOS)
                    .frame(width: geometry.size.width,
                           height: UIDevice.current.userInterfaceIdiom == .phone ? geometry.size.height * 2 / 3 : geometry.size.height / 3)
#endif
             
                    .clipped()
                
                HStack {
                    Spacer(minLength: 0)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(item.body)
                            .font(.system(size: 16))
                        Spacer(minLength: 0)
                    }
#if os(macOS)
                    .frame(width: 600)
#elseif os(iOS)
                    .padding(.horizontal, 40)
                    .foregroundColor(.white)
#endif
                    
                    Spacer(minLength: 0)
                }
            }

        }
    }
    
    @ViewBuilder
    func homepage() -> some View {
        ZStack(alignment: .top) {
#if os(macOS)
            mediaContent()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
#elseif os(iOS)
            mediaContent()
                .padding()
                .offset(x: 0, y: geometry.size.height / 3)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(.black)
#endif
            VStack {
                Text(item.title)
                    .font(.system(size: 18, weight: .bold))
                Text(item.body)
                    .font(.system(size: 30, weight: .bold))
            }
            .foregroundColor(.white)
#if os(macOS)
            .padding(.top, 80)
#elseif os(iOS)
            .padding(.top, 30)
#endif

        }
    }
    
    @ViewBuilder
    func mediaContent() -> some View {
        if let image = item.image {
            if image.hasPrefix("http"), let url = URL(string: image) {
                WebImage(url: url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        } else if let url = item.video {
            VideoPlayer(player: player)
                .onAppear {
                    player.replaceCurrentItem(with: .init(url: url))
                }
                .onChange(of: proxy.currentPage) { page in
                    if  page == index {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            player.play()
                        })
                    } else {
                        DispatchQueue.main.async {
                            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                            player.pause()
                        }
                    }
                }
        }
    }
}

public struct MacTipsPageViewControlller: View {
    var items: [MacTipsPageViewItem]
    var proxy: PageViewProxy
    var geometry: GeometryProxy
    
    public var body: some View {
        VStack {
            Color.clear
                .frame(height: geometry.size.height / 4 * 3)
#if os(macOS)
            Spacer()
            HStack {
                proxy.prevPageButton {
                    pageToggle(.chevronLeft)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                proxy.nextPageButton {
                    pageToggle(.chevronRight)
                }
                .padding(.horizontal, 40)
            }
            .buttonStyle(.borderless)
#endif
            Spacer()
            Group {
#if os(macOS)
                Text("\(proxy.currentPage) of \(items.count - 1)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
#elseif os(iOS)
                HStack(spacing: 12) {
                    let items = items[0..<items.count-1]
                    ForEach(Array(items.enumerated()), id: \.offset) { i, _ in
                        Circle()
                            .foregroundColor(i == proxy.currentPage - 1 ? Color.primary : Color.secondary)
                            .frame(width: 8, height: 8)
                    }
                }
#endif
            }
            .opacity(proxy.currentPage > 0 ? 1 : 0)
        }
    }
    
    @ViewBuilder
    func pageToggle(_ symbol: SFSymbol) -> some View {
        Hover { isHover in
            Image(systemSymbol: symbol)
                .resizable()
                .frame(width: 8, height: 30)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(Color.textColor.opacity(0.9))
                .padding(.horizontal, 6)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHover ? .ultraThickMaterial : .ultraThinMaterial)
                }
        }
    }
}

extension HPageView where Pages == ForEach<[EnumeratedSequence<[MacTipsPageViewItem]>.Element], Int, MacTipsPageViewContent>, Overlay == MacTipsPageViewControlller {
    public static func macTipsPageView(items: [MacTipsPageViewItem]) -> HPageView {
        HPageView(items: Array(items.enumerated()), id: \.offset) { proxy, item, geometry in
            MacTipsPageViewContent(proxy: proxy, index: item.offset, item: item.element, geometry: geometry)
        }
        .overlay { proxy, geometry in
            MacTipsPageViewControlller(items: items, proxy: proxy, geometry: geometry)
        }
    }
}

#if DEBUG
struct MacTipsPageView_Previews: PreviewProvider {
    static var previews: some View {
        let items: [MacTipsPageViewItem] = [
            .init(image: "AppOverview", title: "Schedule when to send an email", body: "Click ￼ next to the Send button, then choose a time — or choose Send Later to pick the date and time."),
            .init(image: "AppOverview", title: "Schedule when to send an email2 ", body: "Click ￼ next to the Send button, then choose a time — or choose Send Later to pick the date and time.2"),
            .init(image: "AppOverview", title: "Schedule when to send an email3 ", body: "Click ￼ next to the Send button, then choose a time — or choose Send Later to pick the date and time.3")
        ]
        HPageView.macTipsPageView(items: items)
    }
}
#endif
