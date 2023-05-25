import SwiftUI
import SwiftUIOverlayContainer

public struct ChocofordUI {
        
    public init() {}
}

struct TeleportConfiguration: ContainerConfigurationProtocol {
    var displayType: ContainerViewDisplayType = .stacking
    var queueType: ContainerViewQueueType = .multiple
    var ignoresSafeArea: ContainerIgnoresSafeArea = .all
}

extension View {
    @ViewBuilder
    public func setupChocofordUI() -> some View {
        self
            .overlayContainer("teleport", containerConfiguration: TeleportConfiguration())
    }
}
