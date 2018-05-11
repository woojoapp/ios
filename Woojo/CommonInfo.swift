//
//  CommonInfo.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class CommonInfo: Codable {
    var events: [Event] = []
    var commonEvents: [CommonEvent] = []
    var friends: [Friend] = []
    var pageLikes: [PageLike] = []
    
    private enum CodingKeys: String, CodingKey {
        case friends
        case commonEvents = "events"
        case pageLikes = "page-likes"
    }
}
