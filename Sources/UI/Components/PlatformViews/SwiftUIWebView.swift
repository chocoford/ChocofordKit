//
//  SwiftUIWebView.swift
//  
//
//  Created by Chocoford on 2023/4/28.
//

import SwiftUI
import WebKit

#if os(macOS)
public struct SwiftUIWebView: NSViewRepresentable {
    var url: URL?
    
    @ObservedObject var config = Config()
    
    public init(url: URL?) {
        self.url = url
    }
    
    public func makeNSView(context: Context) -> WKWebView {
        context.coordinator.webView
    }
    
    public func updateNSView(_ webView: WKWebView, context: Context) {
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(config: config)
    }
}
#elseif os(iOS)
public struct SwiftUIWebView: UIViewRepresentable {
    var url: URL?
    @ObservedObject var config = Config()

    public init(url: URL?) {
        self.url = url
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        context.coordinator.webView
    }
    
    public func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(config: config)
    }
}
#endif

public extension SwiftUIWebView {
    final class Coordinator: NSObject, WKNavigationDelegate {
        let webView: WKWebView
        @ObservedObject var config: Config
        
        init(config: Config) {
            self.webView = WKWebView()
            self.config = config
            super.init()
            
            webView.navigationDelegate = self
        }
        
        // MARK: - WKNavigationDelegate
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let script = config.onMountedScript {
                webView.evaluateJavaScript(script)
            }
        }
        
    }
    
    func executeScriptOnMounted(_ script: String) -> SwiftUIWebView {
        self.config.onMountedScript = script
        return self
    }
}

extension SwiftUIWebView {
    final class Config: ObservableObject {
        var onMountedScript: String?
    }
}

#if DEBUG
struct SwiftUIWebView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIWebView(url: nil)
    }
}
#endif
