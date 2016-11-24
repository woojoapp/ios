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

class User: Equatable {
    
    var uid: String
    var fbAppScopedID: String?
    var fbAccessToken: AccessToken?
    var profile: Profile!
    var activity: Activity!
    
    static var current: CurrentUser?
    
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
    
    var isObserved = false
    
    /*func startObserving() {
        isObserved = true
        activity.startObserving()
        profile.startObserving()
        startObservingEvents()
        startObservingCandidates()
    }
    
    func stopObserving() {
        activity.stopObserving()
        profile.stopObserving()
        stopObservingEvents()
        stopObservingCandidates()
        isObserved = false
    }*/

        
    // MARK: - Activity
    
    /*struct Activity {
        
        private static var _activity = Woojo.Activity()
        
        static var ref: FIRDatabaseReference? {
            get {
                if let userRef = CurrentUser.ref {
                    return userRef.child(Constants.User.Activity.firebaseNode)
                } else {
                    return nil
                }
            }
        }
        
        static var lastSeen: Date? {
            get {
                return _activity.lastSeen
            }
            set {
                if let newValue = newValue {
                    ref?.child(Constants.User.Activity.properties.firebaseNodes.lastSeen).setValue(Woojo.Activity.dateFormatter.string(from: newValue))
                }
                _activity.lastSeen = newValue
            }
        }
        
        static var signUp: Date? {
            get {
                return _activity.signUp
            }
            set {
                if let newValue = newValue {
                    ref?.child(Constants.User.Activity.properties.firebaseNodes.signUp).setValue(Woojo.Activity.dateFormatter.string(from: newValue))
                }
                _activity.signUp = newValue
            }
        }
        
        static var isObserving = false
        static func startObserving() {
            ref?.observe(.value, with: { snapshot in
                if let activity = Woojo.Activity.from(firebase: snapshot) {
                    //_activity.lastSeen = activity.lastSeen
                    //_activity.signUp = activity.signUp
                    _activity = activity
                }
            })
            isObserving = true
        }
        
        static func stopObserving() {
            ref?.removeAllObservers()
            isObserving = false
        }
        
    }*/
    
    // MARK: - Profile
    
    /*struct Profile {
        
        private static var _profile = Woojo.Profile()
        
        static var observers: [(Woojo.Profile) -> Void] = []
        
        static var displayName: String? {
            get {
                return CurrentUser.firebaseAuthUser?.displayName
            }
            set {
                let profileChangeRequest = CurrentUser.firebaseAuthUser?.profileChangeRequest()
                profileChangeRequest?.displayName = newValue
                profileChangeRequest?.commitChanges { error in
                    if let error = error {
                        print("Failed to update Firebase user profile display name: \(error.localizedDescription)")
                    }
                }
                ref?.child(Constants.User.Profile.properties.firebaseNodes.firstName).setValue(newValue)
                _profile.displayName = newValue
            }
        }
        
        static func photoDownloadURL(completion: @escaping (URL?, Error?) -> Void) {
            if let url = CurrentUser.firebaseAuthUser?.photoURL {
                FIRStorage.storage().reference(forURL: url.absoluteString).downloadURL(completion: completion)
            }
        }
        
        static var gender: Gender? {
            get {
                return _profile.gender
            }
            set {
                ref?.child(Constants.User.Profile.properties.firebaseNodes.gender).setValue(newValue?.rawValue)
                _profile.gender = newValue
            }
        }
        static var ageRange: (min: Int?, max: Int?)
        static var description: String?
        static var city: String?
        static var country: String?
        static var photoID: String?
        
        static var ref: FIRDatabaseReference? {
            get {
                if let userRef = CurrentUser.ref {
                    return userRef.child(Constants.User.Profile.firebaseNode)
                } else {
                    return nil
                }
            }
        }
        
        static var storageRef: FIRStorageReference? {
            get {
                if let userRef = CurrentUser.storageRef {
                    return userRef.child(Constants.User.Profile.firebaseNode)
                } else {
                    return nil
                }
            }
        }
        
        static var isObserving = false
        static func startObserving() {
            ref?.observe(.value, with: { snapshot in
                if let profile = Woojo.Profile.from(firebase: snapshot) {
                    _profile = profile
                    for observer in observers {
                        observer(profile)
                    }
                }
            })
            isObserving = true
        }
        
        static func stopObserving() {
            ref?.removeAllObservers()
            isObserving = false
        }
        
        static func loadDataFromFacebook() {
            if AccessToken.current != nil {
                if firebaseAuthUser != nil {
                    let userProfileGraphRequest = UserProfileGraphRequest()
                    userProfileGraphRequest.start { response, result in
                        switch result {
                        case.success(let response):
                            // Update Firebase with the data loaded from Facebook
                            Profile.displayName = response.profile?.displayName
                            if let responseAsDictionary = response.profile?.toDictionary() {
                                ref?.updateChildValues(responseAsDictionary) { error, _ in
                                    if let error = error {
                                        print("Failed to update user profile in database: \(error)")
                                    }
                                }
                                CurrentUser.ref?.child(Constants.User.Properties.fbAppScopedID).setValue(response.fbAppScopedID)
                            }
                            if Activity.signUp == nil {
                                Activity.signUp = Date()
                            }
                        case .failed(let error):
                            print("UserProfileGraphRequest failed: \(error.localizedDescription) \(AccessToken.current)")
                        }
                    }
                } else {
                    print("Failed to load profile data from Facebook: No authenticated Firebase user.")
                }
            } else {
                print("Failed to load profile data from Facebook: No Facebook access token.")
            }
        }
        
        static func loadPhotoFromFacebook() {
            if AccessToken.current != nil {
                if let user = firebaseAuthUser {
                    let userProfilePhotoGraphRequest = UserProfilePhotoGraphRequest()
                    userProfilePhotoGraphRequest.start { response, result in
                        switch result {
                        case .success(let response):
                            print("Photo URL: \(response.photoURL?.absoluteString)")
                            print("Thumbnail URL: \(response.thumbnailURL?.absoluteString)")
                            if let photoID = response.photoID {
                                ref?.child(Constants.User.Profile.properties.firebaseNodes.photoID).setValue(photoID)
                                if let photoURL = response.photoURL {
                                    let photoRef = storageRef?.child("photos").child(photoID)
                                    DispatchQueue.global().async {
                                        photoRef?.put(try! Data(contentsOf: photoURL), metadata: nil) { metadata, error in
                                            if let error = error {
                                                print("Failed to upload profile photo to Firebase Storage: \(error)")
                                            } else {
                                                let profileChangeRequest = user.profileChangeRequest()
                                                profileChangeRequest.photoURL = metadata?.downloadURL()
                                                profileChangeRequest.commitChanges { error in
                                                    if let error = error {
                                                        print("Failed to update Firebase user profile photo URL: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if let thumbnailURL = response.thumbnailURL {
                                    let thumbnailRef = storageRef?.child("thumbnails").child(photoID)
                                    DispatchQueue.global().async {
                                        thumbnailRef?.put(try! Data(contentsOf: thumbnailURL), metadata: nil) { metadata, error in
                                            if let error = error {
                                                print("Failed to upload profile photo to Firebase Storage: \(error)")
                                            }
                                        }
                                    }
                                }
                            }
                        case .failed(let error):
                            print("UserProfilePhotoGraphRequest failed: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Failed to load profile photo from Facebook: No authenticated Firebase user.")
                }
            } else {
                print("Failed to load profile photo from Facebook: No Facebook access token.")
            }
        }
    }*/


}

func == (left: User, right: User) -> Bool {
    return left.uid == right.uid
}
