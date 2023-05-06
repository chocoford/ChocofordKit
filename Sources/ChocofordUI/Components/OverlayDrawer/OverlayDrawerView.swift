//
//  SwiftUIView.swift
//  
//
//  Created by Chocoford on 2023/4/21.
//

import SwiftUI

public struct OverlayDrawerViewModier<Drawer: View>: ViewModifier {
    @Binding var isPresent: Bool
    var slideFrom: Edge = .leading
    var drawerView: () -> Drawer
    
    var alignment: Alignment {
        switch slideFrom {
            case .top:
                return .top
            case .leading:
                return .leading
            case .bottom:
                return .bottom
            case .trailing:
                return .trailing
        }
    }
    
    init(_ isPresent: Binding<Bool>, slideFrom: Edge = .leading, @ViewBuilder drawerView: @escaping () -> Drawer) {
        self._isPresent = isPresent
        self.slideFrom = slideFrom
        self.drawerView = drawerView
    }
    
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment, content: drawerOverlay)
    }
    
#if os(macOS)
    @ViewBuilder
    func drawerOverlay() -> some View {
        if isPresent {
            drawerView()
                .zIndex(100)
                .transition(.move(edge: slideFrom))
        }
    }
#elseif os(iOS)
    @ViewBuilder
    func drawerOverlay() -> some View {
        if isPresent {
            ZStack(alignment: alignment) {
                Color.black.opacity(0.6)
                    .transition(.fade)
                    .onTapGesture {
                        isPresent = false
                    }
                    .transition(.fade)

                drawerView()
                    .padding(.top, .safeArearTop)
                    .background{
                        Rectangle()
                            .foregroundColor(.windowBackgroundColor)
                            .shadow(radius: 10)
                    }
                    .transition(.move(edge: slideFrom))
            }
            .ignoresSafeArea()
            .zIndex(100)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 50,
                            coordinateSpace: .local)
                    .onEnded({ value in
                        if value.translation.width < 0 {
                            // left
                            if slideFrom == .leading {
                                isPresent = false
                            }
                        }
                        
                        if value.translation.width > 0 {
                            // right
                            if slideFrom == .trailing {
                                isPresent = false
                            }
                        }
                        
                        if value.translation.height < 0 {
                            // up
                            if slideFrom == .top {
                                isPresent = false
                            }
                        }
                        
                        if value.translation.height > 0 {
                            // down
                            if slideFrom == .bottom {
                                isPresent = false
                            }
                        }
                    })
            )
        }
    }
#endif

}

public extension View {
    @ViewBuilder
    func overlayDrawer<Drawer: View>(_ isPresent: Binding<Bool>,
                                     slideFrom: Edge = .leading,
                                     @ViewBuilder drawerView: @escaping () -> Drawer) -> some View {
        self
            .modifier(OverlayDrawerViewModier(isPresent, slideFrom: slideFrom, drawerView: drawerView))
    }
}

struct DrawerPreview: View {
    @State private var showDrawer: Bool = false
    
    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            NavigationStack {
                Center {
                    Button {
                        withAnimation {
                            showDrawer.toggle()
                        }
                    } label: {
                        Text("Toggle Drawer")
                    }
                }
                .toolbar(content: {
                    Button {
                        
                    } label: {
                        Image(systemName: "plus")
                    }
                })

            }
            .overlayDrawer($showDrawer, slideFrom: .trailing) {
                Center {
                    Text("Drawer")
                }
                .background(Color.green)
                .frame(width: 300)
            }
        } else {
            // Fallback on earlier versions
            EmptyView()
        }
    }
}


#if DEBUG
struct OverlayDrawerView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerPreview()
        
    }
}
#endif
