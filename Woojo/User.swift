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
    var profile: Profile!
    var activity: Activity!
    
    static var current: Variable<CurrentUser?> = Variable(nil)
    
    init(uid: String) {
        self.uid = uid
        profile = Profile(for: self)
        activity = Activity(for: self)
    }
    
    var ref: FIRDatabaseReference {
        get {
            return FIRDatabase.database().reference().child(Constants.User.firebaseNode).child(uid)
        }
    }
    
    var storageRef: FIRStorageReference {
        get {
            return FIRStorage.storage().reference().child(Constants.User.firebaseNode).child(uid)
        }
    }
    
    var matchesRef: FIRDatabaseReference {
        get {
            return FIRDatabase.database().reference().child(Constants.User.Match.firebaseNode).child(uid)
        }
    }
    
    func unmatch(completion: ((Error?) -> Void)?) {
        if let currentUid = User.current.value?.uid {
            FIRDatabase.database().reference().child(Constants.User.Like.firebaseNode).child(currentUid).child(uid).removeValue { error, _ in
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

}

func == (left: User, right: User) -> Bool {
    return left.uid == right.uid
}
