//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension GraphAPI {
    struct Event: Codable {
        var id: String?
        var name: String?
        var start: Date?
        var end: Date?
        var place: Place?
        var cover: Cover?
        var description: String?
        var attendingCount: Int?
        var interestedCount: Int?
        var noReplyCount: Int?
        var type: String?
        var rsvpStatus: String?
        
        private enum CodingKeys: String, CodingKey {
            case id, name, place, type, description, cover
            case start = "start_time"
            case end = "end_time"
            case attendingCount = "attending_count"
            case interestedCount = "interested_count"
            case noReplyCount = "noreply_count"
            case rsvpStatus = "rsvp_status"
        }
        
        struct Cover: Codable {
            var source: String?
            var id: String?
        }
    }
}
