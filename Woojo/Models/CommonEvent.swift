//
//  CommonEventInfo.swift
//  Woojo
//
//  Created by Edouard Goossens on 26/10/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation

class CommonEvent: Codable {
    var name: String?
    var rsvpStatus = Event.RSVP.unsure
    
    private enum CodingKeys: String, CodingKey {
        case name
        case rsvpStatus = "rsvp_status"
    }
    
    /* init(snapshot: DataSnapshot) {
        self.id = snapshot.key
        if let name = snapshot.childSnapshot(forPath: "name").value as? String {
            self.name = name
        }
        if let rsvpStatus = snapshot.childSnapshot(forPath: "rsvp_status").value as? String {
            self.rsvpStatus = Event.RSVP(rawValue: rsvpStatus) ?? Event.RSVP.unsure
        }
    } */
}
