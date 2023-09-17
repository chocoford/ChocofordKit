//
//  SwiftUIView.swift
//  
//
//  Created by Dove Zachary on 2023/9/17.
//

import SwiftUI

struct DefaultAvatarUser: AvatarUserRepresentable {
    var id: UUID = UUID()
    var name: String?
    var avatarURL: URL?
}

public struct AvatarsGroupView<T: AvatarUserRepresentable>: View {
    var users: [T]
    
    public init(users: [T]) {
        self.users = users
    }
    
    
    public var body: some View {
        ForEach(Array(users.prefix(5))) { member in
            if let url = member.avatarURL as? URL {
                AvatarView(url,
                           fallbackText: String(member.name?.first ?? "?"))
                .size(20)
            } else if let urlString = member.avatarURL as? String {
                AvatarView(urlString: urlString,
                           fallbackText: String(member.name?.first ?? "?"))
                .size(20)
            } else {
                AvatarView(nil,
                           fallbackText: String(member.name?.first ?? "?"))
                .size(20)
            }
        }
        if users.count > 5 {
            AvatarView(nil, fallbackText: "+\(users.count - 5)")
            .size(20)
        }
    }
}

#if DEBUG
#Preview {
    AvatarsGroupView(users: [] as [DefaultAvatarUser])
}
#endif
