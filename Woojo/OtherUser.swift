//
//  OtherUser.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class OtherUser {
    var uid: String
    var profile: User.Profile?
    var commonInfo: CommonInfo = CommonInfo()
    
    init(uid: String) {
        self.uid = uid
    }
    
    enum Kind {
        case candidate
        case match
    }
}
