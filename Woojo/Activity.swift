//
//  Activity.swift
//  Woojo
//
//  Created by Edouard Goossens on 20/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct Activity {
    
    var lastSeen: Date?
    var signUp: Date?
    
    static let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = Constants.User.Activity.dateFormat
        return formatter
    }()
    
    static func from(firebase snapshot: FIRDataSnapshot) -> Activity? {
        if let value = snapshot.value as? [String:Any] {
            var activity = Activity()
            if let lastSeenString = value[Constants.User.Activity.properties.firebaseNodes.lastSeen] as? String {
                activity.lastSeen = Activity.dateFormatter.date(from: lastSeenString)
            }
            if let signUpString = value[Constants.User.Activity.properties.firebaseNodes.signUp] as? String {
                activity.signUp = Activity.dateFormatter.date(from: signUpString)
            }
            return activity
        } else {
            print("Failed to create Activity from Firebase snapshot.", snapshot)
            return nil
        }
    }
    
}
