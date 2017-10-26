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
                    rsvpString = "Going to"
                case .unsure:
                    rsvpString = "Interested in"
                case .notReplied:
                    rsvpString = "Invited to"
                }
                return "\(rsvpString) \(name)"
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
