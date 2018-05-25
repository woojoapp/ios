//
//  CommonInfo.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class CommonInfo: Codable {
    var events: [String: Event] = [:]
    var commonEvents: [String: CommonEvent] = [:]
    var friends: [String: User] = [:]
    var pageLikes: [String: PageLike] = [:]
    
    init() {
        
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.commonEvents = try container.decodeIfPresent([String: CommonEvent].self, forKey: .commonEvents) ?? [:]
        self.pageLikes = try container.decodeIfPresent([String: PageLike].self, forKey: .pageLikes) ?? [:]
        //self.friends = try container.decodeIfPresent([String: Friend].self, forKey: .friends) ?? [:]
    }
    
    private enum CodingKeys: String, CodingKey {
        //case friends
        case commonEvents = "events"
        case pageLikes = "page-likes"
    }
}
