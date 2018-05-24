//
//  Event.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation

class Event: Codable {
    var id: String?
    var name: String?
    var start: Date?
    var end: Date?
    var place: Place?
    var coverURL: String?
    var description: String?
    var attendingCount: Int?
    var interestedCount: Int?
    var noReplyCount: Int?
    var type: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, place, type, description
        case start = "start_time"
        case end = "end_time"
        case coverURL = "cover_url"
        case attendingCount = "attending_count"
        case interestedCount = "interested_count"
        case noReplyCount = "noreply_count"
    }

    var rsvpStatus: String = "unsure"
    var source: Source = .recommended
    var active: Bool = false
    
    enum RSVP: String, Codable {
        case attending
        case unsure
        case notReplied = "not_replied"
        case iWasRecommendedOthers = "i_was_recommended_others"
        case otherWasRecommendedMine = "other_was_recommended_mine"
    }
    
    enum Source: String, Codable {
        case facebook
        case eventbrite
        case recommended
        case sponsored
    }
}
