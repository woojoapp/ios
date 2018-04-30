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
    class CommonEvent {
        var rsvpStatus = Event.RSVP.unsure
        var name = ""
        var id: String
        
        var displayString: String {
            get {
                var rsvpString: String
                switch rsvpStatus {
                case .attending:
                    rsvpString = String(format: NSLocalizedString("Goes to %@", comment: ""), name)
                case .unsure:
                    rsvpString = String(format: NSLocalizedString("Interested in %@", comment: ""), name)
                case .notReplied:
                    rsvpString = String(format: NSLocalizedString("Invited to %@", comment: ""), name)
                case .iWasRecommendedOthers:
                    rsvpString = String(format: NSLocalizedString("Goes to %@ (recommended for you)", comment: ""), name)
                case .otherWasRecommendedMine:
                    rsvpString = String(format: NSLocalizedString("Goes to events similar to %@", comment: ""), name)
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
