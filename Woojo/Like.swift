//
//  Like.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

struct Like {
    
    static func on(user uid: String, in event: Event) {
        let byId = FIRAuth.auth()!.currentUser!.uid
        let likeId = "\(byId)♥\(uid)"
        let like: [String:Any] = [
            "onId": uid,
            "byId": byId,
            "eventId": event.id,
            "created": Date().timeIntervalSince1970 * 1000
        ]
        FIRDatabase.database().reference().child("likes").child(likeId).setValue(like)
    }
    
}
