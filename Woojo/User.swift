//
//  UserProtocol.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import FacebookCore
import RxSwift

class User: Equatable {
    
    var uid: String
    var fbAppScopedID: String?
    var fbAccessToken: AccessToken?
    var profile: Profile?
    //var activity: Activity!
    var botUid: String?
    
    static var current: Variable<CurrentUser?> = Variable(nil)
    
    init(uid: String) {
        self.uid = uid
        profile = Profile(for: self)
        //activity = Activity(for: self)
    }
    
    var ref: DatabaseReference {
        get {
            return Database.database().reference().child(Constants.User.firebaseNode).child(uid)
        }
    }
    
    var storageRef: StorageReference {
        get {
            return Storage.storage().reference().child(Constants.User.firebaseNode).child(uid)
        }
    }
    
    var matchesRef: DatabaseReference {
        get {
            return Database.database().reference().child(Constants.User.Match.firebaseNode).child(uid)
        }
    }
    
    func unmatch(completion: ((Error?) -> Void)?) {
        if let currentUid = User.current.value?.uid {
            Database.database().reference().child(Constants.User.Like.firebaseNode).child(currentUid).child(uid).removeValue { error, _ in
                completion?(error)
            }
        }
    }
    
    func report(message: String? = nil, completion: ((Error?) -> Void)?) {
        if let by = User.current.value?.uid {
            let report = Report(by: by, on: uid, message: message)
            report.save { error in
                completion?(error)
            }
        }
    }
    
    func getMatch(with user: OtherUser, completion: ((Match?) -> ())? = nil) {
        Match.between(user: self, and: user, completion: completion)
    }

}

func == (left: User, right: User) -> Bool {
    return left.uid == right.uid
}
