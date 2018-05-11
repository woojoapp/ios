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
import SDWebImage
import CodableFirebase

extension CurrentUser {
    
    class Candidate: OtherUser {
        
        var user: User
        
        var candidateRef: DatabaseReference {
            get {
                return user.ref.child(Constants.User.Candidate.firebaseNode).child(uid)
            }
        }
        
        init(snapshot: DataSnapshot, for user: User) {
            self.user = user
            super.init(uid: snapshot.key)
            for item in snapshot.childSnapshot(forPath: Constants.User.Candidate.properties.firebaseNodes.events).children {
                if let commonEventInfoSnap = item as? DataSnapshot,
                    let commonEvent = try? FirebaseDecoder().decode(CommonEvent.self, from: commonEventInfoSnap) {
                    super.commonInfo.commonEvents.append(commonEvent)
                }
            }
            for item in snapshot.childSnapshot(forPath: Constants.User.Candidate.properties.firebaseNodes.friends).children {
                if let friendSnap = item as? DataSnapshot,
                    let friend = try? FirebaseDecoder().decode(Friend.self, from: friendSnap){
                    super.commonInfo.friends.append(friend)
                }
            }
            for item in snapshot.childSnapshot(forPath: Constants.User.Candidate.properties.firebaseNodes.pageLikes).children {
                if let pageLikeSnap = item as? DataSnapshot,
                    let pageLike = try? FirebaseDecoder().decode(PageLike.self, from: pageLikeSnap){
                    super.commonInfo.pageLikes.append(pageLike)
                }
            }
        }
        
        func like(visible: Bool? = nil, message: String? = nil, completion: ((Error?) -> Void)? = nil) {
            // Like the candidate
            User.current.value?.like(candidate: self.uid, visible: visible, message: message) { error in
                // Remove it from the list
                self.remove(completion: completion)
                //completion?(error)
            }
        }
        
        func pass(completion: ((Error?) -> Void)? = nil) {
            // Pass on the candidate
            User.current.value?.pass(candidate: self.uid) { error in
                self.profile?.removeAllPhotosFromCache()
                // Remove it from the list
                self.remove(completion: completion)
                //completion?(error)
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
