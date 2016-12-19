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
        var events: [Event]?
        
        var candidateRef: FIRDatabaseReference {
            get {
                return user.ref.child(Constants.User.Candidate.firebaseNode).child(uid)
            }
        }
        
        init(uid: String, for user: User) {
            self.user = user
            super.init(uid: uid)
        }
        
        func like(visible: Bool? = nil, message: String? = nil, completion: ((Error?) -> Void)? = nil) {
            // Like the candidate
            Woojo.User.current.value?.like(candidate: self.uid, visible: visible, message: message) { error in
                // Remove it from the list
                self.remove(completion: completion)
            }
        }
        
        func pass(completion: ((Error?) -> Void)? = nil) {
            // Pass on the candidate
            Woojo.User.current.value?.pass(candidate: self.uid) { error in
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
        
    }
    
}
