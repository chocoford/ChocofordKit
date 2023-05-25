//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/5/20.
//

import SwiftUI

public struct FakeRefreshableIndicator: View {
    public init() {}
    public var body: some View {
        ProgressView()
#if os(iOS)
            .controlSize(.large)
#endif
            .padding()
    }
}

struct FakeRefreshableIndicator_Previews: PreviewProvider {
    static var previews: some View {
        FakeRefreshableIndicator()
    }
}
