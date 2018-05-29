//
//  OtherUser.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase

class OtherUser: User {
    var commonInfo: CommonInfo = CommonInfo()

    /* init?(from dataSnapshot: DataSnapshot?) throws {
        super.init?(from: dataSnapshot)
    }

    init(uid: String, profile: User.Profile, commonInfo: CommonInfo) {
        super.init(uid: uid)
        self.profile = profile
        self.commonInfo = commonInfo
    } */

    enum Kind {
        case candidate
        case match
    }
}
