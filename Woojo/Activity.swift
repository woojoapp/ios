//
//  Activity.swift
//  Woojo
//
//  Created by Edouard Goossens on 20/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase


class Activity {
    
    var lastSeen: Date?
    var signUp: Date?
    var repliedToPushNotificationsInvite: Date?

    func setSignUp(completion: ((Error?) -> Void)? = nil) {
        let date = Date()
        let dateString = Activity.dateFormatter.string(from: date)
        ref.child(Constants.User.Activity.properties.firebaseNodes.signUp).setValue(dateString) { error, ref in
            if let error = error {
                print("Failed to set signUp: \(error.localizedDescription)")
            } else {
                self.signUp = date
            }
            completion?(error)
        }
        Analytics.setUserProperties(properties: ["sign_up_date": dateString])
    }

    func setLastSeen(completion: ((Error?) -> Void)? = nil) {
        let date = Date()
        let dateString = Activity.dateFormatter.string(from: date)
        ref.child(Constants.User.Activity.properties.firebaseNodes.lastSeen).setValue(dateString) { error, ref in
            if let error = error {
                print("Failed to set lastSeen: \(error.localizedDescription)")
            } else {
                self.lastSeen = date
            }
            completion?(error)
        }
        Analytics.setUserProperties(properties: ["last_seen_date": dateString])
    }

    func setRepliedToPushNotificationsInvite(completion: ((Error?) -> Void)? = nil) {
        let date = Date()
        ref.child(Constants.User.Activity.properties.firebaseNodes.repliedToPushNotificationsInvite).setValue(Activity.dateFormatter.string(from: date)) { error, ref in
            if let error = error {
                print("Failed to set repliedToPushNotificationsInvite: \(error.localizedDescription)")
            } else {
                self.repliedToPushNotificationsInvite = date
            }
            completion?(error)
        }
    }

}
