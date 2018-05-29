//
// Created by Edouard Goossens on 11/05/2018.
// Copyright (c) 2018 Tasty Electrons. All rights reserved.
//

import Foundation

class CommonalityCalculator {
    static var shared = CommonalityCalculator()

    private init() {}

    func interestScale(rsvpStatus: Event.RSVP) -> Int {
        var commonality = 0
        switch rsvpStatus {
        case .attending:
            commonality = 4
        case .unsure:
            commonality = 3
        case .notReplied:
            commonality = 2
        case .iWasRecommendedOthers:
            commonality = 0
        case .otherWasRecommendedMine:
            commonality = 0
        }
        return commonality
    }

    func commonality(rsvpStatusA: Event.RSVP?, rsvpStatusB: Event.RSVP?) -> Int {
        if rsvpStatusA == nil || rsvpStatusB == nil {
            return 0
        }
        return interestScale(rsvpStatus: rsvpStatusA!) + interestScale(rsvpStatus: rsvpStatusB!)
    }

    func commonality(otherUser: OtherUser) throws -> Int {
        return try otherUser.commonInfo.commonEvents.reduce(0, { $0 + commonality(rsvpStatusA: $1.value.rsvpStatus, rsvpStatusB: try rsvpStatus(eventId: $1.key)) })
    }

    func bothGoing(otherUser: OtherUser) throws -> Bool {
        return try otherUser.commonInfo.commonEvents.reduce(false, { (previousResult, commonEventInfo) -> Bool in
            return try (previousResult && (try rsvpStatus(eventId: commonEventInfo.key) == .attending) && commonEventInfo.value.rsvpStatus == .attending)
        })
    }

    func rsvpStatus(eventId: String) throws -> Event.RSVP {
        return .unsure
    }
}
