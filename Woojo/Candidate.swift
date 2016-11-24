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
        
        func like(completion: ((Error?, FIRDatabaseReference) -> Void)? = nil) {
            // Like the candidate
            print("Liked \(uid)")
            remove(completion: completion)
        }
        
        func pass(completion: ((Error?, FIRDatabaseReference) -> Void)? = nil) {
            // Pass on the candidate
            print("Passed \(uid)")
            remove(completion: completion)
        }
        
        func remove(completion: ((Error?, FIRDatabaseReference) -> Void)? = nil) {
            candidateRef.removeValue { error, ref in
                if let error = error {
                    print("Failed to remove candidate: \(error)")
                }
                completion?(error, ref)
            }
        }
        
    }
    
}
