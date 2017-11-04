//
//  CommonEventInfo.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

extension User {
    class CommonEventInfo {
        var rsvpStatus = Event.RSVP.unsure
        var name = "a common event"
        var id: String
        
        var displayString: String {
            get {
                var rsvpString: String
                switch rsvpStatus {
                case .attending:
                    rsvpString = "Goes to \(name)"
                case .unsure:
                    rsvpString = "Interested in \(name)"
                case .notReplied:
                    rsvpString = "Invited to \(name)"
                case .iWasRecommendedOthers:
                    rsvpString = "Goes to \(name) (recommended for you)"
                case .otherWasRecommendedMine:
                    rsvpString = "Goes to events similar to \(name)"
                }
                return "\(rsvpString)"
            }
        }
        
        init(snapshot: DataSnapshot) {
            self.id = snapshot.key
            if let name = snapshot.childSnapshot(forPath: Constants.User.CommonEventInfo.firebaseNodes.name).value as? String {
                self.name = name
            }
            if let rsvpStatus = snapshot.childSnapshot(forPath: Constants.User.CommonEventInfo.firebaseNodes.rsvpStatus).value as? String {
                self.rsvpStatus = Event.RSVP(rawValue: rsvpStatus) ?? Event.RSVP.unsure
            }
        }
    }
}
