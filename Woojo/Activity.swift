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
        var repliedToPushNotificationsInvite: Date?
        var user: User
        
        var ref: DatabaseReference {
            get {
                return user.ref.child(Constants.User.Activity.firebaseNode)
            }
        }
    
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = Constants.User.Activity.dateFormat
            return formatter
        }()
        
        init(for user: User) {
            self.user = user
        }
        
        func loadFrom(firebase snapshot: DataSnapshot) {
            if let value = snapshot.value as? [String:Any] {
                if let lastSeenString = value[Constants.User.Activity.properties.firebaseNodes.lastSeen] as? String {
                    self.lastSeen = Activity.dateFormatter.date(from: lastSeenString)
                }
                if let signUpString = value[Constants.User.Activity.properties.firebaseNodes.signUp] as? String {
                    self.signUp = Activity.dateFormatter.date(from: signUpString)
                }
                if let repliedToPushNotificationsInviteString = value[Constants.User.Activity.properties.firebaseNodes.repliedToPushNotificationsInvite] as? String {
                    self.repliedToPushNotificationsInvite = Activity.dateFormatter.date(from: repliedToPushNotificationsInviteString)
                }
            }
        }
        
        func loadFromFirebase(completion: ((Activity?, Error?) -> Void)? = nil) {
            ref.observeSingleEvent(of: .value, with: { snapshot in
                self.loadFrom(firebase: snapshot)
                completion?(self, nil)
            }, withCancel: { error in
                print("Failed to load activity from Firebase: \(error.localizedDescription)")
                completion?(self, error)
            })
        }
        
        func setSignUp(completion: ((Error?) -> Void)? = nil) {
            let date = Date()
            ref.child(Constants.User.Activity.properties.firebaseNodes.signUp).setValue(Activity.dateFormatter.string(from: date)) { error, ref in
                if let error = error {
                    print("Failed to set signUp: \(error.localizedDescription)")
                } else {
                    self.signUp = date
                }
                completion?(error)
            }
        }
        
        func setLastSeen(completion: ((Error?) -> Void)? = nil) {
            let date = Date()
            ref.child(Constants.User.Activity.properties.firebaseNodes.lastSeen).setValue(Activity.dateFormatter.string(from: date)) { error, ref in
                if let error = error {
                    print("Failed to set lastSeen: \(error.localizedDescription)")
                } else {
                    self.lastSeen = date
                }
                completion?(error)
            }
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
    
}
