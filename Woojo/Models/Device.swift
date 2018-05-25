//
// Created by Edouard Goossens on 12/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class Device: Codable {
    var fcm: String?
    var token: String?
    var platform: Platform?

    init(fcm: String, token: String, platform: Platform) {
        self.fcm = fcm
        self.token = token
        self.platform = platform
    }

    enum Platform: String, Codable {
        case iOS = "ios"
        case android
    }
}
