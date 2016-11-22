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

struct Candidate: User, Equatable {
    
    var uid: String?
    var profile: Profile?
    var activity: Activity?
    
}

func == (left: Candidate, right: Candidate) -> Bool {
    return left.uid == right.uid
}

extension Candidate {
    
    /*static func from(snapshot: FIRDataSnapshot) -> Candidate? {
        if let value = snapshot.value as? [String:Any] {
            var candidate = Candidate()
            candidate.uid = value["uid"] as? String
            
            return candidate
        } else {
            print("Failed to create Candidate from snapshot.")
            return nil
        }
    }*/
    
    var ref: FIRDatabaseReference? {
        get {
            if let userCandidatesRef = CurrentUser.candidatesRef, let uid = uid {
                return userCandidatesRef.child(uid)
            }
            return  nil
        }
    }
    
    static func get(for uid: String, completion: @escaping (Candidate?) -> Void) {
        var candidate = Candidate()
        candidate.uid = uid
        Profile.get(for: uid) { profile in
            candidate.profile = profile
            candidate.profile?.user = candidate
            completion(candidate)
        }
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
        ref?.removeValue { error, ref in
            if let error = error {
                print("Failed to remove candidate: \(error)")
            }
            completion?(error, ref)
        }
    }
    
}
