//
//  Candidate.swift
//  Woojo
//
//  Created by Edouard Goossens on 04/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

extension CurrentUser {
    
    class Candidate: User {
        
        var user: User
        //var events: [Event]?
        var commonEventInfos: [CommonEventInfo] = []
        
        var candidateRef: DatabaseReference {
            get {
                return user.ref.child(Constants.User.Candidate.firebaseNode).child(uid)
            }
        }
        
        var commonEventsInfoString: String {
            get {
                var result = ""
                for commonEventInfo in self.commonEventInfos {
                    result += "\(commonEventInfo.displayString)\n"
                }
                return result
            }
        }
        
        init(snapshot: DataSnapshot, for user: User) {
            self.user = user
            for item in snapshot.childSnapshot(forPath: Constants.User.Candidate.properties.firebaseNodes.events).children {
                if let commonEventInfoSnap = item as? DataSnapshot {
                    print("COMMON EVENT", commonEventInfoSnap)
                    self.commonEventInfos.append(CommonEventInfo(snapshot: commonEventInfoSnap))
                }
            }
            super.init(uid: snapshot.key)
        }
        
        func like(visible: Bool? = nil, message: String? = nil, completion: ((Error?) -> Void)? = nil) {
            // Like the candidate
            User.current.value?.like(candidate: self.uid, visible: visible, message: message) { error in
                // Remove it from the list
                self.remove(completion: completion)
            }
        }
        
        func pass(completion: ((Error?) -> Void)? = nil) {
            // Pass on the candidate
            User.current.value?.pass(candidate: self.uid) { error in
                self.profile.removeAllPhotosFromCache()
                // Remove it from the list
                self.remove(completion: completion)
            }
        }
        
        func remove(completion: ((Error?) -> Void)? = nil) {
            candidateRef.removeValue { error, ref in
                if let error = error {
                    print("Failed to remove candidate: \(error)")
                }
                completion?(error)
            }
        }
        
        class CommonEventInfo {
            
            var rsvpStatus = Event.RSVP.unsure
            var name = "a common event"
            
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
                if let name = snapshot.childSnapshot(forPath: Constants.User.Candidate.CommonEventInfo.firebaseNodes.name).value as? String {
                    self.name = name
                }
                if let rsvpStatus = snapshot.childSnapshot(forPath: Constants.User.Candidate.CommonEventInfo.firebaseNodes.rsvpStatus).value as? String {
                    self.rsvpStatus = Event.RSVP(rawValue: rsvpStatus) ?? Event.RSVP.unsure
                }
            }
        }
        
    }
    
}
