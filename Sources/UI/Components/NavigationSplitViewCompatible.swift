//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/2/28.
//

import SwiftUI
import SwiftUIIntrospect

public enum NavigationSplitViewVisibilityCompatible {
    case automatic
    case all
    case doubleColumn
    case detailOnly
    
    @available(macOS 13.0, iOS 16.0, *)
    var value: NavigationSplitViewVisibility {
        switch self {
            case .all:
                return .all
            case .automatic:
                return .automatic
            case .detailOnly:
                return .detailOnly
            case .doubleColumn:
                return .doubleColumn
        }
    }
    
    @available(macOS 13.0, iOS 16.0, *)
    init(_ from: NavigationSplitViewVisibility) {
        switch from {
            case .all:
                self = .all
            case .automatic:
                self = .automatic
            case .detailOnly:
                self = .detailOnly
            case .doubleColumn:
                self = .doubleColumn
            default:
                self = .all
        }
    }
}

public struct NavigationSplitViewCompatible<Sidebar: View, Detail: View>: View {
    var columnVisibility: Binding<NavigationSplitViewVisibilityCompatible>?

    var sidebar: () -> Sidebar
    var detail: () -> Detail
    
    
    @State private var showMask = true
    
    public init(columnVisibility: Binding<NavigationSplitViewVisibilityCompatible>? = nil,
                @ViewBuilder sidebar: @escaping () -> Sidebar,
                @ViewBuilder detail: @escaping () -> Detail) {
        self.columnVisibility = columnVisibility
        self.sidebar = sidebar
        self.detail = detail
    }
    
    public var body: some View {
        if #available(macOS 13.0, iOS 16.0, *) {
            if let columnVisibility = columnVisibility {
                NavigationSplitView(columnVisibility: Binding(get: {
                    columnVisibility.wrappedValue.value
                }, set: { val in
                    columnVisibility.wrappedValue = .init(val)
                })) {
                    sidebar()
                } detail: {
                    detail()
                }
            } else {
                NavigationSplitView {
                    sidebar()
                } detail: {
                    detail()
                }
            }
        } else {
            ZStack {
                SplitView(columnVisibility: columnVisibility) {
                    sidebar()
                } detail: {
                    detail()
                }
                
                // give time to set divider position
                if showMask {
                    Rectangle()
                    #if os(macOS)
                        .foregroundColor(.init(nsColor: .windowBackgroundColor))
                    #elseif os(iOS)
                        .foregroundColor(.init(uiColor: .systemBackground))
                    #endif
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        withAnimation {
                            switch columnVisibility?.wrappedValue {
                                case .all:
                                    columnVisibility?.wrappedValue = .detailOnly
                                case .detailOnly:
                                    columnVisibility?.wrappedValue = .all
                                default:
                                    columnVisibility?.wrappedValue = .all
                            }
                        }
                    } label: {
                        Image(systemName: "sidebar.leading")
                    }
                    .help("Toggle sidebar")
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                    withAnimation {
                        showMask = false
                    }
                }
            }
        }
    }
}

extension NavigationSplitViewCompatible {
    #if os(macOS)
    @ViewBuilder public func removeSidebarToggle() -> some View {
        introspect(.navigationSplitView, on: .macOS(.v13)) { splitView in
            let toolbar = splitView.window?.toolbar
            let toolbarItems = toolbar?.items
//            let identifiers = toolbarItems?.map { $0.itemIdentifier }
//            print(identifiers)
            // "com.apple.SwiftUI.navigationSplitView.toggleSidebar"
            if let index = toolbarItems?.firstIndex(where: { $0.itemIdentifier.rawValue == "com.apple.SwiftUI.navigationSplitView.toggleSidebar" }) {
                toolbar?.removeItem(at: index)
            }
        }
    }
    #endif
}

#if os(macOS)
struct SplitView<Sidebar: View, Detail: View>: NSViewRepresentable {
    var columnVisibility: Binding<NavigationSplitViewVisibilityCompatible>?
    var sidebar: () -> Sidebar
    var detail: () -> Detail
    
    @State private var lastColumnVisibilty: NavigationSplitViewVisibilityCompatible = .all
    
    func makeNSView(context: Context) -> NSSplitView {
        let splitView = context.coordinator.splitView
        splitView.delegate = context.coordinator
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.addArrangedSubview(context.coordinator.sidebarView)
        splitView.addArrangedSubview(context.coordinator.detailView)
        
        DispatchQueue.main.async {
            splitView.setPosition(150, ofDividerAt: 0)
            lastColumnVisibilty = columnVisibility?.wrappedValue ?? .all
        }
        
        
        return splitView
    }
    
    func updateNSView(_ splitView: NSSplitView, context: Context) {
        context.coordinator.sidebarView.rootView = sidebar()
        context.coordinator.detailView.rootView = detail()
        
        if let columnVisibility = columnVisibility,
           lastColumnVisibilty != columnVisibility.wrappedValue {
            if columnVisibility.wrappedValue == .detailOnly {
                context.coordinator.sidebarView.animator().isHidden = true
                splitView.animator().adjustSubviews()
            } else if context.coordinator.sidebarView.isHidden {
                context.coordinator.sidebarView.animator().isHidden = false
                splitView.animator().animator().setPosition(150, ofDividerAt: 0)
            }
            DispatchQueue.main.async {
                lastColumnVisibilty = columnVisibility.wrappedValue
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(sidebarView: NSHostingView(rootView: sidebar()),
                    detailView: NSHostingView(rootView: detail()))
    }
}

extension SplitView {
    class Coordinator: NSObject, NSSplitViewDelegate {
        let splitView = NSSplitView()
        
        var sidebarView: NSHostingView<Sidebar>
        var detailView: NSHostingView<Detail>
        
        init(sidebarView: NSHostingView<Sidebar>, detailView: NSHostingView<Detail>) {
            self.sidebarView = sidebarView
            self.detailView = detailView
        }
        
        func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            return 140
        }
        func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
            return 300
        }
//        func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
//            false
//        }
    }
}

#elseif os(iOS)
struct SplitView<Sidebar: View, Detail: View>: UIViewRepresentable {
    var columnVisibility: Binding<NavigationSplitViewVisibilityCompatible>?
    var sidebar: () -> Sidebar
    var detail: () -> Detail
    
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

#endif

//struct NavigationSplitViewCompatible_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationSplitViewCompatible()
//    }
//}
