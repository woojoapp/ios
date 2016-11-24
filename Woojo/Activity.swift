//
//  Activity.swift
//  Woojo
//
//  Created by Edouard Goossens on 20/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase


extension User {
    
    class Activity {
    
        var lastSeen: Date?
        var signUp: Date?
        var user: User
    
        static let dateFormatter: DateFormatter = {
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = Constants.User.Activity.dateFormat
            return formatter
        }()
        
        init(for user: User) {
            self.user = user
        }
        
        func from(firebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any] {
                if let lastSeenString = value[Constants.User.Activity.properties.firebaseNodes.lastSeen] as? String {
                    self.lastSeen = Activity.dateFormatter.date(from: lastSeenString)
                }
                if let signUpString = value[Constants.User.Activity.properties.firebaseNodes.signUp] as? String {
                    self.signUp = Activity.dateFormatter.date(from: signUpString)
                }
            }
        }
        
    }
    
}
